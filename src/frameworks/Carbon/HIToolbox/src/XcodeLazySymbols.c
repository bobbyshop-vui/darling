#include <CoreServices/CoreServices.h>
#include <AE/AEDataModel.h>
#include <HIToolbox/CarbonEvents.h>
#include <HIToolbox/HIObject.h>
#include <HIToolbox/HITheme.h>
#include <HIToolbox/Menus.h>
#include <string.h>

typedef ControlRef HIViewRef;
typedef UInt16 ThemeMenuType;
typedef CGSize HISize;
typedef struct HIThemeMenuItemDrawInfo HIThemeMenuItemDrawInfo;
typedef struct HIThemeTextInfo HIThemeTextInfo;

struct MenuTrackingData {
	MenuRef menu;
	MenuItemIndex itemSelected;
	MenuItemIndex itemUnderMouse;
	Rect itemRect;
	SInt32 virtualMenuTop;
	SInt32 virtualMenuBottom;
};
typedef struct MenuTrackingData MenuTrackingData;

__attribute__((visibility("default"))) OSErr AESuspendTheCurrentEvent(const AppleEvent *theAppleEvent)
{
	(void)theAppleEvent;
	return errAEEventNotHandled;
}

__attribute__((visibility("default"))) OSErr AEResumeTheCurrentEvent(const AppleEvent *theAppleEvent, const AppleEvent *reply,
							 AEEventHandlerUPP dispatcher, SRefCon handlerRefcon)
{
	(void)theAppleEvent;
	(void)reply;
	(void)dispatcher;
	(void)handlerRefcon;
	return errAEEventNotHandled;
}

__attribute__((visibility("default"))) OSStatus GetMenuTrackingData(MenuRef theMenu, MenuTrackingData *outData)
{
	(void)theMenu;
	if (outData)
		memset(outData, 0, sizeof(*outData));
	return unimpErr;
}

__attribute__((visibility("default"))) OSStatus HIMenuGetContentView(MenuRef inMenu, ThemeMenuType inMenuType, HIViewRef *outView)
{
	(void)inMenu;
	(void)inMenuType;
	if (outView)
		*outView = NULL;
	return outView ? unimpErr : paramErr;
}

__attribute__((visibility("default"))) OSStatus HIMouseTrackingGetParameters(OSType inSelector, EventTime *outTime, HISize *outDistance)
{
	(void)inSelector;
	if (outTime)
		*outTime = 0;
	if (outDistance)
		memset(outDistance, 0, sizeof(*outDistance));
	return unimpErr;
}

__attribute__((visibility("default"))) OSStatus HIThemeDrawMenuItem(const HIRect *inMenuRect, const HIRect *inItemRect,
							 const HIThemeMenuItemDrawInfo *inItemDrawInfo, CGContextRef inContext,
							 HIThemeOrientation inOrientation, HIRect *outContentRect)
{
	(void)inMenuRect;
	(void)inItemRect;
	(void)inItemDrawInfo;
	(void)inContext;
	(void)inOrientation;
	if (outContentRect)
		memset(outContentRect, 0, sizeof(*outContentRect));
	return unimpErr;
}

__attribute__((visibility("default"))) OSStatus HIThemeDrawMenuSeparator(const HIRect *inMenuRect, const HIRect *inItemRect,
								  const HIThemeMenuItemDrawInfo *inItemDrawInfo, CGContextRef inContext,
								  HIThemeOrientation inOrientation)
{
	(void)inMenuRect;
	(void)inItemRect;
	(void)inItemDrawInfo;
	(void)inContext;
	(void)inOrientation;
	return unimpErr;
}

__attribute__((visibility("default"))) OSStatus HIThemeDrawTextBox(CFTypeRef inString, const HIRect *inBounds, HIThemeTextInfo *inTextInfo,
							 CGContextRef inContext, HIThemeOrientation inOrientation)
{
	(void)inString;
	(void)inBounds;
	(void)inTextInfo;
	(void)inContext;
	(void)inOrientation;
	return unimpErr;
}

__attribute__((visibility("default"))) OSStatus HIViewSetDrawingEnabled(HIViewRef inView, Boolean inEnabled)
{
	(void)inView;
	(void)inEnabled;
	return unimpErr;
}

__attribute__((visibility("default"))) OSStatus HIViewSetNeedsDisplay(HIViewRef inView, Boolean inNeedsDisplay)
{
	(void)inView;
	(void)inNeedsDisplay;
	return unimpErr;
}
