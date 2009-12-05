#include "FuncView.h"

#define vertclip(X) MIN(MAX((X),0),funcFrame.size.height)
#define horiclip(X) MIN(MAX((X),funcFrame.origin.x),funcFrame.origin.x + funcFrame.size.width-1)
#define tableclip(X) MIN(MAX((X),0),tableLength-1)
#define near(X) ratio * ((int) floor((X)/ratio + .45))
#define under(X) ratio * ((int) floor((X)/ratio))
#define over(X) ratio * ((int) ceil((X)/ratio))
#define BORDER 12.

#import <appkit/timer.h>

@implementation FuncView


+ newFrame:(NXRect *) frameRect
{

    FuncView *newObj = [super newFrame:frameRect];
    
// Create a border around the view where it is possible to clic without modifying the FuncTable
    newObj->frame.size.height += 2 * BORDER ;
    newObj->frame.size.width += 2* BORDER ;
    
    [newObj setFrame:&(newObj->frame)];
    
    [newObj translate:BORDER :BORDER];
    newObj->funcFrame = newObj->bounds;
    newObj->funcFrame.origin.x = 0. ;
    newObj->funcFrame.origin.y = -1. ;
    newObj->clip = newObj->funcFrame;
    newObj->clip.size.height += 1;
    newObj->tableLength = newObj->funcFrame.size.width ;
    newObj->FuncTable = (float *) calloc(newObj->tableLength,sizeof(float));
    newObj->displayMode = CONTINUOUS;
    newObj->editableFlag = YES;
    newObj->scrollable = NO;
    newObj->ratio = 1;
 
    return newObj;
   
}

-setScrollView:anObject
{
    if([anObject class] != [ScrollView class]) return self;
    scrollable = YES;
    scrollView = anObject;
    [self removeFromSuperview];
    [scrollView setDocView:self];
    [scrollView setHorizScrollerRequired:YES];
    [scrollView setBorderType:NX_LINE];
    [scrollView display];
    return self;
}
    


- drawSelf:(NXRect *) rect : (int) rectCount
{
    int i;

    NXRectClip(&clip);    
    NXEraseRect(rect);
    PSsetgray(NX_BLACK);
    
    if(displayMode == CONTINUOUS || ratio == 1)
    {
	PSmoveto(under(rect->origin.x),FuncTable[(int)(MAX(under(rect->origin.x)/ratio,0))] * 
	funcFrame.size.height);
	for(i=under(rect->origin.x);i<=over(rect->origin.x + rect->size.width);i+=ratio)
	    PSlineto((float)i,FuncTable[(int)tableclip(i/ratio)] *  funcFrame.size.height);
    }	
    else
    {
	PSmoveto(rect->origin.x-ratio,0.);
	PSlineto(rect->origin.x + rect->size.width + ratio,0.);
	for(i=under(rect->origin.x);i<=over(rect->origin.x + rect->size.width);i+=ratio)
	{
	    PSmoveto((float)i,0.);
	    PSlineto((float)i,FuncTable[(int)tableclip(i/ratio)] *
	     funcFrame.size.height);
	 }
    }
	
    PSstroke();          
    return self;
}

