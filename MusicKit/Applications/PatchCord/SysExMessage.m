/*
 ** Routines to control sys-ex MIDI messages being received and sent, converting
 ** to and from ASCII and retrieving individual bytes from the message.
 */
#import <MusicKit/MusicKit.h>
#import "SysExReceiver.h"
#import "SysExMessage.h"

@implementation SysExMessage

// class variables holding our MIDI objects.
/*! The MIDI device for receiving MIDI messages. */
static MKMidi *sysExMidiInput;
/*! The MIDI device for sending MIDI messages. */
static MKMidi *sysExMidiOutput;
static SysExReceiver *sysExReceiver;

// Put any MusicKit errors up in an alert panel
static void handleMKError(NSString *msg)
{
    NSAlert *mkErrorAlert = [[NSAlert alloc] init];
    
    [mkErrorAlert setMessageText: msg];
    [mkErrorAlert addButtonWithTitle: @"Quit"];
    [mkErrorAlert setAlertStyle: NSCriticalAlertStyle];
    
    if ([mkErrorAlert runModal] == NSAlertSecondButtonReturn)
        [NSApp terminate: NSApp];
}

// Class initialization
+ (void) initialize
{
    if (self == [SysExMessage class]) {
        MKSetErrorProc(handleMKError);
	sysExMidiInput = nil;	// initialise our static class vars.
	sysExMidiOutput = nil;	// initialise our static class vars.
	sysExReceiver = [[SysExReceiver alloc] init];
    }
}

+ (void) openOnDevice: (NSString *) deviceName forInput: (BOOL) isInput
{
    if (isInput) {
        if (sysExMidiInput) {
            [sysExMidiInput close];
            [sysExMidiInput release];
        }
        sysExMidiInput = [deviceName length] == 0 ? [[MKMidi midi] retain] : [[MKMidi midiOnDevice: deviceName] retain];
        // Connect the note sender of the MIDI input device to the SysEx note receiver.
        [[sysExMidiInput noteSender] connect: [sysExReceiver noteReceiver]];
        [sysExMidiInput setUseInputTimeStamps: NO];
        [sysExMidiInput open];
        [sysExMidiInput run];
        [sysExMidiInput setOutputTimed: NO];
    }
    else {
        if (sysExMidiOutput) {
            [sysExMidiOutput close];
            [sysExMidiOutput release];
        }
        sysExMidiOutput = [deviceName length] == 0 ? [[MKMidi midi] retain] : [[MKMidi midiOnDevice: deviceName] retain];
        // [sysExMidiOutput setOutputTimed: NO];
    }
    [MKConductor setFinishWhenEmpty: NO];
    [MKConductor setClocked: YES];
    [MKConductor startPerformance];
}

// Enable reception of MIDI data to our designated system exclusive receiver.
+ (void) open
{
    [SysExMessage openOnDevice: @"" forInput: YES];
}

// close down the System Exclusive handling
+ (void) close
{
    [MKConductor finishPerformance];
    [sysExMidiInput stop];
    [sysExMidiInput close];
    [sysExMidiInput autorelease];
    sysExMidiInput = nil;
}

+ (MKMidi *) midiDeviceForInput: (BOOL) isInput
{
    return [[isInput ? sysExMidiInput : sysExMidiOutput retain] autorelease];
}

// Hand on synth registrations to the sysExReceiver.
+ (void) registerSynth: (MIDISysExSynth *) sender
{
    [sysExReceiver registerSynth: sender];
}

// and enabling/disabling of messages
+ (void) enable
{
    [sysExReceiver enable];
}

+ (void) disable
{
    [sysExReceiver disable];
}

+ (NSMutableArray *) registeredSynths
{
    return [sysExReceiver registeredSynths];
}

+ (SysExReceiver *) receiver
{
    return sysExReceiver;
}

// initialise our data structure to empty
- (id) init
{
    [super init];
    message = [[NSMutableData dataWithCapacity: 256] retain];
    return self;
}

// initialise our data structure to the new mutable data
// Find the F0..F7 data string within the supplied data object and assign it to message
// Why does this have to be mutable?
- (id) initWithMessage: (NSMutableData *) newMessage
{
    [super init];
    message = [[NSMutableData dataWithData: newMessage] retain];
    return self;
}

