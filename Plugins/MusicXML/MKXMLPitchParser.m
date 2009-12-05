/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLPitchParser.h"

/*
       MusicXML definition:
       Pitch is represented as a combination of the step of the
       diatonic scale, the chromatic alteration, and the octave.
       The step element uses the English letters A through G:
       in a future revision, this could expand to international
       namings.  The alter element represents chromatic 
       alteration in number of semitones (e.g., -1 for flat,
       +1 for sharp).  The octave element is represented by the
       numbers 0 to 9, where 4 indicates the octave started by
       Middle C.
*/

@implementation MKXMLPitchParser

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"pitch parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"pitch"]) { //that's us - no param to do
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects: @"step", @"octave", @"alter", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }

    printf("pitch parser got sent a start tag it does not grok: %s\n",[elementName cString]);
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"(pitch) end element name: %s\n",[elementName cString]);
#endif
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"pitch"]) {
#if DEBUG
        printf("Hurray - pitch parser got its own end tag!\n");
#endif
        [parent setChildData:dict forKey:@"pitch"];

        [self remove];
        return; // we don't care
    }
}

@end
