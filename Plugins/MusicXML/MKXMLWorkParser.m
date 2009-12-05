/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLWorkParser.h"
#import <MusicKit/MusicKit.h>

@implementation MKXMLWorkParser

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"work parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"work"]) {
        return;
    }

    // careful -- opus can have "link-attributes" attribute
    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"work-number", @"work-title", @"opus", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}

- (void) endElement: (NSString*)elementName
{
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"work"]) {
        MKNote *n = [MKGetNoteClass() new];
        id o;
        if ((o = [dict objectForKey:@"work-title"])) {
            [n setPar:[MKNote parTagForName:@"MK_title"] toString:o];
        }
        if ((o = [dict objectForKey:@"opus"])) {   //FIXME - what about "link-attributes" attribute
            [n setPar:[MKNote parTagForName:@"MK_opus"] toString:o];
        }
        if ((o = [dict objectForKey:@"work-number"])) {
            [n setPar:[MKNote parTagForName:@"MK_title_number"] toString:o];
        }
        
        [parent setChildData:n forKey:@"work"];
#if DEBUG
        NSLog(@"Finished getting work info: %@",dict);
#endif
        [self remove];
        return; // we don't care
    }
}

@end
