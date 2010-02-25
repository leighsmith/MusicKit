/*!
 * @class QuadraverbGT
 *
 * Declaration for Alesis Quadraverb GT Digital MultiFX Unit
 * Leigh Smith 6/9/98
 *
 * $Id$
 */
#import <AppKit/AppKit.h>
#import "../MIDISysExSynth.h"

@interface QuadraverbGT : MIDISysExSynth
{
    id configuration;
    SysExMessage *update;
}

/*!
 */
- init;

/*!
  @brief Create a new empty instance of a patch and download it and display it
 */
- (id) initWithEmptyPatch;

/*!
 */
- (BOOL) isParameterUpdate: (SysExMessage *) msg;

/*!
  @brief process a new patch
 */
- (void) acceptNewPatch: (SysExMessage *) msg;

/*!
 */
- (BOOL) isNewPatch: (SysExMessage *) msg;

/*!
  @brief display the complete patch to the user interface
*/
- (void) displayPatch;

@end
