#ifndef __MK_Settings_H___
#define __MK_Settings_H___
#import <appkit/Panel.h>

@interface Settings:Panel
    /* A panel for setting document-specific preferences */
{
    double samplingRate;	/* The sampling rate for this document */
    double headroom;		/* The orchestra headroom for this document */
    int dspNum;			/* The dsp number (unused) */
    BOOL loadScore;		/* Whether to associate a score with the doc */
    int program;
    int headphoneLevel;
    BOOL deemphasis;
    id  documentDisplayer;
    id	headroomDisplayer;
    id	srateDisplayer;
    id  loadScoreDisplayer;
    id  dspNumDisplayer;
    id  programDisplayer;
    id  levelDisplayer;
    id  deemphasisDisplayer;
}

- takeSrateFrom:sender;
- takeHeadroomFrom:sender;
- takeLoadScoreFrom:sender;
- takeDspNumFrom:sender;
- takeProgramFrom:sender;
- takeHeadphoneLevelFrom:sender;
- takeDeemphasisFrom:sender;
- runModal:sender;
- ok:sender;
- cancel:sender;

@end


#endif
