//
//  MKXMLSoundParser.m
//  XML
//
//  Created by Stephen Brandon on Tue Apr 23 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

// "sound" entities can either be children of "direction", or of "measure"/"part".
// If they are children of "direction" then we leave it up to direction to add the
// data to the right place. If it's directly inside a measure or part without
// being inside a direction, then we add all data to the part (mkp) directly.
// There is a slight problem with tempo changes -- the MK does not really support
// tempo changes within a score, as it's more the domain of MKConductor and friends.
// So we stick the tags in here anyway, knowing that MK performances may not know
// what to do with them.

/*
 <!ELEMENT sound (midi-instrument*)>
 <!ATTLIST sound
   tempo CDATA #IMPLIED
   dynamics CDATA #IMPLIED
   dacapo %yes-no; #IMPLIED
   segno CDATA #IMPLIED
   dalsegno CDATA #IMPLIED
   coda CDATA #IMPLIED
   tocoda CDATA #IMPLIED
   divisions CDATA #IMPLIED   // this is apparently only for use in repeats etc, to notify
                              // of the divisions at the other end of the repeat.
   forward-repeat %yes-no; #IMPLIED
   fine CDATA #IMPLIED
   pizzicato %yes-no; #IMPLIED
 >
*/
#import "MKXMLSoundParser.h"
#import "MKXMLDirectionParser.h"
#import <MusicKit/MusicKit.h>

@implementation MKXMLSoundParser
// "sound" elements mostly have attributes, though can contain midi-instruments.
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
    if (elementAttributes && [elementName isEqualToString:@"sound"]) {
        // make sure we save all our attributes, like tempo, dynamics etc.
        // There are a bunch more that this will pick up (see direction.dtd)
        // but we're unlikely to recognise or save these in the near future.
        [self setAttributes:elementAttributes forKey:@"sound"];
        return;
    }
    if ([elementName isEqualToString:@"midi-instrument"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLMidiInstrumentParser"];
        return;
    }
}

- (void) endElement: (NSString*)elementName
{
    if ([elementName isEqualToString:@"sound"]) {
        id n = [MKGetNoteClass() new];
        MKPart *p;
        id o;
#if DEBUG
        printf("Hurray - sound parser got its own end tag!\n");
#endif
        // not really important when sound element is in part declaration, but
        // useful for when sound is part of direction.
        if (attributesDict) {
            if ([attributesDict objectForKey:@"sound"]) {
                [parent setChildData:[attributesDict objectForKey:@"sound"] forKey:@"sound"];
            }
        }

        if (![parent isKindOfClass:[MKXMLDirectionParser class]]) {
            // we add directly to part
            id attr = [attributesDict objectForKey:@"sound"];
            p = [info->parts objectForKey: info->currentPart];
            // the issue here is that I need to get the link back to the score-instrument
            // entity in order to get the midi channel (???) right. Hmmm. Ignore for now.
            if ((o = [dict objectForKey:@"midi-instrument"])) {
                [n copyParsFrom:o];
            }
            if ((o = [attr objectForKey:@"tempo"])) {
                [n setPar:MK_tempo toDouble:[o doubleValue]];
            }
            if ((o = [attr objectForKey:@"dynamics"])) {
                [n setPar:MK_velocity toDouble:(double)[o doubleValue] * 90.0 / 100.0f];
            }
            [n setTimeTag:info->startOfNextNote];
            [n setNoteType:MK_noteUpdate]; // should set as default for following notes
            [p addNote: n];
        }
        [n release];
        [self remove];
        return;
    }
}
    
@end
