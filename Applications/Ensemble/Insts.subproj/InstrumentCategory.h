#ifndef __MK_InstrumentCategory_H___
#define __MK_InstrumentCategory_H___
/* Extension of the Music Kit Instrument class via a Category.
 * We add a few methods for efficiently sending ourselves parameter updates.
 */

#import <musickit/musickit.h>

@interface Instrument(InstrumentCategory)

- updatePar:(MKPar)parNum asDouble:(double)val;
- updatePar:(MKPar)parNum asInt:(int)val;
- updatePar:(MKPar)parNum asString:(char *)val;
- updatePar:(MKPar)parNum asWave:(id)val;
- updateController:(int)controlChange toValue:(int)val;

@end
#endif
