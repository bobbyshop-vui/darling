#ifndef __AppleEvents_H__
#define __AppleEvents_H__

#include <AE/AEDataModel.h>

enum : AEEventID {
kAEOpenApplication = 'oapp',
kAEReopenApplication = 'rapp',
kAEOpenDocuments = 'odoc',
kAEPrintDocuments = 'pdoc',
kAEOpenContents = 'ocon',
kAEQuitApplication = 'quit',
kAEAnswer = 'ansr',
kAEApplicationDied = 'obit',
kAEShowPreferences = 'pref',
};

enum : DescType {
    kCoreEventClass = 'aevt',
};

#ifdef __cplusplus
extern "C" {
#endif

OSErr AEInstallEventHandler(AEEventClass theAEEventClass, AEEventID theAEEventID, AEEventHandlerUPP handler, SRefCon handlerRefcon, Boolean isSysHandler);
OSErr AEGetEventHandler(AEEventClass theAEEventClass, AEEventID theAEEventID, AEEventHandlerUPP* handler, SRefCon* handlerRefcon, Boolean isSysHandler);
OSErr AERemoveEventHandler(AEEventClass theAEEventClass, AEEventID theAEEventID, AEEventHandlerUPP handler, Boolean isSysHandler);

#ifdef __cplusplus
}
#endif

#endif
