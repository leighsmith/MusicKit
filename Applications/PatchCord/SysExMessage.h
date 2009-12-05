#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>

@class MIDISysExSynth;        // Forward declaration of the parameter type for registerSynth:
@class SysExReceiver;

// Need enumerated type for format of Ascii Export
typedef enum _exportFormat {
  musicKitSysExSyntax = 0, // for comma delimited formats
  spaceSeparated,
} SysExMsgExportFormat;

@interface SysExMessage: NSObject <NSCopying>
{
   NSMutableData *message;	// the sysex message data
}

+ (void) open;
+ (void) close;
+ (void) registerSynth: (MIDISysExSynth *) sender;
+ (NSMutableArray *) registeredSynths;
+ (SysExReceiver *) receiver;
+ (void) enable;
+ (void) disable;
- (id) init;
- (void) receive;
- (id) initWithMessage: (NSMutableData *) message;
- (id) initWithNote: (MKNote *) note;
- (void) initWithString: (NSString *) exclusiveString;
- (NSString *) exportToAscii: (SysExMsgExportFormat) format;
- (MKNote *) note;
- (id) copyWithZone: (NSZone *) zone;
- (unsigned int) length;
- (unsigned char) messageByteAt: (unsigned int) index;
- (void) setMessageByteAt: (unsigned int) index to: (unsigned char) value;
- (void) send;
- (NSString *) description;
@end