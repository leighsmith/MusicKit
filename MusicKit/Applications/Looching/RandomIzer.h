#import <musickit/musickit.h>

@interface RandomIzer:Object
{
    char *ranState;
}

-setit;
-(double)GetNumber;
-(double)GetNumber:(double)scaler;
-(double)GetNumberRangeHi:(double)hi Lo:(double)lo;
-(double)GetPlusMinus;
-(double)GetPlusMinus:(double)scaler;
-(int)GetIndex:(int)scaler;
-(int)GetIndexRangeHi:(int)hi Lo:(int)lo;
@end
