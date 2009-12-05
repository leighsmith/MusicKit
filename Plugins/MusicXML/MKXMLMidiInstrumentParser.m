/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLMidiInstrumentParser.h"
#import <MusicKit/MusicKit.h>

@implementation MKXMLMidiInstrumentParser

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"midi-instrument parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"midi-instrument"]) {
        // FIXME -- need to look at possible "id" attribute
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects: @"midi-channel", @"midi-name",
        @"midi-bank", @"midi-program", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}

- (void) endElement: (NSString*)elementName
{
    if ([elementName isEqualToString:@"midi-instrument"]) {
        // here I need to decide what to do with this (portion) of attributes data.
        //[parent setChildData:dict forKey:@"midi-instrument"];

        MKNote *n = [MKGetNoteClass() new];
        id o;
        if ((o = [dict objectForKey:@"midi-channel"])) {
            [n setPar:[MKNote parTagForName:@"MK_midiChan"] toString:o];
        }
        if ((o = [dict objectForKey:@"midi-name"])) {
            [n setPar:[MKNote parTagForName:@"MK_instrumentName"] toString:o];
        }
        if ((o = [dict objectForKey:@"midi-bank"])) {
            [n setPar:[MKNote parTagForName:@"MK_midiBank"] toString:o];
        }
        if ((o = [dict objectForKey:@"midi-program"])) {
            [n setPar:[MKNote parTagForName:@"MK_programChange"] toString:o];
        }
        
        [parent setChildData:n forKey:@"midi-instrument"];

        [self remove];
        return;
    }
}

@end
