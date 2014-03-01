/*!
  @class PatchBank
  @author Leigh M. Smith
  @description
     Class holding a collection of MIDISysExSynths
*/
#import <AppKit/AppKit.h>
#import "MIDISysExSynth.h"

@interface PatchBank: NSObject <NSCoding>
{
    NSMutableArray *theBank;	// Mutuable Dictionary?
    NSMutableArray *sortOrder;  // Ordering of fields & therefore the records.
}

- generatePatchListsForSequence;
- (int) count;
- (id) patchAtIndex: (int) index;
- (void) deletePatchAtIndex: (int) index;
- (void) newPatch: (id) patch;
- (void) encodeWithCoder: (NSCoder *) aCoder;
- (id) initWithCoder:(NSCoder *) aDecoder;
- (id) initWithSMFData: (NSData *) data;
- (NSData *) dataEncodingSMF;
- (void) sortSynths: (NSMutableArray *) sortOrder;
- (NSEnumerator *) objectEnumerator;

@end