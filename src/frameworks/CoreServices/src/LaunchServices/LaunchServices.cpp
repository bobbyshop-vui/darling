#include <LaunchServices/LaunchServices.h>
#include <LaunchServices/LaunchServicesPriv.h>
#include <CarbonCore/MacErrors.h>
#include <CoreFoundation/CFBundle.h>
#include <unistd.h>
#include <string>
#include <memory>
#include <vector>
#include <algorithm>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <limits.h>
#include <unicode/unistr.h>
#include <CoreServices/UniChar.h>

using namespace icu;

extern char** environ;

namespace
{
    const std::string g_scXdgOpenPath = "/usr/bin/xdg-open";
    const std::string g_scXdgMimePath = "/usr/bin/xdg-mime";

    std::string launchApp(const std::string &app, const std::vector<std::string> &args, bool async = false)
    {
        std::string buffer;
        char **argv = new char*[args.size()+1];
        int index=0;
        argv[0] = strdup(app.c_str());
        std::for_each(std::begin(args), std::end(args), [&argv,&index](const std::string &arg)
        {
            argv[++index] = strdup(arg.c_str());
        });
        argv[++index] = 0;

        int pipes[2];
        pipe(pipes);

        pid_t newPid = fork();

        if (newPid == 0) {
            if (!async) {
                close(pipes[0]);
                dup2(pipes[1], 1);
                close(pipes[1]);
            }
            // close stdin
            close(0);
            execv(argv[0], reinterpret_cast<char *const*>(argv));
            perror("Unable to launch process");
            exit(20);
        }
        else if( newPid > 0 ) {
			int status;

            close(pipes[1]);
            if (!async) {
                char cBuffer[1024];

                while(read(pipes[0], cBuffer,sizeof(cBuffer)) != 0) {
                    buffer += cBuffer;
                }
                buffer +='\0';
                wait(&status);
            }
        }
        for(std::size_t i = 0;i< args.size()+1;++i){
            free(argv[i]);
        }
        delete[] (argv);

        return buffer;
    }

    std::string mimeForFile(const std::string &url)
    {
        std::vector<std::string> args {"query", "filetype",url};
        std::string out = launchApp(g_scXdgMimePath,args);

        return out;
    }

    std::string getDefaultApplication(std::string mimeType)
    {
        return launchApp(g_scXdgMimePath,std::vector<std::string> {"query","default", mimeType});
    }
}


// in FileManager.cpp
bool FSRefMakePath(const FSRef* ref, std::string& out);

OSStatus LSInit(LSInitializeFlags flags)
{
	return noErr;
}

OSStatus LSTerm(void)
{
	return noErr;
}

static
int execvpe(const char* name, char** argv, char** envp)
{
	if (!envp)
		return execvp(name, argv);

	char** orig_env;
	int ret;

	orig_env = environ;
	environ = envp;

	ret = execvp(name, argv);

	environ = orig_env;
	return ret;
}

static bool cfStringToUTF8(CFStringRef value, std::string& result)
{
	if (!value || CFGetTypeID(value) != CFStringGetTypeID())
		return false;

	CFIndex capacity = CFStringGetMaximumSizeForEncoding(CFStringGetLength(value), kCFStringEncodingUTF8) + 1;
	if (capacity <= 0)
		return false;

	std::vector<char> buffer((size_t) capacity);
	if (!CFStringGetCString(value, buffer.data(), capacity, kCFStringEncodingUTF8))
		return false;

	result.assign(buffer.data());
	return true;
}

