/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLScoreInstrumentParser.h"

@implementation MKXMLScoreInstrumentParser

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
    if ([elementName isEqualToString:@"score-instrument"]) {
        // FIXME -- need to look at possible "id" attribute
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects: @"instrument-name", @"instrument-abbreviation", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}

- (void) endElement: (NSString*)elementName
{
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"score-instrument"]) {
        [parent setChildData:dict forKey:@"score-instrument"];
        [self remove];
        return; // we don't care
    }
}

@end
