#ifndef __MK_AsympUG_H___
#define __MK_AsympUG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	AsympUG.h 

	This class is part of the Music Kit UnitGenerator Library.
*/
#import <MusicKit/MusicKit.h>

@interface AsympUG:MKUnitGenerator
{
    id anEnv;
    double (*scalingFunc)();
    int envelopeStatus;           
    int arrivalStatus;            
    double timeScale;             
    double releaseTimeScale;      
    double yScale;                
    double yOffset;               
    double targetX;               
    char useInitialValue;         
    int curPt;                    
    double _reservedAsymp1;
    MKMsgStruct * _reservedAsymp2;
    double _reservedAsymp3;
    double _reservedAsymp4;
    double _reservedAsymp5;
    double _reservedAsymp6;
    double _reservedAsymp7;
    DSPDatum _reservedAsymp8;
}

-(MKEnvStatus)envelopeStatus;
-setOutput:aPatchPoint;
-setTargetVal:(double)aVal;
-setCurVal:(double)aVal;
-setRate:(double)aVal;
-setT60:(double)seconds;
-setT48:(double)seconds;
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

/* 
	How Envelopes Are Used in the Music Kit SynthPatch Library 

In the Music Kit SynthPatch library, envelopes are specified in the
parameter list as some combination of an Envelope object (a list of
time, value, and optional smoothing values), up to two value-modifying
numbers, and up to two time-scaling numbers.  See
<unitgenerators/AsympUG.h> for details about the smoothing values in
an Envelope.  The parameter names all begin with something descriptive
of their use, such as "amp" or "freq".  The Envelope parameter has the
suffix "Env", e.g., "freqEnv".  The value-modifying parameters have
the suffixes "0" and "1", e.g., "freq0" and "freq1". The time-scaling
parameters have the suffixes "Att" and "Rel", e.g., "freqAtt" and
"freqRel".  In addition, just the descriptive part of the name may be
substituted for the "1"-suffix parameter, e.g. "freq" = "freq1".

	The Envelope and Value-modifying Parameters

The synthpatches have been designed to allow several alternative ways
to use Envelopes, depending on the precise combination of these three
parameters. In the following paragraphs, the term "val0" stands for
any "0"-suffix numeric parameter, "val1" stands for any "1"-suffix
numeric parameter, "valAtt" stands for any "Att"-suffix parameter, and
"valRel" stands for any "Rel"-suffix parameter.

If no Envelope is supplied, the desired value is specified in the
"val" field, (e.g. "freq") and the result is this value applied as a
constant. If an Envelope is supplied but no "val0" or "val1" numbers
(e.g. "freqEnv" is supplied, but no "freq0" nor "freq1"), the Envelope
values are used directly.  If only an Envelope and "val0" are supplied,
the Envelope's y values are used after being added to "val0".  If only
an Envelope and "val1" are supplied, the Envelope's y values are used
after being multipled by "val1".  If an Envelope and both "val0" and "val1"
are supplied, the values used are "val0" plus the difference of "val1" and
"val0" multiplied by the Envelope values.  In other words, the Envelope
specifies the interpolation between the two numeric values.  "Val0"
specifies the value when the Envelope is 0, and "val1" specifies the
value when the Envelope is 1.

In mathematical terms, the formula for an Envelope parameter val is then:
      
    DSP Value(t) = val0 + (val1 - val0) * valEnv(t)
       
where "val0" defaults to 0, "val1" defaults to 1, and "valEnv" defaults to a
constant value of 1 when only "val1" is supplied, and 0 otherwise.

	The Envelope and Time-scaling Parameters

The "valAtt" and "valDec" numeric parameters directly affect the
"attack" and "decay" portions of an envelope, which are considered to
be the portions before and after the stickpoint, respectively.  When
supplied, the relevant portion of the envelope is scaled so that the
total time of that portion is the time specified in the parameter in
seconds.  For example, if valAtt is set to .5, the segments of the
portion of the envelope before the stick point will be proportionally
scaled so that the total time is .5 seconds.  The smoothing values are
also scaled proportionally so that the behavior of time-scaled
envelopes remains consistent.

ValAtt can only be set when an envelope is also supplied in the same note.
However, valDec may be set independently, e.g., in a noteOff where an
envelope was supplied in the preceeding noteOn.

	Phrases 

The Music Kit supports continuity between notes in a phrase.  When two
notes are part of the same phrase (they have the same time tag) or a
sounding note is updated by a noteUpdate, the envelope of the latter
note does not simply interrupt that of the earlier note.  Rather, the
first point of the latter envelope is ignored, and the envelope
proceeds directly to the second point, starting from wherever the
earlier envelope happens to be when the new noteOn occurs.  The time
it takes to do this is, by default, the time of the first segment of
the latter envelope, possibly affected by its "valAtt" parameter.
However, the "portamento" parameter may be used to specify the time
(in seconds) for the transition should take.  All of the x (time)
values of the envelope, except the first, are increased by the amount
needed to make the first segment take the desired amount of time. In
addition, the smoothing value for the first segment is adjusted
appropriately. 

The single "portamento" parameter affects all envelopes which the synthpatch
may be using.

MKUpdateAsymp() may be called with any of its arguments of type double 
"unset". "unset" is indicated by the value MAXDOUBLE. 

Caveat concerning FM:
  With the current (2.0) implementation of the FM family of SynthPatches, the
  amount of modulation (peak frequency deviation) is computed from freq1.
  That means that if you use the convention of putting the frequencies in the
  envelope itself and setting freq1 to 1, the index values will have to be 
  boosted by the fundamental frequency. 
*/

#endif
