#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLInternal.h>

/* These CGL entry points require window-server or IOSurface state that is not
 * exposed by Darling's current CGL context implementation. */

GLboolean CGLAreContextsShared(CGLContextObj first, CGLContextObj second)
{
	return first != NULL && first == second;
}

void *CGLBackDispatch(CGLContextObj context)
{
	(void) context;
	return NULL;
}

void *CGLFrontDispatch(CGLContextObj context)
{
	(void) context;
	return NULL;
}

CGLPixelFormatObj CGLGetPixelFormat(CGLContextObj context)
{
	(void) context;
	return NULL;
}

void *CGLGetShareGroup(CGLContextObj context)
{
	(void) context;
	return NULL;
}

CGLError CGLGetSurface(CGLContextObj context, CGSConnectionID *connection,
					   CGSWindowID *window, CGSSurfaceID *surface)
{
	if (connection != NULL)
		*connection = 0;
	if (window != NULL)
		*window = 0;
	if (surface != NULL)
		*surface = 0;
	return context == NULL ? kCGLBadContext : kCGLBadDrawable;
}

CGLError CGLGetVirtualScreen(CGLContextObj context, GLint *screen)
{
	if (screen == NULL)
		return kCGLBadAddress;
	*screen = 0;
	return context == NULL ? kCGLBadContext : kCGLNoError;
}

CGLError CGLIsEnabled(CGLContextObj context, int pname, GLint *enabled)
{
	(void) pname;
	if (enabled == NULL)
		return kCGLBadAddress;
	*enabled = 0;
	return context == NULL ? kCGLBadContext : kCGLNoError;
}

void CGLRestoreDispatch(CGLContextObj context)
{
	(void) context;
}

void CGLSelectDispatchBounded(CGLContextObj context, void *dispatch, GLint size)
{
	(void) context;
	(void) dispatch;
	(void) size;
}

void CGLSelectDispatchFunction(CGLContextObj context, void *function, GLint functionID)
{
	(void) context;
	(void) function;
	(void) functionID;
}

CGLError CGLTexImageIOSurface2D(CGLContextObj context, GLenum target,
								GLenum internalFormat, GLsizei width, GLsizei height,
								GLenum format, GLenum type, void *ioSurface, GLuint plane)
{
	(void) target;
	(void) internalFormat;
	(void) width;
	(void) height;
	(void) format;
	(void) type;
	(void) ioSurface;
	(void) plane;
	return context == NULL ? kCGLBadContext : kCGLBadDrawable;
}

CGLError CGLUpdateContext(CGLContextObj context)
{
	return context == NULL ? kCGLBadContext : kCGLNoError;
}

void glFlushRenderAPPLE(void)
{
	glFlush();
}

void glSwapAPPLE(void)
{
	CGLContextObj context = CGLGetCurrentContext();
	if (context != NULL)
		(void) CGLFlushDrawable(context);
}
