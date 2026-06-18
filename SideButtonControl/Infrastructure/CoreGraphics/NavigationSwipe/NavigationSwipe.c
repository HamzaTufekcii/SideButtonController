//
//  NavigationSwipe.c
//  SideButtonControl
//
//  See NavigationSwipe.h. We build the raw byte layout of a gesture CGEvent by hand:
//  take an empty gesture event, strip the trailing fields CGEvent adds, and append a
//  serialized IOHID event-queue collection (a parent "hand" digitizer event with no
//  touches, a vendor token, and the swipe gesture descriptor fields). The struct
//  layouts below mirror IOKit's IOHID ABI so the system parses them by offset.
//

#include "NavigationSwipe.h"

#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef int32_t SBCIOFixed;

// --- IOHID ABI mirror (Apple IOKit, APSL) -----------------------------------

enum {
    kSBCEventTypeVendorDefined = 1,
    kSBCEventTypeDigitizer = 11,
};

enum { kSBCEventOptionIsCollection = 0x00000002 };
enum { kSBCDigitizerTransducerTypeHand = 0x23 };
enum { kSBCDigitizerOrientationTypeQuality = 2 };

// Undocumented gesture-event field tags and subtype, recovered from the binary format.
enum { kSBCGestureSubtypeSwipe = 0x10 };

#define SBC_IOHIDEVENT_BASE \
    uint32_t size;          \
    uint32_t type;          \
    uint64_t timestamp;     \
    uint32_t options;

typedef struct {
    SBC_IOHIDEVENT_BASE
    uint16_t usagePage;
    uint16_t usage;
    uint32_t version;
    uint32_t length;
    uint8_t  data[];
} SBCVendorDefinedEventData;

typedef struct {
    SBC_IOHIDEVENT_BASE
    struct { SBCIOFixed x, y, z; } position;
    uint32_t   transducerIndex;
    uint32_t   transducerType;
    uint32_t   identity;
    uint32_t   eventMask;
    uint32_t   childEventMask;
    uint32_t   buttonMask;
    SBCIOFixed tipPressure;
    SBCIOFixed barrelPressure;
    SBCIOFixed twist;
    uint32_t   orientationType;
    union {
        struct { SBCIOFixed x, y; } tilt;
        struct { SBCIOFixed altitude, azimuth; } polar;
        struct { SBCIOFixed quality, density, irregularity, majorRadius, minorRadius; } quality;
    } orientation;
} SBCDigitizerEventData;

typedef struct {
    uint64_t timeStamp;
    uint64_t deviceID;
    uint32_t options;
    uint32_t eventCount;
} SBCSystemQueueElement;

// --- Field serialization ----------------------------------------------------

static void sbc_appendHeader(CFMutableDataRef data, uint8_t field, uint8_t type, uint16_t count) {
    uint16_t swappedCount = CFSwapInt16HostToBig(count);
    CFDataAppendBytes(data, (const UInt8 *)&swappedCount, sizeof(uint16_t));
    CFDataAppendBytes(data, &type, 1);
    CFDataAppendBytes(data, &field, 1);
}

static void sbc_appendIntegerField(CFMutableDataRef data, uint8_t field, uint32_t value) {
    sbc_appendHeader(data, field, 0x40, 1);
    uint32_t swapped = CFSwapInt32HostToBig(value);
    CFDataAppendBytes(data, (const UInt8 *)&swapped, sizeof(uint32_t));
}

static void sbc_appendFloatField(CFMutableDataRef data, uint8_t field, Float32 value) {
    sbc_appendHeader(data, field, 0xC0, 1);
    CFSwappedFloat32 swapped = CFConvertFloat32HostToSwapped(value);
    CFDataAppendBytes(data, (const UInt8 *)&swapped, sizeof(CFSwappedFloat32));
}

static uint64_t sbc_uptimeNanoseconds(void) {
    return clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
}

