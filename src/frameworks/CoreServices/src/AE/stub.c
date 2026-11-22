#include <AE/AE.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

static int verbose = 0;
__attribute__((constructor)) static void initme(void) {
    verbose = getenv("STUB_VERBOSE") != NULL;
}

OSErr AECreateDesc(DescType typeCode, const void *dataPtr, Size dataSize, AEDesc *result) {
    if (verbose) puts("STUB: AECreateDesc called");
    return noErr;
}

OSErr AEDisposeDesc(AEDesc *theAEDesc) {
    if (verbose) puts("STUB: AEDisposeDesc called");
    return noErr;
}

struct EventHandler {
    AEEventClass eventClass;
    AEEventID eventID;
    AEEventHandlerUPP handler;
    SRefCon refcon;
    struct EventHandler *next;
};

// macOS keeps separate application and system dispatch tables in each process.
static struct EventHandler *eventHandlers[2];
static pthread_mutex_t eventHandlersLock = PTHREAD_MUTEX_INITIALIZER;

/* The caller holds eventHandlersLock. Return the link to an exact match or
 * the end of the selected table.
 */
static struct EventHandler **findEventHandler(
    AEEventClass eventClass, AEEventID eventID, Boolean isSysHandler
) {
    struct EventHandler **link = &eventHandlers[isSysHandler != 0];
    while (*link && ((*link)->eventClass != eventClass || (*link)->eventID != eventID))
        link = &(*link)->next;
    return link;
}

OSErr AEInstallEventHandler(
  AEEventClass theAEEventClass,
  AEEventID theAEEventID,
  AEEventHandlerUPP handler,
  SRefCon handlerRefcon,
  Boolean isSysHandler
) {
    if (!handler)
        return paramErr;

    pthread_mutex_lock(&eventHandlersLock);
    struct EventHandler **link = findEventHandler(theAEEventClass, theAEEventID, isSysHandler);
    struct EventHandler *entry = *link;
    if (!entry) {
        entry = malloc(sizeof(*entry));
        if (!entry) {
            pthread_mutex_unlock(&eventHandlersLock);
            return memFullErr;
        }
        *entry = (struct EventHandler) { .eventClass = theAEEventClass, .eventID = theAEEventID };
        *link = entry;
    }
    entry->handler = handler;
    entry->refcon = handlerRefcon;
    pthread_mutex_unlock(&eventHandlersLock);
    return noErr;
}

OSErr AEGetEventHandler(
    AEEventClass theAEEventClass,
    AEEventID theAEEventID,
    AEEventHandlerUPP *handler,
    SRefCon *handlerRefcon,
    Boolean isSysHandler
) {
    pthread_mutex_lock(&eventHandlersLock);
    const struct EventHandler *entry = *findEventHandler(theAEEventClass, theAEEventID, isSysHandler);
    if (handler)
        *handler = entry ? entry->handler : NULL;
    if (handlerRefcon)
        *handlerRefcon = entry ? entry->refcon : (SRefCon) 0;
    OSErr status = entry ? noErr : errAEHandlerNotFound;
    pthread_mutex_unlock(&eventHandlersLock);
    return status;
}

OSErr AERemoveEventHandler(
    AEEventClass theAEEventClass,
    AEEventID theAEEventID,
    AEEventHandlerUPP handler,
    Boolean isSysHandler
) {
    pthread_mutex_lock(&eventHandlersLock);
    struct EventHandler **link = findEventHandler(theAEEventClass, theAEEventID, isSysHandler);
    struct EventHandler *entry = *link;
    if (!entry || (handler && entry->handler != handler)) {
        pthread_mutex_unlock(&eventHandlersLock);
        return errAEHandlerNotFound;
    }
    *link = entry->next;
    pthread_mutex_unlock(&eventHandlersLock);
    free(entry);
    return noErr;
}
