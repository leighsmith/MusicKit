/* EdsndApp.m -- Implementation for EdsndApp object.
 *
 * Original code by Lee Boynton
 * Revision by James Pritchett, 10/89
 * Version 1.01, 11/89
 * Version 1.1, 12/89
 *	-- Added Stopwatch support
 *	-- Re-arranged menu cell tags
 * Version 1.2, 1/90
 *	-- Added FFT display 
 *	-- Added enveloping
 *	-- Added methods to retrieve flag values
 *	-- Changed menu updating system
 *	-- Changed all accessories to UpPanels and added updating
 * Version 1.3, 2/90 (Steven M. Boker)
 *  	-- Added Spectrum display
 * Version 1.31, 3/90
 *	-- EdsndApp now keeps track of the current Sound
 */

 
#import "EdsndApp.h"
#import "SoundDocument.h"
#import "ScrollingSound.h"
#import "EdSoundView.h"
#import "Stopwatch.h"
#import "FFT.h"
#import "Envelope.h"
#import "UpPanel.h"

#import <string.h>
#import <appkit/Form.h>
#import <appkit/OpenPanel.h>
#import <appkit/Cursor.h>
#import <appkit/Panel.h>
#import <appkit/Menu.h>
#import <appkit/MenuCell.h>

/* Tags on menu cells identify what conditions are necessary for them
 * to be active:
 */
#define NEEDSNIL  0	/* Always enabled */
#define NEEDSDOC  1	/* Needs an open document */
#define NEEDSSND  2	/* Needs some sound (i.e., non-empty document) */
#define NEEDSFILE 3	/* Needs a filename */


/* C FUNCTIONS NEEDED BY EdsndApp METHODS:
 *
 * getOpenPath() -- Gets a filename and path for the open command.
 *	Uses an OpenPanel object to get the filename.
 */
static BOOL getOpenPath(char *buf)
{
    static id	openPanel = nil;
    BOOL	ok;
    char const *fileTypes[2] = {0,0};

    if (!openPanel) {
	[NXWait set];		/* This sets cursor to "disk wait" form */
	NXPing();
        openPanel = [OpenPanel new];	/* panel for getting filename */
	[NXArrow set];
	NXPing();
    }
   [NXApp setAutoupdate:NO];

/* OpenPanel object will prompt user for a filename and return it.
 */
    if ([openPanel runModalForTypes:fileTypes]) {
	strcpy(buf,[openPanel filename]);
	[NXApp setAutoupdate:YES];
	return YES;
    } else {
	[NXApp setAutoupdate:YES];
	return NO;
    }
}

