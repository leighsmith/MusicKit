#ifndef __MK_FuncView_H___
#define __MK_FuncView_H___
// FuncView implements an editable View for the display and the drawing of functions' graphs. 
// The FuncView is editable by default, but you can make it a mere display view using the 
// setEditable method with a NO argument.
// The values of the function, stored in FuncTable, must lie between 0 and 1; 
// The size of the array FuncTable is equal by default to the width of the view: If you need to use an
// FuncTable shorter than the size of the View, you must invoque the setTableLength method.
// Make sure you leave enough place around the view to make it possible to clic outside the frame 
// and yet modify the values (especially if you group the view in a Box.)
// The FuncView class makes it possible to perform actions after each received mouseDragged and
// mouseUp events by overriding the afterDrag and afterUp methods. For example, you can send
// the values that you just modified to a waveTable each time you drag the mouse.
// The FuncView class can also be used in a scroll view. To do that, you just need to create a 
// scrollView and a FuncView and use the FuncView's setScrollView method to make the 
// FuncView the scroll View's docView. With the interface builder, connect the FuncView's outlet 
// scrollView to the containing scrollView object. You can then zoom-in, zoom-out, and select the
// display mode (continuous or discrete.) 

#import <AppKit/AppKit.h>	

#define CONTINUOUS 1	// For a continuous display of the FuncTable
#define DISCRETE 0		// For a discrete display of the FuncTable (vertical lines)


@interface FuncView: NSView
{
    id scrollView;			// The optional ScrollView containing the FuncView
    NSRect clip;
    NSRect funcFrame;
    float *FuncTable;		// The array where the function's values are stored
    int displayMode;		// Flag containing the type of display
    BOOL editableFlag;	// Flag determining if the FuncView is editable or not
    BOOL scrollable;		// Flag determining if the FuncView is scrollable or not
    int ratio;
    int tableLength;		// Length of the FuncTable
}


// This method creates a new FuncView instance and sets the size of its FuncTable array to the
// width of *(frameRect). If you want to set the FuncTable to a different size, use setTableLengh.

+ newFrame:(NSRect *) frameRect;

// Use this method to connect the FuncView to a ScrollView's docView;

- setScrollView:anObject;
	
- drawSelf:(NSRect *) rect : (int) rectCount;
- mouseDown:(NSEvent *) anEvent;

// afterDrag is called by the FuncView object each time it receives a mouseDragged event; 
// The default implementation just returns self. You can override this method to perform any action
// after each mouseDragged event; Data is a pointer to the FuncTable array, aLength the length
// of the modified segment, and anOffset the location of the first modified value in the FuncTable
// array.

- afterDrag:(float*) data length:(int)aLength offset:(int)anOffset;

// afterUp is called by the FuncView object each time it receives a mouseUp event; 
// The default implementation just returns self. You can override this method to perform any action
// after each mouseUp event; Data is a pointer to the FuncTable array, and aLength is its length.

- afterUp:(float*)data length:(int)aLength;

// table returns a pointer to the FuncTable array;

- (float*) table;

// tableLength returns the size of the FuncTable array;

- (int) tableLength;

// setFuncTable sets copies aLength values from the array data to the FuncTable starting at anOffset
// It returns the number of data actually read (in case Offset+Length is larger than tableLength.)
// You must invoque the draw:sender method to make the FuncView display what you sent.

- (int)setFuncTable:(float*)data length:(int)aLength offset:(int)anOffset;

// draw sends the FuncView or the scrollView object a display:self message. 

- draw:sender;

// Use this method to select the display mode: CONTINUOUS or DISCRETE. The method doesn't 
// do anything if the FuncView object is not used in a scrollView. When the width of the View is
// equal to the length of the FuncTable array, the discrete mode is switched to continuous.

-setDisplayMode:(int)aMode;

// Use this method to set the size of the array FuncTable containing the values of the function.
// If the FuncView is used in a ScrollView, then the size of the array FuncTable is set to aLength.
// If the FuncView object is not used in a scrollView, the method returns the maximum length 
// possibly available, and sets the size of the FuncView to the nearest multiple of the FuncTable's
// size. For example, if the original size of the FuncView object was 200 and if you want to set the
// FuncTable size to 45, the FuncView object will be resized to 4*45 = 180. 

-(int)setTableLength:(int)aLength;

// This method double the current ratio (size of FuncTable / size of the View);
// It doesn't do anything if the FuncView object is not used in a scrollView.

-zoomIn:sender;

// This method halves the current ratio (size of FuncTable / size of the View);
// It doesn't do anything if the FuncView object is not used in a scrollView.

-zoomOut:sender;

// Use this method to make the FuncView object editable (flag = YES) or not (flag = NO) 
// The default mode is editable;

-setEditable:(BOOL)flag;

@end
#endif
