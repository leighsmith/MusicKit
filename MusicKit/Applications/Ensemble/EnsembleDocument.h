#ifndef __MK_EnsembleDocument_H___
#define __MK_EnsembleDocument_H___
/* Obsolete - see EnsembleDoc.h */
#import <objc/Object.h>

#define MAXINSTRUMENTS 4

@interface EnsembleDocument:Object
{
	id window;
    id orchestra;	     /* The default DSP orchestra */
    id midi;
    double samplingRate;	     /* The document's sampling rate */
    double headroom;		     /* The document's orchestra headroom */
    int tempo;			     /* A tempo associated with this doc */
    int dspNum;			     /* The documents DSP (not now used) */
    BOOL loadScore;		     /* Associate score with document if YES */
    BOOL isConnected;		     /* Document is connected to performers */
    BOOL usesDSP;		     /* Document includes DSP instruments */
    char *scoreFilePath;	     /* Path of associated score file if any */
    id noteFilters[MAXINSTRUMENTS];  /* First notefilters in linked list */
    id instruments[MAXINSTRUMENTS];  /* The instruments */
    int partNums[MAXINSTRUMENTS];    /* Part number for each input stage */
    int midiChannels[MAXINSTRUMENTS]; /* Midi channel for each input stage */
    BOOL midiEnabled[MAXINSTRUMENTS]; /* Receive notes from midi or not */
    BOOL partEnabled[MAXINSTRUMENTS]; /* Recieve notes from score or not */
    BOOL instrumentMap[MAXINSTRUMENTS]
	              [MAXINSTRUMENTS];	/* Map inputs to instruments */
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

    id commentPanel;		     /* The document's comment panel */
    int selectedInput;		     /* Number of selected input stage */
    int selectedInstrument;	     /* Number of selected instrument */
    int program;		     /* Document's program change */
    int headphoneLevel;		/* The level of the heaphone outputs */
    BOOL deemphasis;		/* Deemphasis filter setting */
}

@end
#endif