static void initMenu(id menu)
/*
 * Sets the updateAction for every menu item.  This function is recursive:
 * it calls itself to handle sub-menus. 
 */ 
{
    int count;
    id matrix, cell;

    matrix = [menu itemList];
    count = [matrix cellCount];

    while (count--) {
	cell = [matrix cellAt:count :0];
	[cell setUpdateAction:@selector(menuUpdate:) forMenu:menu];
	if ([cell hasSubmenu])
	    initMenu([cell target]);
    }
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

@implementation EdsndApp

/* new -- create and initialize all variables
 */
+ new
{
	self = [super new];
	openDoc = openSound = openFile = NO;
	currentSound = nil;
}
/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* appDidInit: -- issued when application is initialized
 *	(since there's no delegate for the Application, the Application
 *	will be issued this message)
 */
- appDidInit:sender
{
/* Set the update method for all menu cells
 */
	initMenu([NXApp mainMenu]);
	[self setAutoupdate:YES];

	return self;
}
	
/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* hide: -- Hide the Application, but stop any play first
 */
- hide:sender
{
/* Note:  mainWindow is always the current SoundDocument (no other
 *	windows in this application)
 * The SoundDocument is the delegate for its window.
 */
	if (mainWindow)
 	   [[mainWindow delegate] stop:self];
        return [super hide:sender];
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* terminate: -- Quit the Application, but save any unsaved files first
 */
- terminate:sender
{
	id win;			/* Pointer to window */
	int choice;

/* Go through window list any find any edited documents.  Prompt user to
 *	save them or not, and issue a save: command if necessary.
 */
 
	while ((win = 
	      [self makeWindowsPerform:@selector(isDocEdited) inOrder:NO])
	      != nil) {
		[win orderFront:sender];
		choice = 
		NXRunAlertPanel("Quit", "%s is modified.\nSave it?",
			        "Yes", "No", NULL, [win title]);
		switch (choice) {
	 		case NX_ALERTALTERNATE:
				[win setDocEdited:NO];
				break;
			case NX_ALERTDEFAULT:
				[[win delegate] save:self];
				break;
		}
	}
	[super terminate:sender];
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* newDocument: -- Create a new, empty SoundDocument
 */
- newDocument:sender
{
	[SoundDocument new];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* open: -- Open a file in response to menu selection
 */
- open:sender
{
    char pathname[1024];
    id newDocument;
    
    if (getOpenPath(pathname)) {
	newDocument = [SoundDocument new];
	[newDocument setFileName:pathname];
	[newDocument load:self];
    }
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* addSil: -- Translate input from AddPanel to EdSoundView
 */
- addSil:sender
{
	float dur;

	dur = [addForm floatValueAt:0];
	if (currentSound)
		[currentSound addSilence:dur];
	[addPanel orderOut:self];
	return self;
}	

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* stopwatch: -- Bring up the stopwatch panel
 */

- stopwatch:sender
{
/* Make the stopwatch if we haven't already done so
 */
	if (watch == nil) {
		watch = [Stopwatch new];
		watchPanel = [watch panel];
		[watch setDelegate:self];	/* We're the delegate */
	}
	[watchPanel makeKeyAndOrderFront:self];
	return self;
}

/* stopwatchWillStart:, stopwatchDidStop: -- delegate methods for stopwatch
 */

- stopwatchWillStart:sender
{
	id curDoc;
	if (openDoc) {
		curDoc = [[self mainWindow] delegate];
		[watch setTarget:curDoc
		       toStart:@selector(play:)
		       andStop:@selector(stop:)];
	}
	return self;
}

- stopwatchDidStop:sender
{
	[watch setTarget:nil 
	       toStart:@selector(play:) andStop:@selector(stop:)];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* showFFT:	-- Create and/or bring up the FFT panel
 */
- showFFT:sender
{
/* If the FFT manager doesn't exist, make it
 */
	if (!FFTObj)
		FFTObj = [FFT new];

	[FFTObj displayFFT:self];

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* showEnv:	-- Create and/or bring up the Envelope panel
 */
- showEnv:sender
{
/* If the envelope manager doesn't exist, make it
 */
	if (!EnvObj)
		EnvObj = [Envelope new];

	[[EnvObj envPanel] makeKeyAndOrderFront:self];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* isOpenDocument:, isOpenSound:, isOpenFile: -- set/reset flags to control
 *	menu cells
 * isOpenDocument, isOpenSound, isOpenFile -- return those flags
 */
- isOpenDocument:(BOOL)flag
{
	openDoc = flag;
	if (!flag)			/* No doc means no sound or file */
		openSound = openFile = flag;
	return self;
}

- isOpenSound:(BOOL)flag
{
	openSound = flag;
	return self;
}

- isOpenFile:(BOOL)flag
{
	openFile = flag;
	return self;
}

- (BOOL)isOpenDocument
{
	return openDoc;
}
- (BOOL)isOpenSound
{
	return openSound;
}
- (BOOL)isOpenFile
{
	return openFile;
}

- isPlaying:(BOOL)flag
{
	isPlaying = flag;
	if (!flag && (watch != nil))	/* Stop the watch if necc. */
		[watch performStop:self];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* menuUpdate -- Update action for menu cells
 */
- menuUpdate:sender
{
/* We keep up with menu cells by their tag #'s.  See above for
 * details.
 */
	switch([sender tag]) {
		case NEEDSDOC:
			[sender setEnabled:openDoc];
			break;
		case NEEDSSND:
			[sender setEnabled:openSound];
			break;
		case NEEDSFILE:
			[sender setEnabled:openFile];
			break;
		default:
			[sender setEnabled:YES];
			break;
	}
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
/* panelUpdate: update action for UpPanels (accessories)
 *	Panels are removed when there's no open document.
 */
 - panelUpdate:sender
 {
 	if (!openDoc)
		[sender orderOut:self];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* Get/set instance variables
 */

- setCurrentSound:aSoundView
{
	currentSound = aSoundView;
	return self;
}

- currentSound
{
	return currentSound;
}

- setAddForm:anObject
{
	addForm = anObject;
	return self;
}

- setAddPanel:anObject
{
	addPanel = anObject;
	[addPanel setUpdateAction:@selector(panelUpdate:) by:NXApp];
	return self;
}



@end
