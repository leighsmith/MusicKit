#ifndef __MK_EnsembleApp_H___
#define __MK_EnsembleApp_H___
#define MAXINSTRUMENTS 4
#define MAXPARTS 8

#import <appkit/Application.h>
#import <musickit/musickit.h>
#import "Clavier.subproj/Clavier.h"

@interface EnsembleApp : Application
{
    Orchestra *orchestra;	/* The resident DSP orchestra */
    Midi *midi;			/* Midi object handles MIDI I/O */
    Clavier *clavier;		/* The on-screen clavier  */
    id window;			/* The performance window */
    id preferences;		/* The preferences panel */
    id infoPanel;		/* The info panel */
    id notesPanel;		/* The release notes panel */
    id settings;		/* The document settings panel */
    id programChanger;		/* The instrument which does program changes */
    id playButton;		/* The Play button */
    id stopButton;		/* The Stop button */
    id pauseButton;		/* The Pause button */
    id recordButton;		/* The Record button */

    id tempoDisplayer;		/* The tempo text displayer */
    id tempoSlider;		/* The tempo slider */
    id scoreFileNameDisplayer;	/* The score file name displayer */
    id numPartsDisplayer;	/* The score's number of parts displayer */
    id recordButtons;		/* The record enable button matrix */
    id partSelectButtons;	/* The part number matrix */

    BOOL DSPCommands;		/* Creating DSPCommands file if true */
    BOOL writeData;		/* Creating sound file if true */
    MKPerformerStatus status;	/* The status of a performance */
    
    id soundSavePanel;		/* Alerts user to sound file write */
}

/** Connection of note senders and receivers to performers and recorders **/

- connectReceiver:receiver toPart:(int)partNum;
- disconnectReceiver:receiver fromPart:(int)partNum;
- connectReceiverToClavier:receiver;
- disconnectReceiverFromClavier:receiver;
- connectSenders:noteSenders toRecorder:(int)partNum;
- disconnectSenders:noteSenders fromRecorder:(int)partNum;
- (BOOL)isConnected:receiver toPart:(int)partNum;
- orchestra; /* Returns the orchestra */

/*******************  Main Window Interface methods  *********************/

- start;
- stop;
- pause;
- resume;
- reset;
- play:sender;
- pause:sender;
- stop:sender;
- record:sender;
- reset:sender;
- takeTempoFrom:sender;
- selectPart:sender;
- recordEnable:sender;
- mutePart:sender;

/*****************************  Score Files  *****************************/

- (BOOL)getScoreFile:(char *)path;
- openScoreFile:sender;
- newScore:sender;
- saveScore:sender;
- saveScoreAs:sender;
- changeSaveType:sender;

/***************************  Document Control  ***************************/

- new:sender;
- open:sender;
- saveAllDocuments:sender;
- showComments:sender;
- settings:sender;
- miniaturizeAll:sender;

/******************************  Printing  ********************************/

- pageLayout:sender;
- printKeyWindow:sender;

/********************************  Info  **********************************/

- info:sender;
- preferences:sender;
- preferences;
- (MKPerformerStatus)performanceStatus;

/**********************  Miscellaneous App Methods  **********************/

- midi;
- clavier:sender;
- terminate:sender;
- sendAllNotesOff:sender;
- setTempoFromDocument:(int)aTempo;
- sendRealTimeNote:(MKMidiParVal)message;
- synchDSP;
- synchDSPDelayed:(double)time;

@end

/*************** Other Functions and External Variables  *******************/

extern void mouseDownSliders(id view);

extern id pasteboard;
extern const char DocumentPBType[];
extern const char NoteFilterPBType[];
extern const char InstrumentPBType[];
extern const char PartPBType[];

extern BOOL multiThreaded;

extern BOOL batchMode;
extern BOOL newRanVals;
extern char *soundFile;
extern id soundOutDevice;

extern char scoreFilePath[];
#endif
