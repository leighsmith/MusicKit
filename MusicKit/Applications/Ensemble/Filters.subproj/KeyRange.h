#ifndef __MK_KeyRange_H___
#define __MK_KeyRange_H___
#import "musickit/musickit.h"
#import "EnsembleNoteFilter.h"

@interface KeyRange : EnsembleNoteFilter
  /* A simple note filter that allows notes within a specified range,
   * and handles trasnsposition. 
   */
{
@public
    id rangeField;
    id minKeySlider;
    id maxKeySlider;
    id transpositionField;
    id transpositionSlider;
@private
    int minKey, maxKey, transposition;
    id tagTable;
}

- init;
- setMinKey:(int)aKey;
- setMaxKey:(int)aKey;
- takeMinKeyFrom:sender;
- takeMaxKeyFrom:sender;
- takeTranspositionFrom:sender;
- (int)minKey;
- (int)maxKey;
- realizeNote:aNote fromNoteReceiver:aNoteReceiver;

@end


#endif
