/* 
 * By David A. Jaffe
 * Copyright Stanford University, 1996, All rights reserved
 * AsympenvUG.h 
 *
 * This class is part of the Music Kit UnitGenerator Library.
 */

#import <MusicKit/MusicKit.h>

@interface AsympenvUG : MKUnitGenerator
{
    id anEnv;
    double (*scalingFunc)(); 
    double timeScale;            
    double releaseTimeScale;      
    double yScale;                
    double yOffset;               
    double targetX;               
    char useInitialValue;         
    int stickPoint; 
    DSPDatum firstVal;
    double releaseTime;
    double envTriggerTime;
    MKSynthData *durMem,*targetMem,*rateMem; 
    double _transitionTime;
    double _samplingRate;
    double _smoothConstant;
    int _tickRate;
}

+(void)envelopeHasChanged:(MKEnvelope *)env;  
+(void)freeKeyObjects; 
-setOutput:aPatchPoint;
-setTargetVal:(double)aVal;
-setCurVal:(double)aVal;
-setRate:(double)aVal;
-setT60:(double)seconds;
-preemptEnvelope;
-setEnvelope:anEnvelope yScale:(double)yScale yOffset:(double)yOffset
 xScale:(double)xScale releaseXScale:(double)rXScale
 funcPtr:(double(*)())func ;
-resetEnvelope:anEnvelope yScale:(double)yScaleVal yOffset:(double)yOffsetVal
    xScale:(double)xScaleVal releaseXScale:(double)rXScaleVal
    funcPtr:(double(*)())func  transitionTime:(double)transTime;
-useInitialValue:(BOOL)yesOrNo;
-setYScale:(double)yScaleVal yOffset:(double)yOffsetVal;
-setReleaseXScale:(double)rXScaleVal ;
-envelope;
-runSelf;
-abortSelf;
-idleSelf;
-(double)finishSelf;
+(BOOL)shouldOptimize:(unsigned) arg;
-abortEnvelope;
-setConstant:(double)aVal;

extern id MKAsympUGxClass(void);
extern id MKAsympUGyClass(void);
extern void
  MKUpdateAsymp(id asymp, id envelope, double val0, double val1,
		double attDur, double relDur, double portamentoTime,
		MKPhraseStatus status);

@end

