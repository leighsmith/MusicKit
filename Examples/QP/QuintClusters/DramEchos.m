#import <musickit/musickit.h>
#import <musickit/unitgenerators/unitgenerators.h>

#import "DramEchos.h"

/* 
 * We do our own allocation of DRAM.
 * The first 32 locations are reserved for DRAM versions of SINK and ZERO
 *
 * We split the DRAM in half for our two echo delays.
 */
#define DRAM_BASE_ADDR 32    
#define DRAM_PARTITION (0x15000+32)

/* Declare some unit generator variables for updating the DRAM */
static id scl1,scl2,delay1,delay2;

void allocateDramEchos(id qp,double initialEchoAmp)
{
    id in,add2,x1,x2,y1,y2,x3,y3,out;
    [UnitGenerator enableErrorChecking:YES];

    x1 = [qp allocPatchpoint:MK_xPatch];
    x2 = [qp allocPatchpoint:MK_xPatch];
    x3 = [qp allocPatchpoint:MK_xPatch];
    y1 = [qp allocPatchpoint:MK_yPatch];
    y2 = [qp allocPatchpoint:MK_yPatch];
    y3 = [qp allocPatchpoint:MK_yPatch];

#define ADDER_X(_i1,_i2,_o) \
    add2 = [qp allocUnitGenerator:[Add2UGxxx class]]; \
    [add2 setInput1:_i1]; \
    [add2 setInput2:_i2]; \
    [add2 setOutput:_o]; \
    [add2 run] 

#define IN_L(_dsp) \
    in = [qp allocUnitGenerator:[In1qpUGx class]]; \
    [in setChannel:0]; \
    [in setSatellite:_dsp]; \
    [in setScale:.5]; \
    [in setOutput:x1]; \
    [in run] 

    IN_L('A');

    add2 = [qp allocUnitGenerator:[Add2UGxxy class]]; 
    [add2 setInput1:x1];
    [add2 setInput2:y3];
    [add2 setOutput:x2];
    [add2 run]; 

    IN_L('B');
    ADDER_X(x1,x2,x2);
    IN_L('C');
    ADDER_X(x1,x2,x2);
    IN_L('D');
    ADDER_X(x1,x2,x2);

    out = [qp allocUnitGenerator:[Out1bUGx class]];
    [out setInput:x2];
    [out setScale:1.0];
    [out run];

    delay1 = [qp allocUnitGenerator:[DelayqpUGxx class]];
    [delay1 setInput:x2];
    [delay1 setOutput:x3];
    [delay1 setDelayAddress:DRAM_BASE_ADDR length:0x15000];
    [delay1 run];

    scl1 = [qp allocUnitGenerator:[ScaleUGxx class]];
    [scl1 setInput:x3];
    [scl1 setOutput:x3];
    [scl1 setScale:initialEchoAmp];
    [scl1 run];

#define ADDER_Y(_i1,_i2,_o) \
    add2 = [qp allocUnitGenerator:[Add2UGyyy class]]; \
    [add2 setInput1:_i1]; \
    [add2 setInput2:_i2]; \
    [add2 setOutput:_o]; \
    [add2 run] 

#define IN_R(_dsp) \
    in = [qp allocUnitGenerator:[In1qpUGy class]]; \
    [in setChannel:1]; \
    [in setSatellite:_dsp]; \
    [in setScale:.5]; \
    [in setOutput:y1]; \
    [in run]

    IN_R('A');

    add2 = [qp allocUnitGenerator:[Add2UGyyx class]]; 
    [add2 setInput1:y1];
    [add2 setInput2:x3];
    [add2 setOutput:y2];
    [add2 run];

    IN_R('B');
    ADDER_Y(y1,y2,y2);
    IN_R('C');
    ADDER_Y(y1,y2,y2);
    IN_R('D');
    ADDER_Y(y1,y2,y2);

    out = [qp allocUnitGenerator:[Out1aUGy class]];
    [out setInput:y2];
    [out setScale:1.0];
    [out run];

    delay2 = [qp allocUnitGenerator:[DelayqpUGyy class]];
    [delay2 setInput:y2];
    [delay2 setOutput:y3];
    [delay2 setDelayAddress:DRAM_PARTITION length:0x15000];
    [delay2 run];

    scl2 = [qp allocUnitGenerator:[ScaleUGyy class]];
    [scl2 setInput:y3];
    [scl2 setOutput:y3];
    [scl2 setScale:initialEchoAmp];
    [scl2 run];
}

void setDramEchoScale(double val)
{
    [scl1 setScale:val];
    [scl2 setScale:val];
}

void setDramEchoDelay(int delayLength)
{
    [delay1 setDelayAddress:DRAM_BASE_ADDR length:delayLength];
    [delay2 setDelayAddress:DRAM_PARTITION length:delayLength];
}
