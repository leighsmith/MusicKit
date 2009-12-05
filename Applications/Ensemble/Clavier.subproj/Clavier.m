/* Clavier is a Performer-like object that displays three graphic piano octaves
 * with keys that can be clicked on, pitchbend and modwheel sliders,
 * a sustain button, and program change buttons.
 */

#import <MusicKit/MusicKit.h>
#import <AppKit/AppKit.h>
#import <ctype.h>
#import "Clavier.h"
#import "PianoOctave.h"
#import "MySlider.h"
#import "../ParamInterface.h"

char *GeneralMidiGroupings[16] = {
    "Piano",
    "Chromatic Percussion",
    "Organ",
    "Guitar",
    "Bass",
    "Strings",
    "Ensemble",
    "Brass",
    "Reed",
    "Pipe",
    "Synth Lead",
    "Synth Pad",
    "Synth Effects",
    "Ethnic",
    "Percussive",
    "Sound Effects"
};

char *GeneralMidiSounds[128] = {

 /* Piano */
    "Acoustic Grand Piano",
    "Bright Acoustic Piano",
    "Electric Grand Piano",
    "Honky-tonk Piano",
    "Elec Piano 1",
    "Elec Piano 2",
    "Harpsichord",
    "Clavichord",

 /* Chromatic Percussion */
    "Celesta",
    "Glockenspiel",
    "Music Box",
    "Vibraphone",
    "Marimba",
    "Xylophone",
    "Tubular Bells",
    "Dulcimer",

 /* Organ */
    "Drawbar Organ",
    "Percussive Organ",
    "Rock Organ",
    "Church Organ",
    "Reed Organ",
    "Accordion",
    "Harmonica",
    "Tango Accordion",

 /* Guitar */
    "Acoustic Guitar (nylon)",
    "Acoustic Guitar (steel)",
    "Electric Guitar (jazz)",
    "Electric Guitar (clean)",
    "Electric Guitar (muted)",
    "Overdriven Guitar",
    "Distortion Guitar",
    "Guitar Harmonics",

 /* Bass */
    "Acoustic Bass",
    "Electric Bass (finger)",
    "Electric Bass (pick)",
    "Fretless Bass",
    "Slap Bass 1",
    "Slap Bass 2",
    "Synth Bass 1",
    "Synth Bass 2",

 /* Strings */
    "Violin",
    "Viola",
    "Cello",
    "Contrabass",
    "Tremolo Strings",
    "Pizzicato Strings",
    "Orchestral Harp",
    "Timpani",

 /* Ensemble */
    "String Ensemble 1",
    "String Ensemble 2",
    "SynthStrings 1",
    "SynthStrings 2",
    "Choir Aahs",
    "Voice Oohs",
    "Synth Voice",
    "Orchestra Hit",

 /* Brass */
    "Trumpet",
    "Trombone",
    "Tuba",
    "Muted Trumpet",
    "French Horn",
    "Brass Section",
    "SynthBrass 1",
    "SynthBrass 2",

 /* Reed */
    "Soprano Sax",
    "Alto Sax",
    "Tenor Sax",
    "Baritone Sax",
    "Oboe",
    "English Horn",
    "Bassoon",
    "Clarinet",

 /* Pipe */
    "Piccolo",
    "Flute",
    "Recorder",
    "Pan Flute",
    "Blown Bottle",
    "Shakuhachi",
    "Whistle",
    "Ocarina",

 /* Synth Lead */
    "Lead 1 (square)",
    "Lead 2 (sawtooth)",
    "Lead 3 (calliope)",
    "Lead 4 (chiff)",
    "Lead 5 (charang)",
    "Lead 6 (voice)",
    "Lead 7 (fifths)",
    "Lead 8 (bass+lead)",

 /* Synth Pad */
    "Pad 1 (new age)",
    "Pad 2 (warm)",
    "Pad 3 (polysynth)",
    "Pad 4 (choir)",
    "Pad 5 (bowed)",
    "Pad 6 (metallic)",
    "Pad 7 (halo)",
    "Pad 8 (sweep)",

 /* Synth Effects */
    "FX 1 (rain)",
    "FX 2 (soundtrack)",
    "FX 3 (crystal)",
    "FX 4 (atmosphere)",
    "FX 5 (brightness)",
    "FX 6 (goblins)",
    "FX 7 (echoes)",
    "FX 8 (sci-fi)",

 /* Ethnic */
    "Sitar",
    "Banjo",
    "Shamisen",
    "Koto",
    "Kalimba",
    "Bad pipe",
    "Fiddle",
    "Shanai",

 /* Percussive */
    "Tinkle Bell",
    "Agogo",
    "Steel Drums",
    "Woodblock",
    "Taiko Drum",
    "Melodic Tom",
    "Synth Drum",
    "Reverse Cymbal",

 /* Sound Effects */
    "Guitar Fret Noise",
    "Breath Noise",
    "Seashore",
    "Bird Tweet",
    "Telephone Ring",
    "Helicopter",
    "Applause",
    "Gunshot"
};

static char *shortName(int controller)
{
	const char *name = controlNames(controller);
	static char name2[4];
	if (name) {
		int len = strlen(name);
		if (isalpha(name[0]) && isdigit(name[len-1])) {
			strncpy(name2, name, 2);
			name2[2] = name[len-1];
			name2[3] = 0;
		}
		else {
			strncpy(name2, name, 3);
			name2[3] = 0;
		}
	}
	else sprintf(name2, "%d", MIN(controller,999));
	return name2;
}

@implementation Clavier

- init
{
	int i;

	octave = 4;
	noteSender = [[MKNoteSender alloc] init];

	for (i = 0; i < 128; i++)
		noteTags[i] = MKNoteTag();

	soundGroup = 0;
	variation = 0;

	controllers[0] = 91;
	controllers[1] = 93;
	controllers[2] = 11;

        [NSBundle loadNibNamed:@"Clavier.nib" owner:self];
	return self;
}

