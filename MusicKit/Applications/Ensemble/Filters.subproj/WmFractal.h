#ifndef __MK_WmFractal_H___
#define __MK_WmFractal_H___
#import <objc/Object.h>

#define MAXTERMS 32

@interface WmFractal : Object
    /* Implements a Weierstrass-Mandelbrot random fractal function.
     * Source: "Random Fractal Forgeries" - Richard Voss, IBM Thomas
     * J. Watson Research Center.  Published in Fractals class notes at
     * the 1985 SIGGRAPH Conference, or "Fractals in Nature", published
     * in the Fractals class notes at the 1987 SIGGRAPH.
     * 
     * This function is convenient because it is continuous and unlimited,
     * rather than discrete and bounded like a midpoint-displacement
     * style of fractal.  Careful adjustment of its parameters can
     * produce a wide variety of natural-sounding and interesting melodic
     * shapes.
     */
{
    int ampRanSeed;
    int phaseRanSeed;
    int firstTerm;
    int numTerms;
    float h;
    float r;
    float timeScale;
    float timeOffset;
    float valScale;
    float valOffset;
    float currentValue;
    
    float amps[MAXTERMS];
    float phases[MAXTERMS];
    float mag[MAXTERMS];
    float ampRanVals[MAXTERMS];
    float phaseRanVals[MAXTERMS];
    
    id inspectorPanel;
	id paramInterface;
    id ampRanSeedField;
    id phaseRanSeedField;

    id lineGraph;

    id delegate;
}

- init;
- takeAmpRanSeedFrom:sender;
- takePhaseRanSeedFrom:sender;
- takeParamFrom:sender;
- newAmpRanSeed:sender;
- newPhaseRanSeed:sender;
- setNumTerms:(int)nTerms;
- setTimeScale:(float)scale;
- initPhaseRanVals;
- initAmpRanVals;
- initializeFractal;
- graphFractal;
- (float)generate:(float)time;
- (float)currentValue;
- show:sender;
- setDelegate:anObject;

@end

/*
 * Delegate interface.
 */
@interface WmFractalDelegate:Object
- fractalChanged:sender;
@end




#endif
