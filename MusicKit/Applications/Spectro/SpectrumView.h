/* SpectrumView.h -- Interface for SpectrumView class */

#import <AppKit/AppKit.h>

@interface SpectrumView:NSView
{
	id delegate;
	NSColor * spectrumColor;
	NSColor * cursorColor;
	NSColor * gridColor;
	int lastLength;
	int length;
	double dataFactor;			/* Number of data points per pixel */
	float *coefs;				/* The FFT coefficients */
	float *PSdata;				/* User path data */
	float *PShLineData;			/* User path data for hLines */
	float *PSvLineData;			/* User path data for vLines */
	float *PScursorData;		/* User path data for cursor */
	char *PSops;				/* User path operators */
	char *PSLineOps;			/* User path operators for lines */
	char *PScursorOps;			/* User path operators for cursor */
	int cursorPixel;			/* Cursor location (as pixel column) */
	BOOL draw;
	BOOL frames;
}

- initWithFrame:(NSRect)theFrame;
- (void)setDelegate:(id)anObject;
- delegate;
- frames:(BOOL)value;
- setDataFactor:(double)dFactor;
- (double)dataFactor;
- getCursorLocation:(float *)cursorPoint;
- setCursor:(float)cursorPoint;
- drawSpectrum:(int)npoints array:(float *)f;
- (void)drawRect:(NSRect)rects;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)event;
- setColors;

@end