- (void) awakeFromNib
{
	[window center];
	[pianoOctave1 setTag:0];	/* Indicates octaves from base octave */
	[pianoOctave2 setTag:1];
	[pianoOctave3 setTag:2];
	[modWheelSlider sendActionOn:(NX_MOUSEDOWNMASK | NX_MOUSEDRAGGEDMASK)];
	[pitchBendSlider setMinValue:0];
	[pitchBendSlider setMaxValue:16383.0];
	[pitchBendSlider setReturnValue:8192.0];	/* The centering value */
	[pitchBendSlider setDoubleValue:8192.0];
	[pitchBendSlider sendActionOn:
	 	(NX_MOUSEDOWNMASK | NX_MOUSEDRAGGEDMASK | NX_MOUSEUPMASK)];
	[controllerInterface setMode:CONTROLS];
	[controllerInterface setIntValues:controllers];
        [[controllerFields cellAt:0:0] setStringValue: [NSString stringWithCString: shortName(controllers[0])]];
        [[controllerFields cellAt:0:1] setStringValue: [NSString stringWithCString: shortName(controllers[1])]];
        [[controllerFields cellAt:0:2] setStringValue: [NSString stringWithCString: shortName(controllers[2])]];
	[soundGroupMatrix selectCellAt:0 :0];
        [soundGroupDisplayer setStringValue: [NSString stringWithCString: GeneralMidiGroupings[soundGroup]]];
	[variationMatrix selectCellAt:0 :0];
	[programChangeField setIntValue:soundGroup*8+variation];
}

- noteSender
{
	return noteSender;
}

- window
{
	return window;
}

- takeOctaveFrom:sender
 /* Set the base octave of the three octaves available. */
{
	octave = MAX(MIN(octave + [[sender selectedCell] tag], 7), 1);
        [octaveDisplayer setStringValue: [NSString stringWithFormat: @"C%d", octave - 1]];

	return self;
}

- takeKeyValueFrom:sender
 /* This gets sent by a PianoOctave control when a key is clicked on. */
{
	static id note = nil;
	int key = [sender intValue];

	[MKConductor lockPerformance];
	if (!note) {
		note = [[MKNote alloc] init];
		[note setPar:MK_velocity toInt:64];
	}
	[note setNoteType:([sender state:key]) ? MK_noteOn : MK_noteOff];
	/* The tag indicates how many octaves up from the base octave */
	[note setPar:MK_keyNum toInt:key += 12 * (octave + [sender tag])];
	[note setNoteTag:noteTags[key]];
	[noteSender sendNote:note];
	[MKConductor unlockPerformance];

	return self;
}

- setSound
{
	static id note = nil;
	int timbre;

	timbre = soundGroup * 8 + variation;
	if (timbre < 0 || timbre > 127) {
		fprintf(stderr, "timbre ( = %d ) must be 0-127\n", timbre);
		return nil;
	}
	[variationDisplayer setStringValue: [NSString stringWithCString: GeneralMidiSounds[timbre]]];
	[programChangeField setIntValue:timbre];

	[MKConductor lockPerformance];
	if (!note)
		[(note = [[MKNote alloc] init]) setNoteType :MK_noteUpdate];
	[note setPar:MK_programChange toInt:timbre];
	[noteSender sendNote:note];
	[MKConductor unlockPerformance];

	return self;
}

- takeSoundGroupFrom:sender
{
	soundGroup = [[sender selectedCell] tag];
	if (soundGroup < 0 || soundGroup > 15) {
		fprintf(stderr, "clavier.nib's soundGroup button tags "
				"( = %d ) must be 0-15\n", soundGroup);
		return nil;
	}
        [soundGroupDisplayer setStringValue: [NSString stringWithCString: GeneralMidiGroupings[soundGroup]]];
	[self setSound];
	return self;
}

- takeVariationFrom:sender
{
	variation = [[sender selectedCell] tag];
	if (variation < 0 || variation > 7) {
		fprintf(stderr, "clavier.nib's variation button tags ( = %d ) must be 0-7\n",
				variation);
		return nil;
	}
	[self setSound];
	return self;
}

- sendController:(int)controller value:(int)value
{
	static id note = nil;
	if (!note)
		[(note = [[MKNote alloc] init]) setNoteType :MK_noteUpdate];
	setControlValToInt(note, controller, value);

	[MKConductor lockPerformance];
	[noteSender sendNote:note];
	[MKConductor unlockPerformance];

	removeControl(note, controller);
	return self;
}

- takeModWheelFrom:sender
 /* This is sent by the modwheel slider. */
{
	return [self sendController:MIDI_MODWHEEL value:[sender intValue]];
}

- takePitchBendFrom:sender
 /* This is sent by the pitchBend slider. The sendController method expects a param
  * number in the ParamInterface object's numbering system, wherein Music Kit
  * parameters begin at MK_PAR_START (numbers below that are MIDI controllers) */
{
	return [self sendController:MK_pitchBend+MK_PAR_START value:[sender intValue]];
}

- takeSostenutoFrom:sender
 /* This is sent by the sustain button. */
{
	return [self sendController:MIDI_DAMPER value:([sender state]) ? 127 : 0];
}

- takeControlValFrom:sender
{
	return [self sendController:controllers[[[sender selectedCell] tag]]
				value:[sender intValue]];
}

- takeControllerFrom:sender
{
	int which = [sender selectedIndex];
	controllers[which] = [sender intValue];
        [[controllerFields cellAt:0:which] setStringValue: [NSString stringWithCString: shortName(controllers[which])]];
	return self;
}

@end
