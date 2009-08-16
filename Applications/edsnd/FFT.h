/* FFT.h -- Interface for FFT object
 *
 * This is a custom object that handles the FFT display in edsnd.
 * It manages the FFTpanel, FFTView, the SpectrumPanel, SpectrumView, 
 * and the buttons and forms that control the views.
 * 
 * Only one instance of this object is created by EdsndApp.
 *
 * jwp@silvertone.Princeton.edu, 1/90
 * Version 1.3, 2/90
 *	-- Added Spectral Analysis (courtesy Steven Boker)
 */


#import <objc/Object.h>

@interface FFT : Object
{
	id fftPanel;		/* Panel for FFT display */
	id fftView;		/* FFTView in this panel */
	id fftAmpForm;		/* Cursor display forms */
	id fftFreqForm;
	id fftSizeButton;	/* Pop-up list for setting FFT window size */

	id spectrumPanel;	/* Panel for Spectrum display */
	id spectrumView;	/* SpectrumView in this panel */
	id spectrumMeanForm;	/* Cursor display forms */
	id spectrumTimeForm;
	id spectrumFreqForm;
	id spectrumSlideButton;	/* Pop-up list for setting Spectrum slide */
	id spectrumMeanButton;	/* Radio button for mean freq. display */
	id spectrumSpectButton;	/* Radio button for Spectrum display */
	int slidepoints;	/* Spectrum slide */
}

/* Class methods:
 * 
 * Creating the object:
 *	+ new		-- Initializes pop-up lists 
 */
+ new;

/* Instance methods:
 *
 * Displaying the FFT:
 *	- displayFFT:	-- Brings up the panel, attaches the current sound
 *			   to the FFTView, and displays.
 *	- displaySpectrum:	-- Brings up the panel, and displays spectrum
 *				   over current selection.
 */
- displayFFT:sender;
- displaySpectrum:sender;

/* Setting up the views
 *	- setFFTSize:		-- Set the number of points in the FFT
 *	- setFFTScaling:	-- Set the scaling type for the FFT
 *	- setSpectrumSlide:	-- Set the slide on Spectrum display
 *	- setSpectrumMean:	-- Select/deselect mean freq. display
 *	- setSpectrum:		-- Select/deselect spectrum display
 */
- setFFTSize:sender;
- setFFTScaling:sender;
- setSpectrumSlide:sender;
- setSpectrumMean:sender;
- setSpectrum:sender;

/* Responding to the views
 *	- cursorMoved:		-- Reflect changes in a view's cursor
 *				   position.
 */
- cursorMoved:sender;

/* .nib stuff:
 */
- setFftPanel:anObject;
- setFftView:anObject;
- setFftAmpForm:anObject;
- setFftFreqForm:anObject;
- setFftSizeButton:anObject;
- setSpectrumPanel:anObject;
- setSpectrumView:anObject;
- setSpectrumMeanForm:anObject;
- setSpectrumFreqForm:anObject;
- setSpectrumTimeForm:anObject;
- setSpectrumSlideButton:anObject;
- setSpectrumMeanButton:anObject;
- setSpectrumSpectButton:anObject;

@end
