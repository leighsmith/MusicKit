#import <musickit/musickit.h>
#import "LoochPerformer.h"
#import "RandomIzer.h"

@implementation LoochPerformer:Performer
{
	id LoochNote;
}

int aTag;
id RandNum;

-initialize
  /* This method is invoked when a new instance is created. */
{

	/* You must send [super initialize] in your subclass' implementation. */
	[super initialize];
	LoochNote = [Note new];
	[LoochNote setNoteType:MK_noteOn];
	[LoochNote setNoteTag:aTag = MKNoteTag()];
	/* We give ourselves one NoteSender. */  
	[self addNoteSender:[NoteSender new]];

	[self setDefaults];
	
	RandNum = [RandomIzer new];
	[RandNum setit];

	return self;
}


-setDefaults
/* used internally to set the LoochNote attributes upon initialization */
{
	[LoochNote setPar:MK_amp toDouble:0.1];
	[LoochNote setPar:MK_freq0 toDouble:100.0];
	[LoochNote setPar:MK_freq1 toDouble:100.0];
//	[LoochNote setPar:MK_bearing toDouble:0.0];
	[LoochNote setPar:MK_waveform toWaveTable:nil];
	[LoochNote setPar:MK_ampAtt toDouble:1.0];
	[LoochNote setPar:MK_ampRel toDouble:1.0];
	[LoochNote setPar:MK_svibFreq toDouble:0.2];
	[LoochNote setPar:MK_svibAmp toDouble:1.0];
	[LoochNote setPar:MK_rvibFreq toDouble:0.2];
	[LoochNote setPar:MK_rvibAmp toDouble:1.0];
}


-startNote
{
	[LoochNote setNoteType:MK_noteOn];
	[[self noteSender] sendNote:LoochNote];

	return self;
}


-stopNote
{
	[LoochNote setNoteType:MK_noteOff];
	[[self noteSender] sendNote:LoochNote];

	return self;
}


-changeNote
{
	[LoochNote setNoteType:MK_noteUpdate];
	[[self noteSender] sendNote:LoochNote];

	return self;
}


-pause
{
	[LoochNote setNoteType:MK_noteOff];
	[[self noteSender] sendNote:LoochNote];

	return self;
}

-setfreq:(double)hz spread:(double)window
{
	double deviate = [RandNum GetPlusMinus:window];
	
	[LoochNote setPar:MK_freq0 toDouble:hz];
	[LoochNote setPar:MK_freq1 toDouble:(hz+deviate)];

	return(self);
}

-setamp:(double)amplitude
{
	[LoochNote setPar:MK_amp toDouble:amplitude];

	return(self);
}

-setbearing:(double)bearing
{
	[LoochNote setPar:MK_bearing toDouble:bearing];

	return(self);
}

-setwave:(id)thePartials
{
	[LoochNote setPar:MK_waveform toWaveTable:thePartials];
	
	return(self);
}

-setattack:(double)attack
{
	[LoochNote setPar:MK_ampAtt toDouble:attack];
	
	return(self);
}

-setdecay:(double)decay
{
	[LoochNote setPar:MK_ampRel toDouble:decay];

	return(self);
}

-setvibfreq0:(double)vfreq
{
	[LoochNote setPar:MK_svibFreq toDouble:vfreq];

	return(self);
}

-setvibfreq1:(double)vfreq
{
	[LoochNote setPar:MK_rvibFreq toDouble:(vfreq)];

	return(self);
}

-setvibamp0:(double)vamp
/* this is expressed as Hz, which represents the max deviation in Hz
   from the base freq */
{
	[LoochNote setPar:MK_svibAmp toDouble:vamp];

	return(self);
}

-setvibamp1:(double)vamp
/* this is expressed as Hz, which represents the max deviation in Hz
   from the base freq */
{
	[LoochNote setPar:MK_rvibAmp toDouble:(vamp)];

	return(self);
}

@end