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

/* converted almost all doubles to floats 8/22/92 */

#import <appkit/appkit.h>
#import "musickit/musickit.h"
#import "WmFractal.h"
#import "LineGraph.h"
#import "EnsembleApp.h"
#import "ParamInterface.h"

// extern double pow();

// extern long random();
// extern void srandom();

#define MAXRAN 2147483647.0
#define DRANDOM ((double)random()/MAXRAN)

@implementation WmFractal
{
}

+ initialize
 /*
  * Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[WmFractal setVersion:5];
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"WmFractal.nib" owner:self];
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	int i;
	[super init];
	firstTerm = 0;
	numTerms = 6;
	r = 0.618;
	h = 0.8;
	timeScale = 8.0;
	ampRanSeed = random() >> 8;
	phaseRanSeed = random() >> 8;
	for (i = 0; i < MAXTERMS; i++) {
		ampRanVals[i] = 0.0;
		phaseRanVals[i] = 0.0;
	}
	[self loadNibFile];
	return self;
}

- awakeFromNib
{
	[ampRanSeedField setIntValue:ampRanSeed];
	[phaseRanSeedField setIntValue:phaseRanSeed];

	[paramInterface setModeAt:2 to:DOUBLES];
	[paramInterface setModeAt:3 to:DOUBLES];
	[paramInterface setIntValueAt:0 to:firstTerm];
	[paramInterface setIntValueAt:1 to:numTerms];
	[paramInterface setDoubleValueAt:2 to:2.0 - h];
	[paramInterface setDoubleValueAt:3 to:r];
	[paramInterface setIntValueAt:4 to:timeScale];
	[paramInterface setIntValueAt:5 to:timeOffset];

	[lineGraph setLineGray:NX_WHITE];
	[lineGraph setBackgroundGray:NX_BLACK];
	[self initAmpRanVals];
	[self initPhaseRanVals];
	[self initializeFractal];
	[self graphFractal];
	return self;
}


- copyFromZone:(NXZone *)aZone
{
	WmFractal *new = [[WmFractal allocFromZone:aZone] init];
	new->firstTerm = firstTerm;
	new->numTerms = numTerms;
	new->r = r;
	new->h = h;
	new->timeScale = timeScale;
	new->ampRanSeed = ampRanSeed;
	new->phaseRanSeed = phaseRanSeed;
	return [new awakeFromNib];
}
	
- inspectorPanel
{
	return inspectorPanel;
}

- show:sender;
{
	return [inspectorPanel makeKeyAndOrderFront:self];
	return self;
}

- setTimeScale:(float)scale
{
	timeScale = MAX((float)scale, 1.0);
	[paramInterface setDoubleValueAt:4 to:timeScale];
	[self graphFractal];
	return self;
}

- takeAmpRanSeedFrom:sender
{
	ampRanSeed = [sender intValue];
	if (ampRanSeedField && (sender != ampRanSeedField))
		[ampRanSeedField setIntValue:ampRanSeed];
	[self initAmpRanVals];
	[self initializeFractal];
	[self graphFractal];
	if ([delegate respondsTo:@selector(fractalChanged:)])
		[delegate fractalChanged:self];

	return self;
}

- newAmpRanSeed:sender
{
	ampRanSeed = random() >> 8;	/* makes the numbers less verbose. */
	[ampRanSeedField setIntValue:ampRanSeed];
	[self initAmpRanVals];
	[self initializeFractal];
	[self graphFractal];
	if ([delegate respondsTo:@selector(fractalChanged:)])
		[delegate fractalChanged:self];

	return self;
}

- initAmpRanVals
{
	int     i;

	srandom(ampRanSeed);
	for (i = 0; i < numTerms; i++)
		ampRanVals[i] = DRANDOM;

	return self;
}

- takeParamFrom:sender
{
	switch ([sender selectedIndex]) {
		case 0:
			firstTerm = [sender intValue];
			[self initializeFractal];
			break;
		case 1:
			numTerms = [sender intValue];
			[self initializeFractal];
			break;
		case 2:
			h = 2.0 - (float)[sender doubleValue];
			[self initializeFractal];
			break;
		case 3:
			r = (float)[sender doubleValue];
			[self initializeFractal];
			break;
		case 4:
			timeScale = (float)[sender intValue];
			break;
		case 5:
			timeOffset = (float)[sender intValue];
			break;
	}
	[self graphFractal];
	if ([delegate respondsTo:@selector(fractalChanged:)])
		[delegate fractalChanged:self];
	return self;
}

- setNumTerms:(int)nTerms
{
	numTerms = MAX(MIN(nTerms, 32), 0);
	[paramInterface setIntValueAt:1 to:numTerms];
	[self initializeFractal];
	[self graphFractal];
	return self;
}

- takePhaseRanSeedFrom:sender
{
	phaseRanSeed = [sender intValue];
	if (phaseRanSeedField && (sender != phaseRanSeedField))
		[phaseRanSeedField setIntValue:phaseRanSeed];
	[self initPhaseRanVals];
	[self initializeFractal];
	[self graphFractal];
	if ([delegate respondsTo:@selector(fractalChanged:)])
		[delegate fractalChanged:self];

	return self;
}

- newPhaseRanSeed:sender
{
	phaseRanSeed = random() >> 8;
	[phaseRanSeedField setIntValue:phaseRanSeed];
	[self initPhaseRanVals];
	[self initializeFractal];
	[self graphFractal];
	if ([delegate respondsTo:@selector(fractalChanged:)])
		[delegate fractalChanged:self];

	return self;
}

