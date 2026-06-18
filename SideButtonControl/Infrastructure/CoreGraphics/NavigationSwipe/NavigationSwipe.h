//
//  NavigationSwipe.h
//  SideButtonControl
//
//  Synthesizes a discrete two-finger navigation swipe (NSEventTypeGesture / swipe),
//  the same gesture the trackpad sends for browser back/forward. Unlike a Cmd+[
//  keystroke, an unhandled swipe is silently ignored by the system, so there is no
//  "unhandled shortcut" beep at navigation boundaries or on the desktop.
//
//  This is our own implementation of the gesture-event byte format. The IOHID event
//  struct layouts it mirrors are an OS ABI (Apple's IOKit, APSL); none of the GPL
//  serializer code from third-party tools is used here.
//

#ifndef NavigationSwipe_h
#define NavigationSwipe_h

#include <stdbool.h>
#include <stdint.h>

// Values mirror IOKit's IOHIDSwipeMask. In macOS, swiping left navigates Back and
// swiping right navigates Forward.
typedef enum {
    SBCNavigationSwipeLeft  = 4, // Back
    SBCNavigationSwipeRight = 8, // Forward
} SBCNavigationSwipeDirection;

// Posts a begin + swipe gesture pair to the HID event tap. Returns true if both
// events were created and posted.
bool SBCPostNavigationSwipe(SBCNavigationSwipeDirection direction);

#endif /* NavigationSwipe_h */
