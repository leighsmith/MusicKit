/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLAttributesParser.h"

@implementation MKXMLAttributesParser

-(void)dealloc
{
    [clefs release];
    [super dealloc];
}

- (void) addClef:(id)clef
{
    if (!clefs) {
        clefs = [NSMutableArray new];
    }
    if (clef) {
        [clefs addObject:clef];
    }
}

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"attributes parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"attributes"]) { //that's us - no param to do
        return;
    }
    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"divisions", @"staves", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
    
    if ([elementName isEqualToString:@"key"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLKeyParser"];
    }

    if ([elementName isEqualToString:@"time"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLTimeParser"];
    }

    if ([elementName isEqualToString:@"clef"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLClefParser"];
    }

#if DEBUG
    printf("attributes parser got sent a start tag it does not grok: %s\n",[elementName cString]);
#endif
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"(attributes) end element name: %s\n",[elementName cString]);
#endif
    if ([elementName isEqualToString:@"attributes"]) {
        if (clefs) {
            if (!dict) dict = [NSMutableDictionary new];
            [dict setObject:clefs forKey:@"clefs"];
        }
        if (dict) {
            [parent setChildData:dict forKey:@"attributes"];
        }

        [self remove];
        return;
    }
}

@end