OSStatus LSOpenApplication(const LSApplicationParameters *appParams, ProcessSerialNumber *outPSN)
{
	if (!appParams || !appParams->application)
		return paramErr;

	std::string bundlePath;
	std::vector<char*> argv;
	std::vector<std::string> argumentStorage;
	std::unique_ptr<std::vector<char*>> envp;
	std::vector<std::string> envStrings;
	int pipefds[2];
	pid_t pid;
	OSStatus rv = noErr;

	if (!FSRefMakePath(appParams->application, bundlePath))
		return fnfErr;

	CFURLRef bundleURL = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
		(const UInt8*) bundlePath.c_str(), bundlePath.length(), true);
	if (!bundleURL)
		return fnfErr;

	CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
	CFRelease(bundleURL);
	if (!bundle)
		return kLSApplicationNotFoundErr;

	CFURLRef executableURL = CFBundleCopyExecutableURL(bundle);
	CFRelease(bundle);
	if (!executableURL)
		return kLSApplicationNotFoundErr;

	std::vector<UInt8> executablePathBuffer(PATH_MAX);
	if (!CFURLGetFileSystemRepresentation(executableURL, true, executablePathBuffer.data(), executablePathBuffer.size()))
	{
		CFRelease(executableURL);
		return fnfErr;
	}
	CFRelease(executableURL);
	std::string exePath((const char*) executablePathBuffer.data());

	if (appParams->argv != nullptr)
	{
		CFIndex count = CFArrayGetCount(appParams->argv);
		argumentStorage.reserve((size_t) count);

		for (CFIndex i = 0; i < count; i++)
		{
			CFStringRef ref = (CFStringRef) CFArrayGetValueAtIndex(appParams->argv, i);
			std::string argument;
			if (!cfStringToUTF8(ref, argument))
				return paramErr;
			argumentStorage.push_back(argument);
		}

		argv.reserve(argumentStorage.size() + 2);
		argv.push_back((char*) exePath.c_str());
		for (std::string& argument : argumentStorage)
			argv.push_back((char*) argument.c_str());
		argv.push_back(nullptr);
	}
	else
		argv = { (char*) exePath.c_str(), nullptr };

	if (appParams->environment != nullptr)
	{
		envStrings.reserve((size_t) CFDictionaryGetCount(appParams->environment));
		CFDictionaryApplyFunction(appParams->environment, [](const void* key, const void* value, void* context) {
			std::string keyString, valueString;
			if (cfStringToUTF8((CFStringRef) key, keyString) && cfStringToUTF8((CFStringRef) value, valueString))
				((std::vector<std::string>*) context)->push_back(keyString + "=" + valueString);
		}, &envStrings);

		envp.reset(new std::vector<char*>);
		envp->reserve(envStrings.size() + 1);
		for (std::string& item : envStrings)
			envp->push_back((char*) item.c_str());
		envp->push_back(nullptr);
	}

	// https://stackoverflow.com/questions/1584956/how-to-handle-execvp-errors-after-fork
	
	if (pipe(pipefds))
		return makeOSStatus(errno);

	fcntl(pipefds[1], F_SETFD, fcntl(pipefds[1], F_GETFD) | FD_CLOEXEC);

	switch (pid = fork())
	{
		case -1:
			rv = makeOSStatus(errno);
			close(pipefds[0]);
			close(pipefds[1]);
			break;
		case 0:
			close(pipefds[0]);
			execvpe(exePath.c_str(), &argv[0], envp ? &(*envp)[0] : nullptr);
			write(pipefds[1], &errno, sizeof(int));
			_exit(1);
			break;
		default:
		{
			int err, count;
			close(pipefds[1]);

			while ((count = read(pipefds[0], &err, sizeof(err))) == -1)
			{
				if (errno != EINTR)
					break;
			}

			if (count > 0)
				rv = makeOSStatus(err);
			close(pipefds[0]);
		}
	}
	
	return rv;
}

OSStatus LSSetExtensionHiddenForRef(const FSRef *inRef, Boolean hide)
{
	return noErr; // dummy operation
}

OSStatus LSSetExtensionHiddenForURL(CFURLRef inURL, Boolean hide)
{
	return noErr; // dummy operation
}

/*OSStatus LSOpenCFURLRef(CFURLRef inURL, CFURLRef *outLaunchedURL)
{
	// TODO: use 'xdg-mime query' and 'xdg-mime default' to determine the app?

    const char *str = CFStringGetCStringPtr(CFURLGetString(inURL),CFStringGetSystemEncoding());
    std::vector<std::string> args;
    args.push_back(str);
    launchApp(g_scXdgOpenPath,args);
    outLaunchedURL = nullptr;
	return unimpErr;
}*/

OSStatus LSGetExtensionInfo(UniCharCount inNameLen, const UniChar* inNameBuffer, UniCharCount *outExtStartIndex)
{
	if (!outExtStartIndex)
		return paramErr;

	UnicodeString str((const char*) inNameBuffer, inNameLen*2, UNICHAR_ENCODING);
	int32_t pos = str.lastIndexOf('.');

	if (pos == -1)
		*outExtStartIndex = inNameLen;
	else
		*outExtStartIndex = pos;

	return noErr;
}

// TODO: See https://gist.github.com/zorgiepoo/d751cba19a0167a589a2

CFTypeRef _LSCopyApplicationInformationItem(int /* hopefully */, CFTypeRef asn, CFStringRef what)
{
	return NULL;
}

CFDictionaryRef _LSCopyApplicationInformation(int, CFTypeRef asn, int)
{
	return NULL;
}

/*
OSStatus _LSOpenURLsWithRole(CFArrayRef inURLs, LSRolesMask inRole, void *unknown)
{
	CFURLRef url = CFArrayGetValueAtIndex(inURLs, 0);
	LSOpenCFURLRef(url, NULL);
	return noErr;
}
*/

CFStringRef LSUserApplicationType = CFSTR("User");
CFStringRef LSSystemApplicationType = CFSTR("System");
CFStringRef LSInternalApplicationType = CFSTR("Internal");
CFStringRef LSPlugInKitType = CFSTR("PluginKitPlugin");
CFStringRef LSVPNPluginType = CFSTR("VPNPlugin");


