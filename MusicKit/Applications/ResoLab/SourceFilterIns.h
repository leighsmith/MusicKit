#import <musickit/musickit.h>

/* Interface for SynthPatch SourceFilterIns. */
@interface SourceFilterIns:SynthPatch
{
    /* Amplitude parameters. */
	id		ampEnv;	/* the Envelope object for amplitude */
	double	amp1,	/* amplitude scaler */
			amp0,	/* amplitude offset */
			ampAtt,   /* ampEnv attack duration in seconds */
			ampRel;	/* ampEnv release duration in seconds */

    /* Frequency parameters. */ 	
	id	     freqEnv;	/* the Envelope object for frequency */
	double	freq1,	/* frequency scaler */
			freq0,	/* frequency offset */
			freqAtt,	/* freqEnv attack duration in seconds */
			freqRel;	/* freqEnv release duration in seconds */
    /* Amplitude parameters. */
	id		svibAmpEnv;	/* the Envelope object for amplitude */
	double	svibAmp1,	/* amplitude scaler */
			svibAmp0,	/* amplitude offset */
			svibAmpAtt,   /* ampEnv attack duration in seconds */
			svibAmpRel;	/* ampEnv release duration in seconds */

    /* Frequency parameters. */ 	
	id	     svibFreqEnv;	/* the Envelope object for frequency */
	double	svibFreq1,	/* frequency scaler */
			svibFreq0,	/* frequency offset */
			svibFreqAtt,	/* freqEnv attack duration in seconds */
			svibFreqRel;	/* freqEnv release duration in seconds */

    /* Other parameters. */
	double  sourceFader,		//  Cross fade between osc (0.0) and noise (1.0)
		noiseLevel,		//  Noise source level
		oscLevel,		//  Oscillator source level
		rvibAmp;		//  Gain of random vibrato component

	
	id	waveTable;
	int	waveTableLength;
	
	int     numHarmonics;
	
	double filt1pr,filt1zr,filt1pf,filt1zf,			//  radius and freq. of poles
		filt2pr,filt2zr,filt2pf,filt2zf,		//  and zeroes of the the 
		filt3pr,filt3zr,filt3pf,filt3zf,		//  three filters
		filt1Gain,filt2Gain,filt3Gain;
		
	double	portamento; 				/* transition time in seconds */
	double    bearing;	 			 /* stereo location  */
}


+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- (double)noteOffSelf:aNote;
- noteEndSelf;
- preemptFor:aNote;
- initialize;

@end
