/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLTimeParser.h"

@implementation MKXMLTimeParser
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"time parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"time"]) {
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"beats", @"beat-type", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"(time) end element name: %s\n",[elementName cString]);
#endif
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"time"]) {
#if DEBUG
        printf("Hurray - key parser got its own end tag!\n");
#endif
        // here I need to decide what to do with this (portion) of attributes data.
        [parent setChildData:dict forKey:@"time"];
        [self remove];
        return; // we don't care
    }
}

@end