// if there is a sysEx parameter there, extract it into the message return YES, no if there wasn't a sysEx message
- (id) initWithNote: (MKNote *) note
{
//  if([note isParPresent:
    [self initWithString: [note parAsString: MK_sysExclusive]];
    return self;
}

// Decode the ASCII System Exclusive String into binary
// and assign it in a NSMutableData buffer with the number of bytes stored.
// Accepts delimiters of commas, white space between hexadecimal numbers
- (void) initWithString: (NSString *) exclusiveString
{
    unsigned int length = 0;
    unsigned int midiByte;	// bigger than what we want but this avoids problems during scanning
    NSScanner *exclScanner;
    NSCharacterSet *hexDigitSeparatorsSet; // Mutable character sets are less efficient
    NSMutableCharacterSet *whitespaceSet;  // to use than immutable character sets.
    
    exclScanner = [NSScanner scannerWithString: exclusiveString];
    whitespaceSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
    [whitespaceSet addCharactersInString: @","];   // delimiters: commas, white space. 
    hexDigitSeparatorsSet = [whitespaceSet copy];
    [whitespaceSet release];
    [exclScanner setCharactersToBeSkipped: hexDigitSeparatorsSet];
    
    while ([exclScanner isAtEnd] == NO) {
  	if([exclScanner scanHexInt: &midiByte] == YES) {
	    if(midiByte > 0xff) {
		midiByte &= 0xff;
	    }
	    else {
		// Check for first byte being f0, last being f7?
		// This needs checking regardless of binary or ascii input.
                [self setMessageByteAt: length to: (unsigned char) midiByte];
                length++;
            }
	}
	else {			// non hex int input encountered, TODO report the error
	    NSLog(@"Error reading hex numbers\n");
	}
    }
    [message setLength: length];
}


// Encode the system exclusive message into ascii NSString according to the format parameter.
- (NSString *) exportToAscii: (SysExMsgExportFormat) format
{
    unsigned int byteCount, i;
    NSString *hexString;
    
    byteCount = [message length];
    if(byteCount > 0) {
	hexString = [NSString stringWithFormat: @"%02X", [self messageByteAt: 0]];
	for(i = 1; i < byteCount; i++) {
	    hexString = [hexString stringByAppendingFormat: @",%02X", [self messageByteAt: i]];
	}
	return hexString;     // I guess NSString has marked it to be autoreleased already
    }
    else
	return nil;                        // bodged for now (TODO)
}

// copying protocol method as per the NSCopying protocol
- (id) copyWithZone: (NSZone *) zone
{
    SysExMessage *copy = [[SysExMessage alloc] initWithMessage: message];
    return copy;
}

// how many bytes in the sysex message
- (unsigned int) length
{
    return [message length];
}

// Return the byte (unsigned char) in the SysEx message at the index (from 0).
- (unsigned char) messageByteAt: (unsigned int) index
{
    return (* ((unsigned char *) [message bytes] + index));
}

// Set the byte (unsigned char) in the SysEx message at the index (from 0).
- (void) setMessageByteAt: (unsigned int) index to: (unsigned char) value
{
    NSRange changeSingleByte = { index, 1 };
    [message replaceBytesInRange: changeSingleByte withBytes: &value];
}

// make the sysEx message be tested against the receiver.
- (void) receive
{
    [sysExReceiver respondToMsg: self];
}

// return a note version of the message
- (MKNote *) note
{
    NSString *s = [self exportToAscii: musicKitSysExSyntax];
    MKNote *myNote = [[MKNote alloc] init];
    
    [myNote setPar: MK_sysExclusive toString: s];
    return [myNote autorelease];
}


// send the given SysEx message
- (void) send
{
    BOOL loopBack = NO;
    
    NSLog(@"Note %@", [self note]);
    // [[sysExMidiInput noteReceiver] receiveAndFreeNote: [self note]];
    // Ok for some reason this doesn't work??
    if (!loopBack)
        [[sysExMidiInput noteReceiver] receiveNote: [self note]];
    else    // loop back to check other synths, only for debugging.
        [self receive];
}

- (NSString *) description
{
    return [self exportToAscii: spaceSeparated];
}

@end

