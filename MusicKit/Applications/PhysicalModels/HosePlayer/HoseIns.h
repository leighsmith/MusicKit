#import <musickit/SynthPatch.h>

@interface HoseIns:SynthPatch
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
	double    lipCoefficient1;	  /* lip filter coefficient */
	double    lipCoefficient2;	  /* lip filter coefficient */
	double    lipFiltGain;	  /* lip filter gain */
	double    outAmp;	  /* outputAmplitude */
	id delayMemory;
}


+ (void)patchTemplateFor:aNote;
- (void)noteOnSelf:aNote;
- (void)noteUpdateSelf:aNote;
- (double)noteOffSelf:aNote;
- (void)noteEndSelf;
- (void)preemptFor:aNote;
- init;

@end
