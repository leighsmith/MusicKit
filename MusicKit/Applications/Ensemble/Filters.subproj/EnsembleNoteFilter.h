#ifndef __MK_EnsembleNoteFilter_H___
#define __MK_EnsembleNoteFilter_H___
#import <musickit/musickit.h>
#import <appkit/Window.h>
#import "EnsembleDoc.h"

extern int filterStatePar;
#define NUMFILTERS 10
extern const char *filterNames[];
extern const char *filterClasses[];

@interface EnsembleNoteFilter : NoteFilter
  /* provides for a linked list of notefilters */
{
    EnsembleDoc *document;		/* The document for this note filter */
    NoteReceiver *noteReceiver;		/* It's note receiver and sender */
    NoteSender *noteSender;
    id performer;		/* The filter may control a performer */
    id inspectorPanel;			/* The interface panel */
    BOOL isEnabled;		/* Whether filter is connected to anything */
    int position;		/* The position in the note filter chain */
    int inputNum;		/* Which input stage */
    id nextFilter, lastFilter;	/* The previous and next filters in the list */
    id menuCell;		/* The menu cell used to open this filter */
	id bypassButton;
}

- init;
- setDefaults;
- inspectorPanel;
- showInspector;
- setEnabled:(BOOL)enable;
- (BOOL)isEnabled;
- setPosition:(int)position;
- (int)position;
- setInputNum:(int)inputNum;
- (int)inputNum;
- setNextFilter:aNoteFilter;
- nextFilter;
- setLastFilter:aNoteFilter;
- lastFilter;
- toggleBypass:sender;
- reset;
- reset:sender;
- allSenders;
- setDocument:aDocument;
- setMenuCell:aCell;
- performer;

@end
  

#endif
