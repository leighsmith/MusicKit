
/* Generated by Interface Builder */

#import <Foundation/Foundation.h>

@interface MyObject: NSObject
{
	int numQuarterNotes;
	int numEighthNotes;
	int numSixteenthNotes;
	int numPitchesEnabled;
	unsigned char pitchMode[12];
	double tempo;
	id startStopButton;
}

- setNumQuarterNotes:sender;
- setNumEighthNotes:sender;
- setNumSixteenthNotes:sender;
- setTempoFrom:sender;
- setMode:sender;
- compute:sender;
- play:sender;

@end
