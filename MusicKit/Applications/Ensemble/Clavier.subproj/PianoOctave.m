/* One octave of a piano keyboard control. Drawing code by Doug Keislar. */
#import "PianoOctave.h"
#import <AppKit/AppKit.h>
//#import <dpsclient/dpsNeXT.h>
//#import <dpsclient/wraps.h>

#define HIGHLIGHTCOLOR NX_DKGRAY

enum keyRectNum {CLOW,CUP,DLOW,DUP,ELOW,EUP,FLOW,FUP,GLOW,GUP,
		   ALOW,AUP,BLOW,BUP,CSH,DSH,FSH,GSH,ASH};

static int rectToKey[] = {0,0,2,2,4,4,5,5,7,7,9,9,11,11,1,3,6,8,10};
static int keyToRect[] = {0,14,2,15,4,6,16,8,17,10,18,12};

@implementation PianoOctave

- initWithFrame:(const NSRect *)frameRect
    /* Initialize all the key rects according to the frameRect size */
{ 
    double viewWidth,viewHeight, viewX,viewY,
    lowerWhiteWidth, lowerWhiteHeight,
    CDEupperWidth, upperWhiteHeight ,FGABupperWidth,
    blackWidth,blackHeight, gap,
    upperWhiteY,blackY,whitePlusGap;

    self = [super initWithFrame:frameRect];
    viewX = bounds.origin.x;
    viewY = bounds.origin.y;
    viewWidth = bounds.size.width;
    viewHeight = bounds.size.height;
    gap = 4;  
    lowerWhiteWidth = viewWidth/7 - gap;  
    lowerWhiteHeight = viewHeight * .4;  
    whitePlusGap = lowerWhiteWidth + gap;
    blackWidth  = lowerWhiteWidth / 2.0;
    upperWhiteY = lowerWhiteHeight;
    upperWhiteHeight = viewHeight - lowerWhiteHeight;
    blackY = upperWhiteY + gap;
    blackHeight = upperWhiteHeight - gap; 
    CDEupperWidth = ((whitePlusGap*3) - gap - (blackWidth*2+gap*4))/3;  
    FGABupperWidth = ((whitePlusGap*4) - gap - (blackWidth*3+gap*6))/4; 

    keyRects[CLOW] = NSMakeRect(0, 0, lowerWhiteWidth, lowerWhiteHeight);
    keyRects[DLOW] = NSMakeRect(whitePlusGap, 0, lowerWhiteWidth, lowerWhiteHeight);
    keyRects[ELOW] = NSMakeRect(whitePlusGap * 2.0, 0, lowerWhiteWidth, lowerWhiteHeight);
    keyRects[FLOW] = NSMakeRect(whitePlusGap * 3.0, 0, lowerWhiteWidth, lowerWhiteHeight);
    keyRects[GLOW] = NSMakeRect(whitePlusGap * 4.0, 0, lowerWhiteWidth, lowerWhiteHeight);
    keyRects[ALOW] = NSMakeRect(whitePlusGap * 5.0, 0, lowerWhiteWidth, lowerWhiteHeight);
    keyRects[BLOW] = NSMakeRect(whitePlusGap * 6.0, 0, lowerWhiteWidth, lowerWhiteHeight);
    keyRects[CUP]  = NSMakeRect(0, upperWhiteY, CDEupperWidth, upperWhiteHeight);
    keyRects[CSH]  = NSMakeRect(CDEupperWidth + gap, blackY, blackWidth, blackHeight);
    keyRects[DUP]  = NSMakeRect(CDEupperWidth + gap *2 + blackWidth, upperWhiteY, CDEupperWidth, upperWhiteHeight);
    keyRects[DSH]  = NSMakeRect(CDEupperWidth * 2 + gap * 3 + blackWidth, blackY, blackWidth, blackHeight);
    keyRects[EUP]  = NSMakeRect(viewWidth * 3/7 - CDEupperWidth - gap, upperWhiteY, CDEupperWidth, upperWhiteHeight);
    keyRects[FUP]  = NSMakeRect(whitePlusGap * 3.0, upperWhiteY, FGABupperWidth, upperWhiteHeight);
    keyRects[FSH]  = NSMakeRect(whitePlusGap * 3.0 + FGABupperWidth + gap, blackY, blackWidth, blackHeight);
    keyRects[GUP]  = NSMakeRect(whitePlusGap * 3.0 + FGABupperWidth + gap*2+blackWidth, upperWhiteY, FGABupperWidth, upperWhiteHeight);
    keyRects[GSH]  = NSMakeRect(whitePlusGap * 3.0 + FGABupperWidth * 2 + gap * 3 + blackWidth, blackY, blackWidth, blackHeight);
    keyRects[AUP]  = NSMakeRect(viewWidth - (FGABupperWidth * 2 + gap * 3 + blackWidth), upperWhiteY, FGABupperWidth, upperWhiteHeight);
    keyRects[ASH]  = NSMakeRect(viewWidth - (FGABupperWidth + gap * 2 + blackWidth), blackY, blackWidth, blackHeight);
    keyRects[BUP]  = NSMakeRect(viewWidth - (FGABupperWidth + gap), upperWhiteY, FGABupperWidth, upperWhiteHeight);
    value = -1;

    return self;
}

- drawSelf:(const NSRect *)rects :(int)rectCount
  /* doesn't call drawKey, since the latter sets lockFocus etc. */
{
    PSsetgray(NX_WHITE);
    NSRectFillList(&keyRects[CLOW],14);
    PSsetgray(NX_BLACK);
    NSRectFillList(&keyRects[CSH],5);

    return self;
}

- setKey:(int) keyNum toState:(int)state
    /* Programmatically set the state of a particular key */
{   
    int rectNum;

    if (keyNum < 0 || keyNum > 11) return self;
    rectNum= keyToRect[keyNum];
    keyStates[keyNum] = state;
    [self lockFocus];
    if (rectNum < 14) {
	PSsetgray(state? HIGHLIGHTCOLOR: NX_WHITE);
	NSRectFillList(&keyRects[rectNum],2);
    }
    else {
	PSsetgray(state? HIGHLIGHTCOLOR: NX_BLACK);
	NSRectFill(&keyRects[rectNum]);
    }
    [self unlockFocus];
    [window flushWindow];

    return self;
}

- (void) mouseDown: (NSEvent *) event
    /* Find the key rect in which the cursor is located, and send a message
     * to the target.
     */
{
    int i;

    [self convertPoint:&(event->location) fromView:nil];
    for (i=0; i<19; i++)
      if (NSPointInRect(&(event->location),&keyRects[i])) {
	  value = rectToKey[i];
	  [self setKey:value toState:!keyStates[value]];
	  [self sendAction:action to:target];
	  break;
      }

    return self;
} 

- (void) mouseUp: (NSEvent *) event
    /* Send a message to the target when the mouse button goes up as well */
{
    if (keyStates[value] && !(event->flags & NX_COMMANDMASK)) {
	[self setKey:value toState:0];
	[self sendAction:action to:target];
    }

    return self;
}

- (BOOL) acceptsFirstMouse;
{
    return(YES);
}     

- (int)intValue
{
    return value;
}

- setTarget:anObject
{
    target = anObject;

    return self;
}

- setAction:(SEL)aSelector
{
    action = aSelector;

    return self;
}

- (int)state:(int)keyNum
{
    return keyStates[keyNum];
}

@end
  

