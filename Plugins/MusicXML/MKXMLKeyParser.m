/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLKeyParser.h"

@implementation MKXMLKeyParser
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"key parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"key"]) {
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects: @"fifths", @"mode", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}
- (void) endElement: (NSString*)elementName
{
    if ([elementName isEqualToString:@"key"]) {
#if DEBUG
        printf("Hurray - key parser got its own end tag!\n");
#endif
        // here I need to decide what to do with this (portion) of attributes data.
        [parent setChildData:dict forKey:@"key"];
        [self remove];
        return; // we don't care
    }
}

@end
