/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    Add2UG  - from dsp macro /usr/lib/dsp/ugsrc/add2.asm (see source for details).
    Outputs the sum of two input signals. 

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/* 
	How Envelopes Are Used in the Music Kit SynthPatch Library 

In the Music Kit SynthPatch library, envelopes are specified in the
parameter list as some combination of an MKEnvelope object (a list of
time, value, and optional smoothing values), up to two value-modifying
numbers, and up to two time-scaling numbers.  See
<MKUnitGenerators/AsympUG.h> for details about the smoothing values in
an MKEnvelope.  The parameter names all begin with something descriptive
of their use, such as "amp" or "freq".  The MKEnvelope parameter has the
suffix "Env", e.g., "freqEnv".  The value-modifying parameters have
the suffixes "0" and "1", e.g., "freq0" and "freq1". The time-scaling
parameters have the suffixes "Att" and "Rel", e.g., "freqAtt" and
"freqRel".  In addition, just the descriptive part of the name may be
substituted for the "1"-suffix parameter, e.g. "freq" = "freq1".

	The MKEnvelope and Value-modifying Parameters

The synthpatches have been designed to allow several alternative ways
to use Envelopes, depending on the precise combination of these three
parameters. In the following paragraphs, the term "val0" stands for
any "0"-suffix numeric parameter, "val1" stands for any "1"-suffix
numeric parameter, "valAtt" stands for any "Att"-suffix parameter, and
"valRel" stands for any "Rel"-suffix parameter.

If no MKEnvelope is supplied, the desired value is specified in the
"val" field, (e.g. "freq") and the result is this value applied as a
constant. If an MKEnvelope is supplied but no "val0" or "val1" numbers
(e.g. "freqEnv" is supplied, but no "freq0" nor "freq1"), the MKEnvelope
values are used directly.  If only an MKEnvelope and "val0" are supplied,
the Envelope's y values are used after being added to "val0".  If only
an MKEnvelope and "val1" are supplied, the Envelope's y values are used
after being multipled by "val1".  If an MKEnvelope and both "val0" and "val1"
are supplied, the values used are "val0" plus the difference of "val1" and
"val0" multiplied by the MKEnvelope values.  In other words, the MKEnvelope
specifies the interpolation between the two numeric values.  "Val0"
specifies the value when the MKEnvelope is 0, and "val1" specifies the
value when the MKEnvelope is 1.

In mathematical terms, the formula for an MKEnvelope parameter val is then:
      
    DSP Value(t) = val0 + (val1 - val0) * valEnv(t)
       
where "val0" defaults to 0, "val1" defaults to 1, and "valEnv" defaults to a
constant value of 1 when only "val1" is supplied, and 0 otherwise.

	The MKEnvelope and Time-scaling Parameters

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
  With the current (2.0) implementation of the FM family of MKSynthPatches, the
  amount of modulation (peak frequency deviation) is computed from freq1.
  That means that if you use the convention of putting the frequencies in the
  envelope itself and setting freq1 to 1, the index values will have to be 
  boosted by the fundamental frequency. 
*/
// classgroup Envelope Handlers and Followers
/*!
  @class AsympUG
  @abstract <b>AsympUG</b> handles an MKEnvelope, passing it to the DSP one segment at a time
            and implementing asymptotic envelope segments.
  @discussion

AsympUG is an exponential (asymptotic) MKEnvelope handler that plays a MusicKit
MKEnvelope on the DSP. It is very similar to AsympenvUG and has almost the same
Objective C protocol. However, unlike AsympenvUG, which loads the entire
MKEnvelope into DSP memory, AsympUG feeds the MKEnvelope to the DSP one segment at a
time. This means AsympUG is more well-suited to very long Envelopes that would
not fit in DSP memory. For example, an entire piece may be specified as one long
MKEnvelope. AsympUG also uses less DSP code than AsympenvUG. However, AsympUG is
not well-suited to handling Envelopes in interactive real-time applications,
such as playing a MIDI keyboard and hearing sound immediately. For such
applications, it is better to use AsympenvUG. 

AsympUG objects are normally used to provide dynamic scaling of a musical
attribute.  To this end, the output of an AsympUG is typically connected to the
frequency or amplitude input of an OscgafiUG object or used as input to an
InterpUG, Mul2UG, ScaleUG, etc. Although typically used to convey Envelopes,
AsympUG may also be used as a simple exponential ramper, without an explicit
MKEnvelope object. Methods are provided that let you set the rate directly, or as
a time limit (referred to as  &ldquo;T60&rdquo;) that defines when the target will
have been perceptually reached.  

For each MKEnvelope segment, AsympUG creates an exponential signal that approaches
a limit (the &ldquo;target&rdquo;) at a particular rate, where the rate expresses
the precentage of the remaining journey that's taken with each
step:
	
<i>output</i> = <i>previousOutput</i> + (<i>rate</i> * (<i>target - 
previousOutput</i>))	
<i>previousOutput</i> = <i>output</i>

For example, if the rate is 0.1 and the target is 1.0, the samples generated by
the AsympUG are
	
0.1, 0.19, 0.271, 0.343, 0.409, 0.4685, ...

Exponential envelopes have the advantage of being "self-limiting". That is, 
they seek their targets from any starting point. This allows for efficient
implementation of long connected MKEnvelope "phrases", one of the primary
advantages of the Music Kit's Note representation. In addition, if, for some
reason, the host processor gets a little bit behind, due to time-sharing, the
envelope will not continue unbounded toward disaster. 
 
MKEnvelope data is mapped onto the exponential representation as
follows:

The Envelope's yArray[n] is the target, considered to be in the infinite
future.The Envelope's xArray[n] is the time of the right-hand side of the
segment (i.e. the time to interrupt the trajectory toward yArray[n]). The
Envelope's smoothingArra[n] is the smoothing constant to get to yArray[n]. If
smoothingArra[n] is 0, the point  is reached immediately. If smoothingArra[n] is
1.0, the point is reached,  within about -48dB at the time of the next update.
If smoothingArra[n] is larger, the point is not reached within -48dB by the time
of the next update. A value of smoothingArra[n] of infinity will cause the
envelope to never change value. The first point, xArray[0], is assumed to be the
right-hand side of the non-existant first segment. yArray[0] is the initial
point (which may or may not be used, depending on the value of the instance
variable useInitialvalue (see below)). smoothingArra[0] is ignored. 

The envelope has a "stick point". When the envelope handler reaches the stick
point, it does not proceed to the next point until it receives the
<b>-finish</b> message. If there is no stick point, the <b>-finish</b> message
is ignored. If the envelope handler has not yet reached the stick point when the
<b>-finish</b> message is received, the envelope handler proceeds to the first
point after the stick point and continues from there.  Keep in mind that while
AsympUG uses the clockConductor (see Conductor Class Description) for timing of
envelope breakpoint values, <b>-finish</b> is sent based on the arrival of a
<b>noteOff</b> to the SynthPatch, which is (usually) managed by another
Conductor.

Music Kit Envelopes are usually associated with a set of parameters, such as
attackTime, releaseTime, etc. The C function <b>MKUpdateAsymp()</b> is provided
to conveniently manage setting the AsympUG's attributes according to a given
MKEnvelope and a set of Note parameters.  By using <b>MKUpdateAsymp()</b>, you
need only set the AsympUG's output patchpoint; all other methods are invoked for
you.  For more information, see the Class Description for the MKEnvelope
class.

A few other points to keep in mind: 

&#180; You should not change the contents of a Music Kit MKEnvelope object while
an AsympUG is using it. 
&#180; The methods <b>-setYScale:yOffset: </b>and <b>-setReleaseXScale:</b> are
provided by AsympUG, but not by AsympenvUG. 
&#180; TransitionTime, which is specified in the method -<b>resetEnvelope:yScale:yOffset:xScale:releaseXScale:funcPtr:transitionTime:</b>, is supported by AsympUG, but not by AsympenvUG. 

<h2>Memory Spaces</h2>

<b>AsympUG<i>a</i></b><br>
<i>a</i>	output 
*/
#ifndef __MK_AsympUG_H___
#define __MK_AsympUG_H___

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

