/*
 * Class declaring Blue Chip Axon NGC-77 MIDI Guitar Controller patch management.
 * Leigh Smith 7/9/97
 */

/*
Perhaps use NSRange to give us a portion of the data to compare against?

Try and display as much of the data simultaneously as possible, so the user can visualise the effect across the entire fretboard, making the intangible tangible. Ideally graphical
*/
#import "AxonNGC77.h"

#define PATCHNAME_LEN 14
#define AXON_LENGTH 9                   // position of the first byte of the length field (3 bytes long) 
#define AXON_DATA (AXON_LENGTH + 3)     // position of the first byte of the data field (length from AXON_LENGTH)

@implementation AxonNGC77

// inline functions to simplify the data extraction

inline static int axonLength(id msg, int start)
{
   return (([(msg) messageByteAt: (start)] << 14) + 
	   ([(msg) messageByteAt: (start)+1] << 7) +
            [(msg) messageByteAt: (start)+2]);
}

inline static int axonData(id msg, int start)
{
   return (([(msg) messageByteAt: (start)+1] << 7) + [(msg) messageByteAt: (start)]);
}

// Create ourselves a SysExMessage to transmit our parameter updates.
- init
{
   [super init];
   NSLog(@"Made it into AxonNGC77 initialisation\n");
// update = [[[SysExMessage alloc] init] retain]; // SysExMessage is one of ours and doesn't get an autorelease check whether the standard behaviour is to or not.
   update = [[SysExMessage alloc] init];
   patchName = [[NSMutableString stringWithCapacity: PATCHNAME_LEN] retain];

   [update initWithString: @"f0,00,20,2d,0c,00,01,01,00,00,00,f7"];
   return self;
}

- (void) loadAndShowNib
{
    [super initWithWindowNibName: @"AxonNGC77" owner:self];
    [[self window] setDocumentEdited: NO];
    [self displayPatch];
}

// Create a new empty instance of a patch and download it and display it
- (id) initWithEmptyPatch
{
   [super initWithEmptyPatch];
   [self init];
   // this isn't right
   [patch initWithString:@"f0,00,20,2d,0c,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,f7"];
   // Need to do something with Channel semantics here.
   [self loadAndShowNib];
   return self;
}

// process a new patch
- (void) acceptNewPatch: (SysExMessage *) msg
{
    [super acceptNewPatch:msg];
//    [self setMidiChannel:[msg messageByteAt: MIDI_CHAN]];
    [self loadAndShowNib];
}

// Ensure it's an Axon NGC-77
- (BOOL) isAnNGC77: (SysExMessage *) msg
{
    return([msg messageByteAt: 0] == 0xF0 &&
	   [msg messageByteAt: 1] == 0x00 &&
	   [msg messageByteAt: 2] == 0x20 &&
	   [msg messageByteAt: 3] == 0x2d &&
	   [msg messageByteAt: 4] == 0x0c);
}

// Given a sys-ex message, returns YES if it's updating a NGC-77 parameter.
//
// Single Paramer
// Byte              5    6    7    8 
// Arrange Main    - 0x00 0x01 0x01 0x?? 
// Scratch Main    - 0x00 0x11 0x01 0x?? 
// Arrange Segment - 0x00 0x02 0xnn 0x?? -  nn = 0-12,
// Scratch Segment - 0x00 0x12 0xnn 0x?? -  nn = 0-1
- (BOOL) isParameterUpdate: (SysExMessage *) msg
{
    return([self isAnNGC77: msg] && [msg messageByteAt: 5] == 0x00);
}

// Check if the sys-ex message is a new NGC-77 patch message
//
// Byte           5    6    7    8 
// Total Dump   - 0x10 0x00 0x00 0x00
// Arrange Dump - 0x10 0x00 0x01 0x00
// Scratch Dump - 0x10 0x00 0x11 0x00
- (BOOL) isNewPatch: (SysExMessage *) msg
{
//	   [msg messageByteAt: 6] == 0x00 &&
//	   [msg messageByteAt: 7] == 0x00 &&
//	   [msg messageByteAt: 8] == 0x00 &&

    return([self isAnNGC77: msg] && [msg messageByteAt: 5] == 0x10);
}

// The NGC-77 has a dump request facility.
+ (BOOL) canUploadPatches
{
    return YES;
}

