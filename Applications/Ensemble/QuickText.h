#ifndef __MK_QuickText_H___
#define __MK_QuickText_H___
#import <appkit/View.h>

/* QuickText defines a class which is capable of writing out static text
 * more quickly than the Appkit Text or TextField classes. The speed is
 * gained at a sacrifice of functionality; QuickText provides output-only,
 * non-selectable, non-editable text. The font and colors cannot be
 * changed dynamically. The text height is determined by the height of
 * the view; it cannot be changed once the view is created.
 */

#define STRLEN 32
#define BACKGROUNDGRAY  NX_LTGRAY
#define TEXTGRAY        NX_BLACK

@interface QuickText:View
{
  char str[STRLEN];
  id   font;
  float textGray;
  float backgroundGray;
  float strWidth;
}

- initFrame:(NXRect *)rect;
- (float)backgroundGray;
- setBackgroundGray:(float)aValue;
- (float)textGray;
- setTextGray:(float)aValue;
- setStringValue:(const char *)val;
- setShortValue:(short)val;
- setIntValue:(int)val;
- drawSelf:(NXRect *)rects :(int)rectCount;

@end


#endif