/*!
  @method (MKEnvStatus)envelopeStatus
  @result Returns an id.
  @discussion Returns the status of the most recently accessed MKEnvelope
              breakpoint. Note that the DSP may not yet have reached that point.
              For example, if the stickpoint's target was just set, envelopeStatus
              is MK_stickPoint, even though the DSP is just beginning its
              exponential approach to the stickpoint. The value returned by
              <b>envelopeStatus</b> is either MK_stickPoint, MK_lastPoint, or
              MK_noEnvError.  If the AsympUG's MKEnvelope hasn't been set,
              MK_noMorePoints is returned.
*/
-(MKEnvStatus)envelopeStatus;

/*!
  @method setOutput:
  @param  aPatchpoint is an id.
  @result Returns an id.
  @discussion Sets the output patchpoint to <i>aPatchpoint</i>.  Returns
              <b>self</b>, or <b>nil</b> if the argument isn't a
              patchpoint.
*/
-setOutput:aPatchPoint;

/*!
  @method setTargetVal:
  @param  (double)target is an id.
  @result Returns <b>self</b>.
  @discussion Sets the target to <i>target</i>, which should be between 0.0 and
              1.0.  The new target is simply inserted, overriding the current
              target.  If the object is already  processing an envelope, that
              envelope is not interrupted. 
*/
-setTargetVal:(double)aVal;

