#import "HSBlackmagicDeviceSpeedEditor.h"

@interface HSBlackmagicDeviceSpeedEditor ()
@end

@implementation HSBlackmagicDeviceSpeedEditor
- (id)initWithDevice:(IOHIDDeviceRef)device manager:(id)manager serialNumber:serialNumber {
    self = [super init];
    if (self) {
        self.deviceType = @"Speed Editor";
        self.serialNumber = serialNumber;
        self.device = device;
        self.isValid = YES;
        self.manager = manager;
        self.callbackRef = LUA_NOREF;
        self.selfRefCount = 0;
        
        self.firstTimeAuthenticating = YES;
        
        self.batteryCharging = NO;
        self.batteryLevel = @-1;
        
        self.ledLookup = @{
            @"CLOSE UP":                @(1 <<  0),
            @"CUT":                     @(1 <<  1),
            @"DIS":                     @(1 <<  2),
            @"SMTH CUT":                @(1 <<  3),
            @"TRANS":                   @(1 <<  4),
            @"SNAP":                    @(1 <<  5),
            @"CAM 7":                   @(1 <<  6),
            @"CAM 8":                   @(1 <<  7),
            @"CAM 9":                   @(1 <<  8),
            @"LIVE OWR":                @(1 <<  9),
            @"CAM 4":                   @(1 << 10),
            @"CAM 5":                   @(1 << 11),
            @"CAM 6":                   @(1 << 12),
            @"VIDEO ONLY":              @(1 << 13),
            @"CAM 1":                   @(1 << 14),
            @"CAM 2":                   @(1 << 15),
            @"CAM 3":                   @(1 << 16),
            @"AUDIO ONLY":              @(1 << 17),
        };
        
        self.jogLEDLookup = @{
            @"JOG":                     @(1 <<  0),
            @"SHTL":                    @(1 <<  1),
            @"SCRL":                    @(1 <<  2),
        };
        
        self.jogModeLookup = @{
            //@"RELATIVE 0":              @0,                       // Relative
            @"JOG":                     @1,                         // Send an "absolute" position (based on the position when mode was set) -4096 -> 4096 range ~ half a turn
            @"SHTL":                    @2,                         // Same as mode 0 ?
            @"SCRL":                    @3,                         // Same as mode 1 but with a small dead band around zero that maps to 0
        };
        
        self.jogModeReverseLookup = @{
            //[NSNumber numberWithInt:0]: @"RELATIVE 0",            // Relative
            [NSNumber numberWithInt:1]: @"JOG",                     // Send an "absolute" position (based on the position when mode was set) -4096 -> 4096 range ~ half a turn
            [NSNumber numberWithInt:2]: @"SHTL",                    // Same as mode 0 ?
            [NSNumber numberWithInt:3]: @"SCRL",                    // Same as mode 1 but with a small dead band around zero that maps to 0
        };

        self.buttonLookup = @{
            @"SMART INSRT":             @0x01,
            @"APPND":                   @0x02,
            @"RIPL OWR":                @0x03,
            @"CLOSE UP":                @0x04,
            @"PLACE ON TOP":            @0x05,
            @"SRC OWR":                 @0x06,
            @"IN":                      @0x07,
            @"OUT":                     @0x08,
            @"TRIM IN":                 @0x09,
            @"TRIM OUT":                @0x0a,
            @"ROLL":                    @0x0b,
            @"SLIP SRC":                @0x0c,
            @"SLIP DEST":               @0x0d,
            @"TRANS DUR":               @0x0e,
            @"CUT":                     @0x0f,
            @"DIS":                     @0x10,
            @"SMTH CUT":                @0x11,
            @"SOURCE":                  @0x1a,
            @"TIMELINE":                @0x1b,
            @"SHTL":                    @0x1c,
            @"JOG":                     @0x1d,
            @"SCRL":                    @0x1e,
            @"ESC":                     @0x31,
            @"SYNC BIN":                @0x1f,
            @"AUDIO LEVEL":             @0x2c,
            @"FULL VIEW":               @0x2d,
            @"TRANS":                   @0x22,
            @"SPLIT":                   @0x2f,
            @"SNAP":                    @0x2e,
            @"RIPL DEL":                @0x2b,
            @"CAM 1":                   @0x33,
            @"CAM 2":                   @0x34,
            @"CAM 3":                   @0x35,
            @"CAM 4":                   @0x36,
            @"CAM 5":                   @0x37,
            @"CAM 6":                   @0x38,
            @"CAM 7":                   @0x39,
            @"CAM 8":                   @0x3a,
            @"CAM 9":                   @0x3b,
            @"LIVE OWR":                @0x30,
            @"VIDEO ONLY":              @0x25,
            @"AUDIO ONLY":              @0x26,
            @"STOP PLAY":               @0x3c
        };
        
        self.defaultButtonState = @{
            @"SMART INSRT":             @NO,
            @"APPND":                   @NO,
            @"RIPL OWR":                @NO,
            @"CLOSE UP":                @NO,
            @"PLACE ON TOP":            @NO,
            @"SRC OWR":                 @NO,
            @"IN":                      @NO,
            @"OUT":                     @NO,
            @"TRIM IN":                 @NO,
            @"TRIM OUT":                @NO,
            @"ROLL":                    @NO,
            @"SLIP SRC":                @NO,
            @"SLIP DEST":               @NO,
            @"TRANS DUR":               @NO,
            @"CUT":                     @NO,
            @"DIS":                     @NO,
            @"SMTH CUT":                @NO,
            @"SOURCE":                  @NO,
            @"TIMELINE":                @NO,
            @"SHTL":                    @NO,
            @"JOG":                     @NO,
            @"SCRL":                    @NO,
            @"ESC":                     @NO,
            @"SYNC BIN":                @NO,
            @"AUDIO LEVEL":             @NO,
            @"FULL VIEW":               @NO,
            @"TRANS":                   @NO,
            @"SPLIT":                   @NO,
            @"SNAP":                    @NO,
            @"RIPL DEL":                @NO,
            @"CAM 1":                   @NO,
            @"CAM 2":                   @NO,
            @"CAM 3":                   @NO,
            @"CAM 4":                   @NO,
            @"CAM 5":                   @NO,
            @"CAM 6":                   @NO,
            @"CAM 7":                   @NO,
            @"CAM 8":                   @NO,
            @"CAM 9":                   @NO,
            @"LIVE OWR":                @NO,
            @"VIDEO ONLY":              @NO,
            @"AUDIO ONLY":              @NO,
            @"STOP PLAY":               @NO,
        };
        
        self.buttonStateCache = [NSMutableDictionary dictionaryWithDictionary:self.defaultButtonState];
        
        self.defaultLEDCache = @{
            @"CLOSE UP":                @NO,
            @"CUT":                     @NO,
            @"DIS":                     @NO,
            @"SMTH CUT":                @NO,
            @"TRANS":                   @NO,
            @"SNAP":                    @NO,
            @"CAM 7":                   @NO,
            @"CAM 8":                   @NO,
            @"CAM 9":                   @NO,
            @"LIVE OWR":                @NO,
            @"CAM 4":                   @NO,
            @"CAM 5":                   @NO,
            @"CAM 6":                   @NO,
            @"VIDEO ONLY":              @NO,
            @"CAM 1":                   @NO,
            @"CAM 2":                   @NO,
            @"CAM 3":                   @NO,
            @"AUDIO ONLY":              @NO,
            @"JOG":                     @NO,
            @"SHTL":                    @NO,
            @"SCRL":                    @NO,
        };
        
        self.ledCache = [NSMutableDictionary dictionaryWithDictionary:self.defaultLEDCache];

        //NSLog(@"Added new Speed Editor device %p with IOKit device %p from manager %p", (__bridge void *)self, (void*)self.device, (__bridge void *)self.manager);
    }
    return self;
}

@end