// send the NGC-77 dump request message.
//RECEIVE
//TOTAL DUMP REQUEST
//Byte  1: #F0      -- SYSEX
//Byte  2: #00      -- ID header
//Byte  3: #20      -- 1st byte of manufacturer's ID
//Byte  4: #2D      -- 2nd byte of manufacturer's ID
//Byte  5: #0C      -- model  ID : AXON NGC77 5.xx
//Byte  6: #30      -- device ID : dump request, else not evaluated
//Byte  7: #00      -- address high
//Byte  8: #00      -- address mid; TOTAL
//Byte  9: #00      -- address low
//Byte 10: #F7      -- EOX
+ (void) requestPatchUpload
{
    SysExMessage *dumpRequest = [[SysExMessage alloc] init];

    [dumpRequest initWithString: @"f0,00,20,2d,0c,30,00,00,00,f7"];
    [dumpRequest send];
}

// Extract the patchname string from the patch
// 28 bytes before checksum : patchname is formatted as one char per 2 byte word, LSB first - probably Unicode, try using inbuilt conversion.
// shouldn't be necessary if we encode it properly from the patch.
//- (NSString *) patchDescription
//{
//    return patchName;
//}

// Assign the named string (accepting the first PATCHNAME_LEN characters into the sysex patch).
// Pads the string to PATCHNAME_LEN.
- (void) setPatchDescription: (NSString *) name
{
    [super setPatchDescription: name];
    // TODO assign into the patch at the right place
}

// interpret the complete patch setting appropriate ivars.
/*
 This is the order the parameters are sent for each segment, so scratch has NORM then HOLD

02: PROGRAM NO.
00: BANK MSB
01: BANK LSB
03: VOLUME
04: TRANSPOSE
05: QUANTIZE
06: PAN POS
07: PAN SPREAD
08: REVERB
20: FINGER PICK
0C: VELOCITY SENS
21: VELOCITY OFFS
22: TRIGGER LEVEL
0D: PICK CONTROL
0E: P1 POSITION
0F: P1 VALUE
10: P2 POSITION
11: P2 VALUE

General structure seems to be:
arrange/chain/scratch data
array of segments
patch name

A general parameter object and segment object would be beneficial, creating a model.

All we are doing at the moment is extracting the name from the sysex message
*/
- (void) interpretPatch: (SysExMessage *) newPatch
{
    unsigned char compactedByte;
    int i;
    char patchNameAscii[PATCHNAME_LEN+1];
    NSRange patchNameRange;
    int dataLength = axonLength(patch, AXON_LENGTH);
    int compactLength = dataLength / 2;
    NSMutableData *compactedPatch = [NSMutableData dataWithCapacity: compactLength]; // 8 bit data from patch

   // check the length matches the length of the _data bytes_ of the message (excluding checksum and EOX) 
   // and the checksum is correct 128 - (SUM (data_bytes) MODULO 128)
// No this should be done when we receive the data, not when we display it.
// eventually split this out.
    for(i = 0; i < dataLength; i += 2) {
	compactedByte = axonData(newPatch, AXON_DATA + i);
	NSLog(@"%3d: %02X, %3d\n", i/2, compactedByte, compactedByte);
        [compactedPatch appendBytes: &compactedByte length: 1];
    }

    // extract the last PATCHNAME_LEN bytes as the patch name. 
    patchNameRange.location = compactLength - PATCHNAME_LEN; // -1 for converting length to ordinal 
    patchNameRange.length = PATCHNAME_LEN;
    [compactedPatch getBytes: patchNameAscii range: patchNameRange];
    patchNameAscii[PATCHNAME_LEN] = '\0';
    [self setPatchDescription: [NSString stringWithCString: patchNameAscii]];
    NSLog([self patchDescription]);
}


// Display the segment selected between the guitar neck and pickup views
- (void) displaySelectedSegment: sender
{
}

// display the Hold segment inspector
// SHouldn't be much different from the other segment inspector.
- (void) displayHoldSegment: sender
{
}

// display the complete patch to the user interface
- (void) displayPatch
{
// [pickup pickCursor: 1 location: p1];
// [pickup pickCursor: 2 location: p2];
  // [guitarNeck fretCursor: 1 location: fretNumber];
// [guitarNeck stringCursor: 1 location: stringNumber];
   [self interpretPatch: patch];
   [[self window] makeKeyAndOrderFront: nil];
}

@end