/*!
  @method setCurVal:
  @param  (double)value is an id.
  @result Returns <b>self</b>.
  @discussion Sets the current value of the AsympUG to <i>value</i>.  The new
              value overrides the previous  sample as shown in the computation in
              the class description above.  If the object is already  processing
              an envelope, that envelope is not interrupted.  
*/
-setCurVal:(double)aVal;

/*!
  @method setRate:
  @param  (double)rate is an id.
  @result Returns <b>self</b>.
  @discussion Sets the rate at which the AsympUG approaches its target, where
              <i>rate</i> is the percentage of the remaining journey that's
              stepped off at each sample.  The value of <i>rate</i>, which should
              be between 0.0 and 0.125.  (It should be between 0.0 and 1.0, but
              for historical reasons the outer limit stands at 0.125.  In any
              case, a rate of 0.125 means that the target is virtually reached in
              less than two ticks, which is quite fast).  More precisely, this
              method sets the rate of the exponential. (1-e^T/tau), where T is
              sampling period and tau is the time constant.If the AsympUG is
              already processing an MKEnvelope, the new rate is simply inserted,
              overriding the current value, and the MKEnvelope proceeds otherwise
              unaffected.  
              
              See also: <b>- setT60:</b>
*/
-setRate:(double)aVal;

/*!
  @method setT60:
  @param  (double)seconds is an id.
  @result Returns <b>self</b>.
  @discussion Computes the AsynpUG's rate such that the target is perceptually
              reached (to within -60dB of the target) in <i>seconds</i> seconds. 
              
              
              See also: <b>- setRate:</b>
*/
-setT60:(double)seconds;

/*!
  @method setT48:
  @param  (double)seconds is an id.
  @result Returns <b>self</b>.
  @discussion Computes the AsynpUG's rate such that the target is perceptually
              reached (to within -48dB of the target) in <i>seconds</i> seconds. 
              Same as <tt>[self setRate:5.52/(seconds*srate)].</tt>
              
              
              See also: <b>- setRate:</b>
*/
-setT48:(double)seconds;

/*!
  @method preemptEnvelope
  @result Returns an id.
  @discussion Causes the AsympUG to head for the last breakpoint in its MKEnvelope,
              using a rate that's computed from the value set through the
              <b>MKSetPreemptDuration()</b> function (the default preempt duration
              is 0.006 seconds).  This method is invoked automatically by a
              SynthInstrument object when it preempts a MKSynthPatch that contains
              AsympUG objects.
*/
-preemptEnvelope;

