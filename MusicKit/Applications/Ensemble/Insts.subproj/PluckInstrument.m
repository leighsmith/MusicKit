/* An SynthInstrument for handling Pluck synthpatches, and adjusting
 * their parameters via a graphic interface.
 */

#import "PluckInstrument.h"
#import "ParamInterface.h"
#import <appkit/appkit.h>
#import <musickit/synthpatches/Pluck.h>

@implementation PluckInstrument
{}

+ initialize
{
	[PluckInstrument setVersion:2];
	return self;
}

- loadNibFile
{
    [NXApp loadNibSection:"PluckInstrument.nib" owner:self withNames:NO];
	return self;
}

- setDefaults
{
	[super setDefaults];
	amp = 6.0;
	brightness = 0.3;
	sustain = 0.9;
	decay = 50.0;
	ampRel = 0.2;
    [updates setPar:MK_amp toDouble:MKdB(amp-18.0)];  /* -18 dB = "unity" */
    [updates setPar:MK_bright toDouble:brightness];
    [updates setPar:MK_sustain toDouble:sustain];
    [updates setPar:MK_decay toDouble:decay];
    [updates setPar:MK_ampRel toDouble:ampRel];

	return self;
}

- init
    /* Called automatically when an instance is created. */
{
    [super init];
    [self setSynthPatchClass:[Pluck class]]; 
    return self;
}

- awakeFromNib
    /* Things that have to be done AFTER the nib section is loaded in */
{
	[super awakeFromNib];
    [sustainField setDoubleValue:sustain];
    [sustainSlider setDoubleValue:sustain];
	[envInterface setDoubleValueAt:0 to:decay];
	[envInterface setDoubleValueAt:1 to:ampRel];
    [[sustainField cell] setFloatingPointFormat:NO left:2 right:2];

    return self;
}

- free
{
	[envInterface free];
	return self;
}

- takePSustainFrom:sender;
    /* Adjust the sustain parameter */
{
	sustain = [sender doubleValue];

	sustain = MAX(MIN(sustain,1.0),-1.0);
	[self updatePar:MK_sustain asDouble:sustain];
    [sustainField setDoubleValue:sustain];
    [document setEdited];

    return self;
}

- takeEnvParFrom:sender
    /* Adjust the decay parameter */
{
	switch ([sender selectedIndex]) {
		case 0:
			decay = [sender doubleValue];
			decay = MAX(MIN(decay,1.0),-1.0);
			[self updatePar:MK_decay asDouble:decay];
			break;
		case 1:
			ampRel = [sender doubleValue];
			ampRel = MAX(ampRel,0.0);
			[self updatePar:MK_ampRel asDouble:ampRel];
			break;
		default:
			break;
	}
    [document setEdited];

    return self;
}

- write:(NXTypedStream *) stream
    /* Archive the instrument to a typed stream. */
{
    [super write:stream];
    NXWriteTypes(stream, "ddd", &sustain, &decay, &ampRel);

    return self;
}

- read:(NXTypedStream *) stream
    /* Unarchive the instrument from a typed stream. */
{
	int version;
    [super read:stream];

	version = NXTypedStreamClassVersion(stream, "PluckInstrument");
	if (version < 2) {
		id decayField, ampRelField;
   		NXReadTypes(stream, "@@@@", &brightField,
		 	&sustainField, &decayField, &ampRelField);
		brightness 	= [brightField doubleValue];
		sustain = [sustainField doubleValue];
		decay 	= [decayField doubleValue];
		ampRel 	= [ampRelField doubleValue];
	}
	else if (version == 2)
    	NXReadTypes(stream, "ddd", &sustain, &decay, &ampRel);

    return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takeBrightFrom:sender {return self;}
- takeSustainFrom:sender {return self;}
- takeDecayFrom:sender {return self;}
- takeAmpRelFrom:sender {return self;}

@end
