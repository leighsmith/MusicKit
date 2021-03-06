/* This class was auto-generated by dspwrap from macro biquad. 
   It should not be edited. */

#import "BiquadUGx.h"

@implementation BiquadUGx : BiquadUG

/* times in seconds/sample */
#define COMPUTETIME (448 * (DSP_CLOCK_PERIOD / DSPMK_I_NTICK))
#define OFFCHIP_COMPUTETIME (678 * (DSP_CLOCK_PERIOD / DSPMK_I_NTICK))

static MKLeafUGStruct _leafUGStruct = {
    {4/* xArg  */,  5/* yArg  */,  0/* lArg */,
     20/* pLoop */,  0/* pSubr */,
     0/* xData */,  0/* yData */} /* memory requirements */, COMPUTETIME};

+(MKLeafUGStruct *)classInfo  
{   if (_leafUGStruct.master == NULL)
      _leafUGStruct.master = [self masterUGPtr];
    return &_leafUGStruct; }

+ (void)initialize /* Sent once on factory start-up. */
{
enum args { ainp, aout, s1, s2, bqa1, bqa2, bqb1, bqb2, go2 };
   static DSPMemorySpace _argSpaces[] = {DSP_MS_Y,DSP_MS_N,DSP_MS_N,DSP_MS_N,DSP_MS_N,DSP_MS_N,DSP_MS_N,DSP_MS_N,DSP_MS_N};
   static DSPDataRecord _dataRecP = {NULL, DSP_LC_P, 0, 1, 20}; 
   static int _dataP[] = {0x66d800,0x61d800,0x4fdc00,0x229500,0x8f8,
                          0x61080,0x8e,0x44d913,0xf098c0,0xf490d6,
                          0xf418e6,0xf818d2,0x44d0e2,0x22b411,0xb2d000,
                          0x45810,0x3c0400,0x45810,0x44c14,0xf7b8};
   static DSPFixup _fixupsP[] = {
   {DSP_LC_P, NULL, 1 /* decrement */, 6 /* refOffset */,  14 /* relAddress */}
   };
   _leafUGStruct.master = NULL;
   _leafUGStruct.argSpaces = _argSpaces;
   _leafUGStruct.data[(int)DSP_LC_P] = &_dataRecP;
   _dataRecP.data = _dataP;
   _leafUGStruct.fixups[(int)DSP_LC_P - (int)DSP_LC_P_BASE] = _fixupsP;
   MKInitUnitGeneratorClass(&_leafUGStruct);
   _leafUGStruct.reserved1 = MK_2COMPUTETIMES;
   _leafUGStruct.offChipComputeTime = OFFCHIP_COMPUTETIME;
   return;
}
@end
