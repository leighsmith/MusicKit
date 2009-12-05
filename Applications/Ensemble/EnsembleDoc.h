#ifndef __MK_EnsembleDoc_H___
#define __MK_EnsembleDoc_H___
#import <objc/Object.h>
#import "EnsembleApp.h"
#import "GenericDocument.h"

@interface EnsembleDoc:GenericDocument
{
    id inputSelectButtons;	     /* Interface controls and displayers */
    id insSelectButtons;
    id midiChanDisplayer;
    id partNumDisplayer;
    id instrumentBox0;
    id instrumentBox1;
    id instrumentBox2;
    id instrumentBox3;
    id filterButton0;
    id filterButton1;
    id filterButton2;
    id filterButton3;
    id instrumentButton0;
    id instrumentButton1;
    id instrumentButton2;
    id instrumentButton3;
    id instrumentBoxes[MAXINSTRUMENTS];
    id filterButtons[MAXINSTRUMENTS];
    id instrumentButtons[MAXINSTRUMENTS];
	id keyRangeSliders;
	id keyRangeFields;
	id transposeSliders;
	id transposeFields;

    Orchestra *orchestra;	     /* The default DSP orchestra */
    id midi;
	id muteButton0;
	id muteButton1;
	id muteButton2;
	id muteButton3;
	id muteButtons[MAXINSTRUMENTS];
	id insNumButton0;
	id insNumButton1;
	id insNumButton2;
	id insNumButton3;
	id insNumButtons[MAXINSTRUMENTS];
	
	id midiButton0;
	id midiButton1;
	id midiButton2;
	id midiButton3;
	id scoreButton0;
	id scoreButton1;
	id scoreButton2;
	id scoreButton3;

@public
    double samplingRate;	     /* The document's sampling rate */
    double headroom;		     /* The document's orchestra headroom */
    int tempo;			     /* A tempo associated with this doc */
    int dspNum;			     /* The documents DSP (not now used) */
    BOOL loadScore;		     /* Associate score with document if YES */
    BOOL isConnected;		     /* Document is connected to performers */
    BOOL usesDSP;		     /* Document includes DSP instruments */
    char *scoreFile;	     /* Path of associated score file if any */
    id noteFilters[MAXINSTRUMENTS];  /* First notefilters in linked list */
    id instruments[MAXINSTRUMENTS];  /* The instruments */
    int partNums[MAXINSTRUMENTS];    /* Part number for each input stage */
    int midiChannels[MAXINSTRUMENTS]; /* Midi channel for each input stage */
    BOOL midiEnabled[MAXINSTRUMENTS]; /* Receive notes from midi or not */
    BOOL partEnabled[MAXINSTRUMENTS]; /* Recieve notes from score or not */
    BOOL instrumentMap[MAXINSTRUMENTS]
	              [MAXINSTRUMENTS];	/* Map inputs to instruments */

    id commentPanel;		     /* The document's comment text (object) */
    id commentText;		     /* The document's comment text (object) */
    int selectedInput;		     /* Number of selected input stage */
    int selectedInstrument;	     /* Number of selected instrument */
    int program;		     /* Document's program change */
    int headphoneLevel;		/* The level of the heaphone outputs */
    BOOL deemphasis;		/* Deemphasis filter setting */
}

/*****************  Document Window Interface Methods  *******************/

- selectInput:sender;
- selectInstrument:sender;
- takeMidiChannelFrom:sender;
- muteMidiInput:sender;
- takePartNumberFrom:sender;
- mutePartInput:sender;
- takeNoteFilterFrom:sender;
- takeInstrumentNumberFrom:sender;
- takeInstrumentFrom:sender;
- sendTestNote:sender;
- muteInstrument:sender;

/***************************  Note Filters  *****************************/

- addFilter:filterOrFilterClass toInput:(int)inputNum atPosition:(int)position;
- connectToPerformers:aNoteFilter;
- connectToInstruments:aNoteFilter;
- firstEnabledFilter:(int)inputNum;
- lastEnabledFilter:(int)inputNum;

/***************************  Instruments  *****************************/

- addInstrument:insClass number:(int)insNum;
- addInstrumentView:instrument at:(int)position;
- (BOOL *)instrumentMap:(int)inputNum;
- (id *)instruments;
- updates:(int)insNum;
- controllers:(int)insNum;
- allocatePatches;
- displayPatchCounts;

/***************************  The Document  *****************************/

- connect;
- disconnect;
- (BOOL)isConnected;
- (int)partNum:(int)inputNum;
- setSamplingRate:(double)srate;
- setHeadroom:(double)headroom;
- setLoadScore:(BOOL)loadScore;
- setDspNum:(int)dspNum;
- setProgram:(int)number;
- setSoundDeemphasis:(BOOL)state;
- setHeadphoneLevel:(int)level;
- (double)samplingRate;
- (double)headroom;
- (BOOL)loadScore;
- (char *)scoreFilePath;
- (BOOL)usesDSP;
- (int)dspNum;
- (int)program;
- (int)headphoneLevel;
- (BOOL)deemphasis;
- setDocumentTempo:(int)aTempo;
- (int)documentTempo;
- setWindowTitles;
- setMidi:newMidi;
- (BOOL)inputFromSSI;
- commentPanel;

@end
  
extern EnsembleDoc *currentDocument;
#endif