// Builds one gesture CGEvent. `gesturePhase` is 1 for the begin event and 4 for the
// swipe event; the swipe event also carries a direction.
static CGEventRef sbc_createGestureSwipeEvent(uint32_t gesturePhase, bool hasDirection, uint32_t direction) {
    uint64_t timestamp = sbc_uptimeNanoseconds();

    // Parent "hand" collection with no child touches.
    SBCDigitizerEventData parent;
    memset(&parent, 0, sizeof(parent));
    parent.size = (uint32_t)sizeof(SBCDigitizerEventData);
    parent.type = kSBCEventTypeDigitizer;
    parent.timestamp = timestamp;
    parent.options = kSBCEventOptionIsCollection;
    parent.transducerType = kSBCDigitizerTransducerTypeHand;
    parent.orientationType = kSBCDigitizerOrientationTypeQuality;

    // Vendor-defined token (device id 0).
    const size_t vendorPayloadLen = 40;
    const size_t vendorDataSize = sizeof(SBCVendorDefinedEventData) + vendorPayloadLen;
    SBCVendorDefinedEventData *vendorData = malloc(vendorDataSize);
    if (vendorData == NULL) {
        return NULL;
    }
    memset(vendorData, 0, vendorDataSize);
    vendorData->size = (uint32_t)vendorDataSize;
    vendorData->type = kSBCEventTypeVendorDefined;
    vendorData->usagePage = 0xFF00;
    vendorData->usage = 0x1777;
    vendorData->version = 1;
    vendorData->length = (uint32_t)vendorPayloadLen;

    // Base gesture event, serialized so we can splice the IOHID payload onto it.
    CGEventRef proto = CGEventCreate(NULL);
    if (proto == NULL) {
        free(vendorData);
        return NULL;
    }
    CGEventSetType(proto, (CGEventType)29);  // NSEventTypeGesture
    CGEventSetFlags(proto, (CGEventFlags)256);
    CGEventSetTimestamp(proto, timestamp);

    CFDataRef baseData = CGEventCreateData(kCFAllocatorDefault, proto);
    CFRelease(proto);
    if (baseData == NULL) {
        free(vendorData);
        return NULL;
    }
    CFMutableDataRef gestureData = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, baseData);
    CFRelease(baseData);

    // CGEvent appends 24 bytes of gesture fields; the parser expects the IOHID payload
    // immediately after the base event, so remove them.
    if (CFDataGetLength(gestureData) >= 24) {
        CFDataDeleteBytes(gestureData, CFRangeMake(CFDataGetLength(gestureData) - 24, 24));
    }

    // CGEvent field header for the spliced IOHID event-queue blob.
    uint16_t totalSize = (uint16_t)(sizeof(SBCSystemQueueElement) + vendorDataSize + sizeof(SBCDigitizerEventData));
    uint16_t swappedTotalSize = CFSwapInt16HostToBig(totalSize);
    CFDataAppendBytes(gestureData, (const UInt8 *)&swappedTotalSize, 2);
    const UInt8 marker[2] = { 0x10, 0x6D };
    CFDataAppendBytes(gestureData, marker, 2);

    // Event-queue collection header. eventCount = touches (0) + parent + vendor = 2.
    SBCSystemQueueElement queueElement;
    memset(&queueElement, 0, sizeof(queueElement));
    queueElement.timeStamp = timestamp;
    queueElement.options = parent.options;
    queueElement.eventCount = 2;
    CFDataAppendBytes(gestureData, (const UInt8 *)&queueElement, sizeof(queueElement));

    // Parent digitizer event and vendor token.
    CFDataAppendBytes(gestureData, (const UInt8 *)&parent, parent.size);
    CFDataAppendBytes(gestureData, (const UInt8 *)vendorData, vendorDataSize);
    free(vendorData);

    // Gesture descriptor fields.
    sbc_appendIntegerField(gestureData, 0x6E, kSBCGestureSubtypeSwipe);
    sbc_appendIntegerField(gestureData, 0x6F, 0);
    sbc_appendIntegerField(gestureData, 0x70, 0);
    sbc_appendIntegerField(gestureData, 0x84, gesturePhase);
    sbc_appendIntegerField(gestureData, 0x85, 0);
    if (hasDirection) {
        sbc_appendIntegerField(gestureData, 0x73, direction);
    }
    sbc_appendFloatField(gestureData, 0x8B, 0.0f);
    sbc_appendFloatField(gestureData, 0x8C, 0.0f);

    CGEventRef event = CGEventCreateFromData(kCFAllocatorDefault, gestureData);
    CFRelease(gestureData);
    return event;
}

bool SBCPostNavigationSwipe(SBCNavigationSwipeDirection direction) {
    CGEventRef begin = sbc_createGestureSwipeEvent(1, false, 0);
    CGEventRef swipe = sbc_createGestureSwipeEvent(4, true, (uint32_t)direction);
    if (begin == NULL || swipe == NULL) {
        if (begin != NULL) { CFRelease(begin); }
        if (swipe != NULL) { CFRelease(swipe); }
        return false;
    }

    CGEventPost(kCGHIDEventTap, begin);
    CGEventPost(kCGHIDEventTap, swipe);
    CFRelease(begin);
    CFRelease(swipe);
    return true;
}