- initPhaseRanVals
{
	int     i;

	srandom(phaseRanSeed);
	for (i = 0; i < numTerms; i++)
		phaseRanVals[i] = DRANDOM;

	return self;
}

- (float)fractalValue:(float)time
{
	register float val = 0, *a = amps, *m = mag, *p = phases, *end = amps + numTerms;
	while (a < end)
		val += (*a++) * (sin(time * (*m++) + (*p++)) + 1.0);
	return val;
}

- initializeFractal
{
	register int i;
	register float val, t = 0, minVal = 1000, maxVal =- 1000;

	if (ampRanVals[0] == 0.0)
		[self initAmpRanVals];
	if (phaseRanVals[0] == 0.0)
		[self initPhaseRanVals];
	/*
	 * Compute the amp and frequency terms. The "*0.5" is an optimization which
	 * replaces the divide by 2 when normalizing the sine values to be between
	 * 0 and 1 in -fractalValue. 
	 */
	for (i = 0; i < numTerms; i++) {
		amps[i] = (float)(ampRanVals[i] * pow(r, (firstTerm + i) * h) * 0.5);
		phases[i] = (float)(phaseRanVals[i] * 2 * M_PI);
		mag[i] = (float)(pow(r, -(firstTerm + i)) * 2 * M_PI);
	}
	for (i = 0; i < 128; i++) {	/* Sample first 8 beats to get max and min */
		val = [self fractalValue:t];
		if (val > maxVal)
			maxVal = val;
		if (val < minVal)
			minVal = val;
		t +=.0625;
	}
	valScale = 1.0 / (maxVal - minVal);
	valOffset = minVal;

	return self;
}

- graphFractal
 /* Graph the first 8 beats of the fractal function */
{
	register int i;
	register float t = 0.0;
	float   x[65], y[65];

	for (i = 0; i < 65; i++) {
		x[i] = t;
		y[i] = [self generate:t];
		t +=.125;
	}
	[lineGraph setPoints:65 x:x y:y minX:0.0 minY:0.0 maxX:8.0 maxY:1.0];
	[lineGraph scaleToFit];
	[lineGraph display];
	return self;
}


- (float)generate:(float)time
{
	/* return value normalized to fall between 0 and 1 */
	currentValue =
		([self fractalValue:(time + timeOffset) / timeScale] - valOffset) * valScale;
	return (currentValue < 0.0) ? 0.0 : (currentValue > 1.0) ? 1.0 : currentValue;
}

- (float)currentValue
 /* Return last computed value */
{
	return currentValue;
}


- write:(NXTypedStream *) stream
 /* Archive the object to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "iiiiffff@",
				 &ampRanSeed, &phaseRanSeed, &firstTerm, &numTerms,
				 &r, &h, &timeScale, &timeOffset, &delegate);
 	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the object from a typed stream. */
{
	int     version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "WmFractal");
	if (version < 5) {
		id dummy;
		if (version <= 1) {
			double dr, dh, dtimeScale, dtimeOffset;
			NXReadTypes(stream, "@iiiidddd", &inspectorPanel,
						&ampRanSeed, &phaseRanSeed, &firstTerm, &numTerms,
						&dr, &dh, &dtimeScale, &dtimeOffset);
			ampRanSeedField = NXReadObject(stream);
			phaseRanSeedField = NXReadObject(stream);
			dummy = NXReadObject(stream);
			dummy = NXReadObject(stream);
			dummy = NXReadObject(stream);
			dummy = NXReadObject(stream);
			dummy = NXReadObject(stream);
			dummy = NXReadObject(stream);
			r = dr; h = dh; timeScale = dtimeScale; timeOffset = dtimeOffset;
		} else if (version <= 2) {
			double dr, dh, dtimeScale, dtimeOffset;
			NXReadTypes(stream, "@iiiidddd@@@@@@@@@", &inspectorPanel,
						&ampRanSeed, &phaseRanSeed, &firstTerm, &numTerms,
						&dr, &dh, &dtimeScale, &dtimeOffset,
						&ampRanSeedField, &phaseRanSeedField, &dummy,
						&dummy, &dummy, &dummy, &dummy, &dummy, &lineGraph);
			r = dr; h = dh; timeScale = dtimeScale; timeOffset = dtimeOffset;
		}
		else
			NXReadTypes(stream, "@iiiiffff@@@@@@@@@", &inspectorPanel,
						&ampRanSeed, &phaseRanSeed, &firstTerm, &numTerms,
						&r, &h, &timeScale, &timeOffset,
						&ampRanSeedField, &phaseRanSeedField, &dummy,
						&dummy, &dummy, &dummy, &dummy, &dummy, &dummy);
	
		if (version>3)
			NXReadTypes(stream, "@", &delegate);
	}
	else if (version == 5)
		NXReadTypes(stream, "iiiiffff@",
				 &ampRanSeed, &phaseRanSeed, &firstTerm, &numTerms,
				 &r, &h, &timeScale, &timeOffset, &delegate);
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];
	if (newRanVals) {
		ampRanSeed = random() >> 8;
		phaseRanSeed = random() >> 8;
	}
	[self loadNibFile];
	return self;
}

- setDelegate:anObject
{
	delegate = anObject;
	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- setAmpRanSeed:sender {return self;}
- setFirstTerm:sender {return self;}
- setDimension:sender {return self;}
- setPhaseRanSeed:sender {return self;}
- setR:sender {return self;}
- setTimeOffset:sender {return self;}

@end
