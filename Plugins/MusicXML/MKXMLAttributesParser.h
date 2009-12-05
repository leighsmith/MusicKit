/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLParser.h"

@interface MKXMLAttributesParser : MKXMLParser
{
  NSMutableArray *clefs;
}

- (void) addClef:(id)aClef;

@end
