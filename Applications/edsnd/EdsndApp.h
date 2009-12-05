/* EdsndApp.h -- Interface for the edsnd Application object
 * 
 * This is a custom Application object.  EdsndApp does the following:
 *	1) Performs all normal Application functions
 *	2) Creates new SoundDocuments
 *	3) Manages all accessory user interface objects
 *
 * Original code by Lee Boynton
 * Revision by James Pritchett, 10/89
 * Version 1.01, 11/89 
 *	-- changed "SoundController" to "EdsndApp" and made it
 *	   a subclass of Application rather than an Application delegate
 *	-- Changed menu management to standard method via update actions
 *	-- Now checks for unsaved files before quitting
 * Version 1.1, 12/89
 *	-- Added Stopwatch
 * Version 1.2, 1/90
 *	-- Added FFT display
 * 	-- Added enveloping
 *	-- Added methods to get flag values
 * Version 1.3, 2/90
 *	-- Added Spectrum display (courtesy of Steven Boker)
 * Version 1.31, 3/90
 *	-- EdsndApp now keeps track of the currentSound for use by the
 *	   accessories
 */
 
#import <appkit/Application.h>

@interface EdsndApp:Application
{
	id currentSound;	/* The SoundView we're editing now */

	id addPanel;		/* Panel to prompt for AddSilence time */
	id addForm;		/* Input form within that panel */

	id watch;		/* The stopwatch object */
	id watchPanel;		/* Its panel */

	id FFTObj;		/* The FFT manager */
	id EnvObj;		/* The enveloping manager */

	BOOL openDoc;		/* Flags to keep track of documents */
	BOOL openSound;
	BOOL openFile;
	BOOL isPlaying;		/* Are we playing now? */
}

/* Custom versions of Application methods:
 *	new		-- Initializes variables
 *	hide: 		-- Stops sound before hiding
 *	terminate:	-- Checks for unsaved files before quitting
 *	appDidInit:	-- pseudo-delegate method to initialize things
 */
+ new;
- hide:sender;
- terminate:sender;
- appDidInit:sender;

/* Methods to create SoundDocuments:
 *	newDocument:	-- Open a new, empty SoundDocument
 *	open:		-- Open a SoundDocument from a file
 */
- newDocument:sender;
- open:sender;

/* Management for accessory objects:
 *	Response to AddPanel/AddForm entry:
 *		- addSil:		-- Send an AddSilence: message
 *	Management of stopwatch:
 *		- stopwatch:		-- Bring up the stopwatch
 *		- stopwatchWillStart: 	-- delegate methods
 *		- stopwatchDidStop:
 *		- isPlaying:		-- Are we still playing a sound?
 * 	Management of FFT display:
 *		- showFFT:		-- Create and/or bring up the FFT
 *	Management of envelope display
 *		- showEnv:		-- Create and/or bring up the envelope
 *	Activate/Deactivate Menu cells:
 *		- isOpenDocument:	-- is there an open document?
 *		- isOpenDocument	-- (returns above value)
 *		- isOpenSound:		-- is there an open non-empty sound?
 *		- isOpenSound		-- (returns above value)
 *		- isOpenFile:		-- is there an open non-null filename?
 *		- isOpenFile		-- (returns above value)
 *		- menuUpdate:		-- update action for menu cells
 */
- addSil:sender;
- stopwatch:sender;
- stopwatchWillStart:sender;
- stopwatchDidStop:sender;
- showFFT:sender;
- showEnv:sender;
- isOpenDocument:(BOOL)flag;	/* Sets YES/NO */
- (BOOL)isOpenDocument;		/* Returns YES/NO */
- isOpenSound:(BOOL)flag;
- (BOOL)isOpenSound;
- isOpenFile:(BOOL)flag;
- (BOOL)isOpenFile;
- isPlaying:(BOOL)flag;
- menuUpdate:sender;


/* Get/set instance variables
 */
- setCurrentSound:aSoundView;
- currentSound;
- setAddPanel:anObject;
- setAddForm:anObject;

@end
