/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLPartListParser.h"

@implementation MKXMLPartListParser

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
    if ([elementName isEqualToString:@"part-list"]) { //that's us - no param to do
        return;
    }
    if ([elementName isEqualToString:@"score-part"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLScorePartParser"];
    }
}

- (void) endElement: (NSString*)elementName
{
    if ([elementName isEqualToString:@"part-list"]) {
#if DEBUG
        NSLog(@"PartList closing dict: %@",dict);
#endif
        [parent setChildData:dict forKey:@"part-list"];
        [self remove];
        return;
    }
}

@end
