/* FFT.m -- Implementation of FFT object
 *
 * This object manages the FFT display panel for edsnd.
 * See FFT.h for more details
 *
 * jwp@silvertone.Princeton.edu, 1/90
 * Version 1.3, 02/90
 *	-- Added support for Spectrum Analysis (courtesy Steve Boker)
 *	-- Fixed bug that allowed FFT of fragmented files
 * Version 1.31, 03/90
 *	-- Fixed bug in setFFTSize that caused program to crash if
 *	   the sound had changed since the last displayFFT:
 */

#import "FFT.h"
#import "FFTView.h"
#import "SpectrumView.h"
#import "EdsndApp.h"
#import "SoundDocument.h"
#import "ScrollingSound.h"
#import "UpPanel.h"

#import <appkit/Panel.h>
#import <appkit/Button.h>
#import <appkit/PopUpList.h>
#import <appkit/Form.h>
#import <appkit/Application.h>

#import <soundkit/Sound.h>
#import <soundkit/SoundView.h>

/* Convenient macros to select a specific row in a pop-up list,
 * and to get the selected row in a pop-up list.
 */
#define PULSelectRow(button,row) \
	[button setTitle:[[[[button target] itemList] cellAt:row :0] title]]
#define PULGetRow(button) \
	[[[button target] itemList] selectedRow]

@implementation FFT
/* new -- Make a new instance of this object
 * This loads the .nib file and initializes the pop-up list for FFT size
 */
