#import <musickit/SynthPatch.h>

@interface FluteIns:SynthPatch
{
    /* Amplitude parameters. */
    id		ampEnv;	/* the Envelope object for amplitude */
    double	amp1,	/* amplitude scaler */
			amp0,	/* amplitude offset */
			ampAtt,   /* ampEnv attack duration in seconds */
			ampRel;	/* ampEnv release duration in seconds */
/* Other parameters. */
	double	portamento; /* transition time in seconds */
	double    bearing;	  /* stereo location */
	double    dLineLength;	  /* delay line length */
	double    outAmp;	  /* outputAmplitude */
	double delay2Length,noiseVolume;   /* embouchure delay and relative noise volume */
	id delayMemory,delayMemory2;
}


+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- (double)noteOffSelf:aNote;
- noteEndSelf;
- preemptFor:aNote;
- init;

@end
