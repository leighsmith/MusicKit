#import <musickit/musickit.h>
#import <musickit/Performer.h>


@interface LoochPerformer:Performer
{
    id LoochNote;
}

-initialize;
-setDefaults;
-startNote;
-stopNote;
-changeNote;
-pause;
-setfreq:(double)hz spread:(double)window;
-setamp:(double)amplitude;
-setbearing:(double)bearing;
-setwave:(id)thePartials;
-setattack:(double)attack;
-setdecay:(double)decay;
-setvibfreq0:(double)vfreq;
-setvibfreq1:(double)vfreq;
-setvibamp0:(double)vamp;
-setvibamp1:(double)vamp;
@end
