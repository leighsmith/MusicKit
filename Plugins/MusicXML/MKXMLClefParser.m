/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLClefParser.h"
#import "MKXMLAttributesParser.h"

@implementation MKXMLClefParser

-(void) dealloc
{
    [clefID release];
    [super dealloc];
}

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"clef parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"clef"]) {
        clefID = [[elementAttributes objectForKey:@"number"] retain];
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"sign", @"line", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"(clef) end element name: %s\n",[elementName cString]);
#endif
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"clef"]) {
        NSMutableDictionary *c = [NSMutableDictionary dictionary];
        if (clefID) [c setObject:clefID forKey:@"clefID"];
        [c setObject:dict forKey:@"data"];
#if DEBUG
        printf("Hurray - key parser got its own end tag!\n");
#endif
        // here I need to decide what to do with this (portion) of attributes data.
        //    [parent setChildData:dict forKey:@"clef"];
        [(MKXMLAttributesParser *)parent addClef:c];
        [self remove];
        return; // we don't care
    }
}

@end