/*!
  @method setEnvelope:yScale:yOffset:xScale:releaseXScale:funcPtr:
  @param  anEnvelope is an id.
  @param  yScaleValue is a double.
  @param  yOffsetValue is a double.
  @param  xScaleValue is a double.
  @param  releaseXScaleValue is a double.
  @param  yScaleFunction is a pointer to a function returning a double (double(*)()).
  @result Returns an id.
  @discussion Associates the AsympUG with the given MKEnvelope and arguments.  When
              the AsympUG is run, it automatically schedules the breakpoints from
              its MKEnvelope to be fed to itself through message requests with the
              clockConductor.  If this method is invoked while the AsympUG is
              running, the object's current value is immediately set to the
              (scaled and offset) y value of the first breakpoint in the new
              MKEnvelope.   When continuity is desired with the previous invocation,
              use the <b>resetEnvelope:...</b> method instead.
                            
              The <i>yScaleValue</i> and <i>yOffsetValue</i>
              arguments scale and offset the AsympUG target values as each
              breakpoint is reached;  <i>xScaleValue</i> and <i>releaseXScaleValue</i>
              modify the rate before and after the Envelope's stickpoint
              is reached, respectively.  
              
              The <i>yScaleFunction</i> argument is a pointer to an
              optional function that performs additional, possibly dynamic, target
              scaling.  The fuction takes two arguments, a <b>double</b> that
              gives the AsympUG's current value, and the object's <b>id</b>.  The
              function is called once for each breakpoint.  
              
              Typically, you call the <b>MKUpdateAsymp()</b>
              function rather than invoking this method.  The function provides a
              slightly easier interface to AsympUG management in the context of a
              MKSynthPatch.  
*/
- setEnvelope:anEnvelope
       yScale:(double)yScaleValue
      yOffset:(double)yOffsetValue
       xScale:(double)xScaleValue
releaseXScale:(double)releaseXScaleValue
      funcPtr:(double(*)())yScaleFunction;
      
/*!
  @method resetEnvelope:yScale:yOffset:xScale:releaseXScale:funcPtr:transitionTime:
  @param  anEnvelope is an id.
  @param  yScaleValue is a double.
  @param  yOffsetValue is a double.
  @param  xScaleValue is a double.
  @param  releaseXScaleValue is a double.
  @param  yScaleFunction is a pointer to a function returning a double (double(*)()).
  @param  transitionTime is a double.
  @result Returns an id.
  @discussion This method is similar to the <b>setEnvelope:...</b> method but for
              this difference:  If the AsympUG is running, its current value isn't
              reset to the new Envelope's first y value; instead, the new
              Envelope's first breakpoint is ignored and the Asymp's rate is reset
              such that the second breakpoint of the new MKEnvelope is (virtually)
              reached within <i>transitionTime</i> seconds.  This affords are more
              graceful transition into the new MKEnvelope.  If <i>transitionTime</i> (as
              with any of the other double values) is MK_NODVAL, it is ignored. 
              As with the <b>setEnvelope:...</b> method, you typically call the
              <b>MKUpdateAsymp()</b> function rather than invoke this
              method.
*/
-resetEnvelope:anEnvelope
        yScale:(double)yScaleValue
       yOffset:(double)yOffsetValue
        xScale:(double)xScaleValue
 releaseXScale:(double)releaseXScaleValue
       funcPtr:(double(*)())yScaleFunction
transitionTime:(double)transitionTime;

/*!
  @method useInitialValue:
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion Controls how the MKEnvelope is handled when it is "retriggered" (i.e.
              <b>run</b> is invoked before the preceeding MKEnvelope has finished.)
              If <i>yesOrNo</i>, the first value of the MKEnvelope is set as the
              AsympUG's first output. Otherwise, the AsympUG continues from
              whatever its current value happens to be to the second point of the
              MKEnvelope. This method is rarely needed, since the same functionality
              is provided by <b>resetEnvelope:yScale:yOffset:xScale:releaseXScale:funcPtr:transitionTime:</b>. It is included as an optimization, when it is known that all parameters are the same.
*/
-useInitialValue:(BOOL)yesOrNo;