-mouseDown:(NXEvent *) anEvent
{
    int looping = YES;
    int i,anOffset,aLength;
    int oldMask;
    int inside;
    float xmin,xmax,ymin,ymax,dx,funcmin,funcmax;
    NXEvent *nextEvent;
    NXPoint cursor;
    NXPoint lastx;
    NXRect white;
    NXRect visible = funcFrame;
    
    if(editableFlag == NO) return self;
    oldMask = [window addToEventMask:NX_LMOUSEDRAGGEDMASK]; 
    [self  lockFocus];
    if(scrollable) [scrollView getDocVisibleRect:&visible];
    funcFrame.size.width = visible.size.width;
    funcFrame.origin.x = visible.origin.x ;
   
    NXRectClip(&clip);
    PSsetgray(NX_BLACK);
    lastx = anEvent->location;
    [self convertPoint:&lastx fromView:nil];
    
    while(looping) {
	nextEvent = [NXApp getNextEvent:(NX_LMOUSEUPMASK | NX_LMOUSEDRAGGEDMASK)];
	switch(nextEvent->type) {
	  case NX_LMOUSEUP:
	    looping = NO;
	    [self afterUp:FuncTable length:tableLength];
	    break;
	  case NX_LMOUSEDRAGGED: 
	    [self convertPoint:&nextEvent->location fromView:nil];
	    inside = NXPointInRect(&(nextEvent->location),&funcFrame);
	    cursor = nextEvent->location;
	    /* If the last and current cursors are outside the editable window, then don'd do anything! */
	    if(lastx.x != horiclip(lastx.x) && cursor.x != horiclip(cursor.x)) continue;
	    
	    if(lastx.x  - cursor.x < 0)		/* Mouse moving right */
	      {
		  xmin = near(lastx.x);
		  xmax = near(cursor.x);
		  ymin = vertclip( lastx.y);
		  ymax = vertclip( cursor.y);
	      }
	    else				/* Mouse moving left */
	      {
		  xmin = near(cursor.x);
		  xmax = near(lastx.x) ;
		  ymin = vertclip( cursor.y);
		  ymax = vertclip( lastx.y) ;
	      }
	    dx = xmax-xmin;
	    
	    white.origin.x = xmin - (ratio > 1)*ratio;
	    white.origin.y = -1.;
	    white.size.height = clip.size.height;
	    white.size.width = dx + ( (ratio > 1)? 2*ratio : .2);
	    NXEraseRect(&white);
	    
	    funcmin = FuncTable[(int)tableclip(xmin/ratio-1)]*funcFrame.size.height;		
	    funcmax = FuncTable[(int)tableclip(xmax/ratio+1)]*funcFrame.size.height;
	    
	    if(displayMode == CONTINUOUS || ratio == 1) {  
		PSmoveto(xmin-ratio, funcmin);
		for(i=(int)xmin;i<=(int)xmax;i+=ratio) {
		    float ddx = MAX(dx,1.);
		    float value;
		    if(i < 0 || i/ratio - tableLength >= 0) continue;
		    value = ymin*(1 - ((float)i-xmin)/ddx) + ymax*(((float)i-xmin)/ddx)  ;
		    FuncTable[(int)(i/ratio)] =  value / funcFrame.size.height;
		    PSlineto((float)i,value);
		}
		PSlineto(xmax+ratio, funcmax);
	    }
	    else {
		PSmoveto(xmin-ratio,funcmin);
		PSlineto(xmin-ratio, 0.);
		PSlineto(xmax+ratio, 0.);
		for(i=(int)xmin;i<=(int)xmax;i+=ratio) {
		    float ddx = MAX(dx,1.);
		    float value;
		    if(i < 0 || i/ratio - tableLength >= 0) continue;
		    value = ymin*(1 - ((float)i-xmin)/ddx) + ymax*(((float)i-xmin)/ddx)  ;
		    PSmoveto ((float)i,0.);
		    PSlineto((float)i,value);
		    FuncTable[(int)(i/ratio)] =  value / funcFrame.size.height;
		}
	    }
	    PSstroke();
	    [window flushWindow];
	    anOffset = tableclip(xmin/ratio);
	    aLength = tableclip(i/ratio-1) - anOffset+1;
	    [self afterDrag:FuncTable length:aLength offset:anOffset];
	    lastx = cursor;
	    break;
	  default: 
	    break;
	}
    }
    [window setEventMask: oldMask];
    [self  unlockFocus];
    return self;
}

-afterDrag:(float*) data length:(int)aLength offset:(int)anOffset
{
    return self;
}

- afterUp:(float*)data length:(int)aLength
{
    return self;
}

-(float*) table
{
    return FuncTable;
}

- (int) tableLength
{
    return tableLength;
}

-(int)setFuncTable:(float*)data length:(int)aLength offset:(int)anOffset
{
    int i;
    float *indTable;
    float *indData;

    indTable=FuncTable+anOffset;
    indData=data;
    for(i=0;i<MIN(aLength,tableLength-anOffset);i++)
	*(indTable++) = *(indData++);
    return (int)MIN(aLength,tableLength-anOffset);
}

-draw:sender
{
    switch(scrollable)
    {
	case YES : [scrollView display]; break;
	case NO : [self display]; break;
    }
    return self;
}

-setDisplayMode:(int)aMode
{
    if(aMode == CONTINUOUS || aMode == DISCRETE)
	displayMode = aMode;
    [self draw:self];
    return(self);
}


-(int)setTableLength:(int)aLength
{
    if(aLength > 0 && scrollable == YES)
    {
	tableLength = aLength;
    }
    if(aLength > 0 && scrollable == NO)
    {
	tableLength = (int) MIN(aLength,frame.size.width - 2*BORDER);
	ratio = (int) floor((frame.size.width - 2*BORDER) / tableLength + 0.5);
    }
    free(FuncTable);
    FuncTable = (float *) calloc(tableLength,sizeof(float));
    frame.size.width = tableLength * ratio + 2*BORDER ;
    bounds.size.width = tableLength * ratio ;
    clip.size.width = tableLength * ratio ;
    funcFrame.size.width = tableLength * ratio ;
    [superview descendantFrameChanged:self];
    return(tableLength);
}

-zoomIn:sender
{
    if(scrollable == YES)
    {
	ratio *= 2;
	frame.size.width = tableLength * ratio + 2*BORDER ;
	bounds.size.width = tableLength * ratio ;
	clip.size.width = tableLength * ratio ;
	funcFrame.size.width = tableLength * ratio ;
	[superview descendantFrameChanged:self];
	[self draw:self];
    }
    return self;
}

-zoomOut:sender
{
    if(ratio >= 2 && scrollable == YES)
    {
	ratio /= 2;
	frame.size.width = tableLength * ratio + 2*BORDER ;
	bounds.size.width = tableLength * ratio ;
	clip.size.width = tableLength * ratio ;
	funcFrame.size.width = tableLength * ratio ;
	[superview descendantFrameChanged:self];
	[self draw:self];
    }
    return self;
}

-setEditable:(BOOL)flag
{
    editableFlag = flag;
    return self;
}

@end

