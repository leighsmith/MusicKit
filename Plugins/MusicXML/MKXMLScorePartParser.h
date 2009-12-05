/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLParser.h"

@interface MKXMLScorePartParser : MKXMLParser
{
//keeps the "id" attribute for the scorepart, and uses it as the key for
//the next level up dict.
  id scorepart_id;
}
@end
