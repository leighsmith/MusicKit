/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLScorePartParser.h"
#import <MusicKit/MusicKit.h>

@implementation MKXMLScorePartParser

- (void)dealloc
{
    [scorepart_id release];
    [super dealloc];
}

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
/* Note:
 * need to do "identification" as child of score-part, too. Have to think about what note tags to use
 * in that case.
 */
{
    if ([elementName isEqualToString:@"score-part"]) {
        id partid = [elementAttributes objectForKey:@"id"];
        scorepart_id = [partid retain];
        return;
    }
    
    if ([self checkForSingleValues:[NSArray arrayWithObjects: @"part-name", @"part-abbreviation",
        @"midi-device", nil] /*careful - midi-device has possible "port" attribute */
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }

    if ([elementName isEqualToString:@"score-instrument"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLScoreInstrumentParser"];
    }

    if ([elementName isEqualToString:@"midi-instrument"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLMidiInstrumentParser"];
    }
}

- (void) endElement: (NSString*)elementName
{
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"score-part"]) {
        id n = [MKGetNoteClass() new];
        MKPart *p;
        id o;
        // the parent, part-list, contains ONLY score-part objects, so we can use individual
        // (attribute) ids as we can (hopefully) always assume they are distinct.
        [parent setChildData:dict forKey:scorepart_id]; // we pass up, but it's not really important
        
        p = [MKPart part];
        if ((o = [dict objectForKey:@"part-name"])) {
            [n setPar:[MKNote parTagForName:@"MK_title"] toString:o];
        }
        if ((o = [dict objectForKey:@"part-abbreviation"])) {
            [n setPar:[MKNote parTagForName:@"MK_title_abbrev"] toString:o];
        }
        if ((o = [dict objectForKey:@"midi-device"])) {
            [n setPar:[MKNote parTagForName:@"MK_midi_device"] toString:o];
        }
        if ((o = [dict objectForKey:@"midi-instrument"])) {
            [n copyParsFrom:o];
        }

        [p setInfoNote: n]; // have to do this AFTER setting parameters - does it copy the note?
        [info->parts setObject:p forKey:scorepart_id]; // so we can cross-ref later
        [info->score addPart:p]; // add to the score proper

        
#if DEBUG
        NSLog(@"ScorePartParser closing score part: scorepart_id: %@ dict: %@", scorepart_id,dict);
#endif
        [self remove];
        return;
    }
}

@end