+ new
{
	id pul;		/* Pointer to the pop-up lists */

	self = [super new];
	[NXApp loadNibSection:"FFT.nib" owner:self];

/* Set up the pop-up list that does FFT size selection for the 
 * FFT display panel
 */
 	pul = [PopUpList new];
	[pul addItem:"256"];
	[pul addItem:"512"];
	[pul addItem:"1024"];
	[pul addItem:"2048"];
	NXAttachPopUpList(fftSizeButton, pul);
	PULSelectRow(fftSizeButton,1);		/* Select 512 points */

/* Set up the pop-up list that does Spectrum sliding window selection 
 * for the Spectrum display panel
 */
 	pul = [PopUpList new];
	[pul addItem:"64"];
	[pul addItem:"128"];
	[pul addItem:"256"];
	[pul addItem:"512"];
	[pul addItem:"1024"];
	[pul addItem:"2048"];
	NXAttachPopUpList(spectrumSlideButton, pul);
	PULSelectRow(spectrumSlideButton,3);		/* Select 512 points */
	slidepoints = 512;

/* Other initializations
 */
	[spectrumView setMeanDisplay:[spectrumMeanButton state]];
	[spectrumView setSpectrumDisplay:[spectrumSpectButton state]];

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* displayFFT: -- Bring up the FFT panel and/or display the spectrum
 */
- displayFFT:sender
{
	id scroller;			/* Scroller within current window */
	float start,size;		/* start/size of selection */

	if (![NXApp isOpenSound])
		return self;

/* Find the current document's scroller and sound, and set up the FFT
 */
	scroller = [[[NXApp mainWindow] delegate] scroller];
	[fftView setSound:[[scroller view] sound]];
	[scroller getSelStart:&start Size:&size];
	[fftView setInskip:start];
	[fftView display];
	[fftPanel makeKeyAndOrderFront:self];

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* displaySpectrum: -- Animate the Spectrum over the selection
 */
- displaySpectrum:sender
{
	id scroller;		/* Current doc's scroller */
	id sound;		/* The sound within that scroller */

	float start,size;	/* Selection start/size times */

/* If there's no current sound, don't do a thing
 */
	if (![NXApp isOpenSound]) {
		return self;
	}

/* Get all the relevant info from the scroller and the sound
 */
	scroller = [[[NXApp mainWindow] delegate] scroller];
	sound = [[scroller view] sound];
	[scroller getSelStart:&start Size:&size];
	if (size == 0.0)
		return self;
	[spectrumPanel makeKeyAndOrderFront:self];
	[spectrumView   doSpectrum:sound
			Start:start
			Dur:size
			Npoints:[fftView npoints]
			Slidepoints: slidepoints ];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setFFTSize: -- Set the size of the FFT window
 */
- setFFTSize:sender
{
	int row;
	id scroller = [[[NXApp mainWindow] delegate] scroller];
	float start,size;	/* Selection start/size times */

/* Get the row of the selected button and derive size from that.
 * Row 0 = 256, Row 1 = 512, etc.
 */
	row = PULGetRow(fftSizeButton);
	[fftView setNpoints: 256 << row];
	[fftView setSound:[[NXApp currentSound] sound]];
	[scroller getSelStart:&start Size:&size];
	[fftView setInskip:start];
	[fftView display];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* SetFFTScaling: -- set FFT scaling type
 * Sender is matrix of Radio buttons
 */
- setFFTScaling:sender
{
	[fftView dBdisplay:[[sender selectedCell] tag]];
	[spectrumView dBdisplay:[[sender selectedCell] tag]];
	[fftView display];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSpectrumSlide: -- Set the size of the Spectrum sliding window
 */
- setSpectrumSlide:sender
{
	int row;

/* Get the row of the selected button and derive size from that.
 * Row 0 = 64, Row 1 = 128, etc.
 */
	row = PULGetRow(spectrumSlideButton);
	slidepoints = 64 << row;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* SetSpectrumMean: -- set SpectrumView to display Mean line
 * Sender is a switch button
 */
- setSpectrumMean:sender
{
	[spectrumView setMeanDisplay:[sender state]];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* SetSpectrum: -- set SpectrumView to display Spectrum
 * Sender is a switch button
 */
- setSpectrum:sender
{
	[spectrumView setSpectrumDisplay:[sender state]];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* cursorMoved:  -- Respond to changes in FFTView cursor position
 * This writes the cursor's freq/amp position into the forms
 */
- cursorMoved:sender
{
	float time,freq,amp,mean;	/* The cursor position data */
	char s[16];			/* Space for sprintf */

	if (sender == fftView) {
		[fftView getCursorFreq:&freq Amp:&amp];
		sprintf(s,"%8.3f",freq);
		[fftFreqForm setStringValue:s at:0];
		sprintf(s,"%8.3f",amp);
		[fftAmpForm setStringValue:s at:0];
	}
	else if (sender == spectrumView) {
		[spectrumView getCursorTime:&time Freq:&freq Mean:&mean];
		sprintf(s,"%8.3f",time);
		[spectrumTimeForm setStringValue:s at:0];
		sprintf(s,"%8.3f",freq);
		[spectrumFreqForm setStringValue:s at:0];
		sprintf(s,"%8.3f",mean);
		[spectrumMeanForm setStringValue:s at:0];
	}
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* For Interface Builder ...
 */

- setFftPanel:anObject
{
	fftPanel = anObject;
	[fftPanel setUpdateAction:@selector(panelUpdate:) by:NXApp];
	return self;
}

- setFftView:anObject
{
	fftView = anObject;
	[fftView setDelegate:self];	/* To get cursorMoved: messages */
	return self;
}
- setFftAmpForm:anObject
{
	fftAmpForm = anObject;
	return self;
}
- setFftFreqForm:anObject
{
	fftFreqForm = anObject;
	return self;
}
- setFftSizeButton:anObject
{
	fftSizeButton = anObject;
	return self;
}
- setSpectrumPanel:anObject
{
	spectrumPanel = anObject;
	[spectrumPanel setUpdateAction:@selector(panelUpdate:) by:NXApp];
	return self;
}
- setSpectrumView:anObject
{
	spectrumView = anObject;
	[spectrumView setDelegate:self];     /* To get cursorMoved: messages */
	return self;
}
- setSpectrumMeanForm:anObject
{
	spectrumMeanForm = anObject;
	return self;
}
- setSpectrumFreqForm:anObject
{
	spectrumFreqForm = anObject;
	return self;
}
- setSpectrumTimeForm:anObject
{
	spectrumTimeForm = anObject;
	return self;
}
- setSpectrumSlideButton:anObject
{
	spectrumSlideButton = anObject;
	return self;
}
- setSpectrumMeanButton:anObject
{
	spectrumMeanButton = anObject;
	return self;
}
- setSpectrumSpectButton:anObject
{
	spectrumSpectButton = anObject;
	return self;
}

@end
