/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLMeasureParser.h"
#import "MKXMLNoteParser.h"
#import "MKXMLPartParser.h"
#import <MusicKit/MusicKit.h>

@implementation MKXMLMeasureParser

-(void) dealloc
{
    [measureNum release];
    [super dealloc];
}

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"measure parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"measure"]) {
        NSString *currentPart = info->currentPart; // only relevant in partwise
        if (currentPart) {
            attributeStack = [info->infoDict objectForKey:[NSString stringWithFormat:@"Att-%@",currentPart]];
            [attributeStack retain];
        }
        measureNum = [[elementAttributes objectForKey:@"number"] retain];
        return;
    }
    if ([elementName isEqualToString:@"part"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLPartParser"];
    }
    
    if ([elementName isEqualToString:@"direction"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLDirectionParser"];
    }
}

- (void) setChildData:(id)elementAttributes forKey:(id)elementName
{
    // certain data should be handled only by parts, such as attributes
    // and directions. This will only happen in partwise scores, where
    // the parts enclose the measures.
    if (([elementName isEqualToString:@"attributes"] ||
        [elementName isEqualToString:@"direction"]) &&
        [parent isKindOfClass:[MKXMLPartParser class]])    {

        [parent setChildData:elementAttributes forKey:elementName];
    }
    // stick em on our local stack too, though not particularly necessary
    [super setChildData:elementAttributes forKey:elementName];
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"(measure) end element name: %s\n",[elementName cString]);
#endif
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"measure"]) {
#if DEBUG
        printf("Hurray - measure parser got its own end tag!\n");
#endif
        [parent setChildData:dict forKey:measureNum];
        [self remove];
        return; // we don't care
    }
    // CLEAN UP

    // nothing to do for now...
}


@end