/*!
  @method setYScale:yOffset:
  @param  yScaleValue is a double.
  @param  yOffsetValue is a double.
  @result Returns an id.
  @discussion Resets the values by which the AsympUG scales and offsets its
              Envelope's y values.  If the object is running, its current value is
              appropriately modified.  Returns <b>nil</b> if the AsympUG has no
              MKEnvelope, otherwise returns <b>self</b>.
*/
-setYScale:(double)yScaleVal yOffset:(double)yOffsetVal;

/*!
  @method setReleaseXScale:
  @param  releaseXScaleValue is a double.
  @result Returns <b>self</b>.
  @discussion Resets the value by which the release time of the AsympUG's MKEnvelope
              is scaled.   This only has an affect on subsequent breakpoints - you
              can't, for example, extend the life of an AsympUG by increasing its
              release scale after the object has read (and is heading for) its
              last breakpoint.  
*/
-setReleaseXScale:(double)rXScaleVal ;

/*!
  @method envelope
  @result Returns an id.
  @discussion Returns the MKEnvelope that's associated with the AsympUG, or
              <b>nil</b> if none.
*/
-envelope;

/*!
  @method runSelf
  @result Returns <b>self</b>.
  @discussion You never send this message.  It's invoked by sending the <b>run</b>
              message to the object.  Starts the MKEnvelope, if any, on its way. 
              
*/
-runSelf;

-abortSelf;

/*!
  @method idleSelf
  @result Returns an id.
  @discussion You never send this message.  It's invoked by sending the
              <b>idle</b>message to the object.  
              Sets the output patchpoint to <i>sink</i>,<i></i> thus ensuring
              that the object does not produce any output.  Note that you must
              send <b>setOutput:</b> and <b>run</b> again to use the MKUnitGenerator
              after sending <b>idle</b>.
*/
-idleSelf;

/*!
  @method finishSelf
  @result Returns a double.
  @discussion You never invoke this method; it's invoked automatically when the
              AsympUG receives the <b>finish</b> message.  If the object has yet
              to see or is waiting at its Envelope's stickpoint, this causes it to
              head for the first breakpoint after the stickpoint, and then on the
              end of the MKEnvelope.  If the AsympUG's MKEnvelope contains no
              stickpoint, this method has no effect. Returns the time in seconds
              until the MKEnvelope is expected to finish, plus a small grace time
              given by <b>MKGetPreemptDuration()</b>. This time may be changed by
              calling  <b>MKSetPreemptDuration()</b>.
*/
-(double)finishSelf;

/*!
  @method shouldOptimize:
  @param arg is an unsigned.
  @result Returns an BOOL.
  @discussion Specifies that all arguments are to be optimized if possible except the
              state variable.
*/
+(BOOL)shouldOptimize:(unsigned) arg;

/*!
  @method abortEnvelope
  @result Returns <b>self</b>.
  @discussion Disassociates the AsympUG from its MKEnvelope.  If the AsympUG is
              running, it stops reading breakpoints. It continues heading for its
              current target.  
*/
-abortEnvelope;

/*!
  @method setConstant:
  @param  val is a double.
  @result Returns an id.
  @discussion Aborts any running MKEnvelope and sets the AsympUG to produce
              <i>val</i> as a constant value.  Equivalent to invoking
              <b>abortEnvelope</b>, followed by <b>setTarget:</b><i>val</i>,
              followed by <b>setCurVal:</b><i>val</i>.
*/
-setConstant:(double)aVal;

extern id MKAsympUGxClass(void);
extern id MKAsympUGyClass(void);
extern void
  MKUpdateAsymp(id asymp, id envelope, double val0, double val1,
		double attDur, double relDur, double portamentoTime,
		MKPhraseStatus status);

@end

#endif
