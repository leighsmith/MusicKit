/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLParser.h"

@class MKNote;

@interface MKXMLNoteParser : MKXMLParser
{
}
+ (MKNote *)mknoteForDict:(NSMutableDictionary *)d currentDivisions:(int)div;

@end
