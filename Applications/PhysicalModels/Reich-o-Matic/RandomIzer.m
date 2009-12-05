#import <MusicKit/MusicKit.h>
#import "RandomIzer.h"

@implementation RandomIzer: NSObject

static double ranNum(id self)
    /* Returns a random number between 0 and 1. */
{
#define   RANDOMMAX (double)((long)MAXINT)

    double newVal;
    newVal =  ((double)random()) / RANDOMMAX;
    
    return newVal;
}

static int ranInt(id self,int lowBound,int highBound)
/* Returns a random int between the specified bounds (inclusive) */
{
    return ( ranNum(self) * (highBound - lowBound) + lowBound + .5);
}

static int initRan(void)
    /* Initialize random numbers with a random seed based on the time of day */
{
#   import <sys/time.h>
#define STATESIZEINBYTES 256
    struct timeval tp;
    unsigned seed;
    gettimeofday(&tp,NULL);
    seed = tp.tv_usec;
    srandom(seed);

    return (seed);
}

-setit
  /* This method should be invoked after a new instance is created. */
{
    initRan(); /* Initialize random number sequence */

    return self;
}

-(double)GetNumber
{
	return(ranNum(self));
}

-(double)GetNumber:(double)scaler
{
	return((ranNum(self)) * scaler);
}

-(double)GetNumberRangeHi:(double)hi Lo:(double)lo
{
	return( (ranNum(self) * (hi-lo)) + lo );
}

-(double)GetPlusMinus
{
	return( (ranNum(self) * 2.0) - 1.0 );
}

-(double)GetPlusMinus:(double)scaler
{
	return( (ranNum(self) * (2.0 * scaler)) - (scaler/2.0) );
}

-(int)GetIndex:(int)scaler
{
	return(ranInt(self,0,scaler));
}

-(int)GetIndexRangeHi:(int)hi Lo:(int)lo
{
	return(ranInt(self,lo,hi));
}

@end


