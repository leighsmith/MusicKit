/* QuickText defines a class which is capable of writing out static text
 * more quickly than the Appkit Text or TextField classes. The speed is
 * gained at a sacrifice of functionality; QuickText provides output-only,
 * non-selectable, non-editable text. The font and colors cannot be
 * changed dynamically. The text height is determined by the height of
 * the view; it cannot be changed once the view is created.
 *
 * Written by: Ali Ozer, NeXT Applications Kit Group
 */

#import "QuickText.h"

#import <dpsclient/wraps.h>  // For PSxxx functions...
#import <appkit/nextstd.h>   // For MAX
#import <appkit/Text.h>
#import <appkit/Font.h>
#import <string.h>

@implementation QuickText

- initFrame:(NXRect *)rect
{
  [super initFrame:rect];
  str[0] = 0;
  str[STRLEN-1] = 0;  
  font = [Font newFont:"Helvetica" size:11 style:0 matrix:NX_IDENTITYMATRIX];
  if (font == nil) font = [Text getDefaultFont];
  [self setClipping:NO];
  textGray = NX_BLACK;
  backgroundGray = NX_LTGRAY;
  return self;
}

- setBackgroundGray:(float)aValue
{
	backgroundGray = aValue;
	return [self display];
}

- (float)backgroundGray
{
	return backgroundGray;
}

- setTextGray:(float)aValue
{
	textGray = aValue;
	return [self display];
}

- (float)textGray
{
	return textGray;
}

- drawSelf:(NXRect *)rects :(int)rectCount
{
  [font set];
  PSsetgray (BACKGROUNDGRAY);
  NXRectFill (&bounds);
  PSsetgray (TEXTGRAY);
  PSmoveto (bounds.size.width-strWidth, 3.0);
  PSshow (str);

  return self;
}

- setStringValue:(const char *)val
{
  strncpy (str, val, STRLEN-2);
  strWidth = [font getWidthOf:str] + 2.0;
  return [self display];
}

- setIntValue:(int)val
{
  sprintf (str, "%d", val);
  strWidth = [font getWidthOf:str] + 2.0;
  return [self display];
}

- setShortValue:(short)val
{
  sprintf (str, "%d", val);
  strWidth = [font getWidthOf:str] + 2.0;
  return [self display];
}

@end

  
      
