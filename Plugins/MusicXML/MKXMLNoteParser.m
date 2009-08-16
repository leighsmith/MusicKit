/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import "MKXMLNoteParser.h"
#import "MKXMLPartParser.h"
#import "MKXMLMeasureParser.h"

@implementation MKXMLNoteParser

+ (int) keyNumForDict:(NSDictionary *)d
{
    NSString *step =   [[d objectForKey:@"step"] lowercaseString];
    NSString *octave = [d objectForKey:@"octave"];
    NSString *alter =  [d objectForKey:@"alter"];
    char s;
    int k;
    int oct;
    if (!step) return 0;
    if ([step length] != 1) return 0;
    s = ((char *)[step cString])[0];
    switch (s) {
        case 'c':
        default:
            k = 0; break;
        case 'd':
            k = 2; break;
        case 'e':
            k = 4; break;
        case 'f':
            k = 5; break;
        case 'g':
            k = 7; break;
        case 'a':
            k = 9 ; break;
        case 'b':
            k = 11; break;
    }
    if ([octave isEqualToString:@"00"]) {
        oct = -1;
    }
    else {
        oct = [octave intValue];
    }
    k += (oct + 1) * 12;
    k += [alter intValue];
    return k;
}

+ (MKNote *)mknoteForDict:(NSMutableDictionary *)d currentDivisions:(int)div
{
    MKNote *n = nil;
    id p;
    double duration;
    if (!div) div = 1;
    n = [[MKNote alloc] initWithTimeTag:[[d objectForKey:@"start_counter"] doubleValue]];
    duration = (double)[[d objectForKey:@"duration"] intValue] / div;
    if ([d objectForKey:@"rest"]) {
        [n setNoteType:MK_mute];
        [n setPar:MK_restDur toDouble:duration];
    }
    else {
        [n setNoteType:MK_noteDur];
        [n setDur:duration];
    }
    if ((p = [d objectForKey:@"dynamics"])) {
        [n setPar:MK_velocity toDouble:(double)[p intValue] * 90.0 / 100.0f];
    }
    if ((p = [d objectForKey:@"end-dynamics"])) {
        [n setPar:MK_relVelocity toDouble:(double)[p intValue] * 90.0 / 100.0f];
    }
    if ((p = [d objectForKey:@"attack"])) {
        [n setPar:MK_amp0 toDouble:0];
        [n setPar:MK_ampAtt toDouble:(double)[p intValue] / div];
        if ((p = [d objectForKey:@"dynamics"])) {
            // dynamics is percentage of standard velocity of 90, out of max
            // midi velocity of 127.
            [n setPar:MK_amp1 toDouble:(double)[p intValue] * 90 / 127 / 100];
        }
    }
    if ((p = [d objectForKey:@"pitch"])) {
        id o;
        [n setPar:MK_keyNum toDouble:[MKXMLNoteParser keyNumForDict:p]];
        if ((o = [p objectForKey:@"alter"])) {
            [n setPar:[MKNote parTagForName:@"MK_chromatic_alteration"]
             toString:o];
        }
        if ((o = [p objectForKey:@"octave"])) {
            [n setPar:[MKNote parTagForName:@"MK_octave"]
             toString:o];
        }
        if ((o = [p objectForKey:@"step"])) {
            [n setPar:[MKNote parTagForName:@"MK_key_letter"]
             toString:o];
        }
//        [n setPar:[MKNote parTagForName:@"MK_XMLkeyNum"] toObject:p];
    }
    [n setNoteTag:MKNoteTag()];
    return [n autorelease];
}


// note itself has attributes: position, printout, dynamics, end-dynamics,
// attack, pizzicato
// where dynamics and end-dynamics are the MIDI attack and release velocities,
// position is a combination of default-x=, default-y=, relative-x=, and relative-y=
//   where the values are in tenths of inter-line spacing
// printout is a combination of print-object=bool, print-dot=bool, print-spacing=bool
// The attack attribute is used to alter the onset time of the note from when it would
//    otherwise occur based on the flow of durations (measured in "divisions").
// pizzicato=bool and refers not to the graphical look, but the actual sound of the note.

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"note parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"note"]) {
        if (!dict) dict = [[NSMutableDictionary dictionary] retain];
        // this will mix in attributes passed up from sub elements (eg duration, type etc)
        // with the attributes specified for the note itself - but I don't think they will clash,
        // and they are conceptually the same as far as we are concerned here.
        [dict addEntriesFromDictionary:elementAttributes];
        return;
    }

    // accidental has attr; cautionary (bool), editorial (bool)
    // accidental has possible vals: sharp, natural, flat, double-sharp, sharp-sharp, flat-flat,
    //    natural-sharp, natural-flat, quarter-flat, quarter-sharp, three-quarters-flat, and
    //    three-quarters-sharp
    // duration has attr: none
    // duration has possible vals: PCDATA
    // type has attr: size=(full|cue)  (editorial; cue is for grace notes etc)
    // type has possible vals: PCDATA   (the graphic note type, from the long
    //    through 256th notes (eg whole, quarter, eighth etc, I assume but don't know).

    [self checkForSingleValues:[NSArray arrayWithObjects:@"duration",@"chord",@"rest",@"voice",
        @"type",@"dot",@"stem",@"staff",@"accidental",nil]
                   elementName:elementName
             elementAttributes:elementAttributes];

    if ([elementName isEqualToString:@"pitch"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLPitchParser"];
    }
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"(note) end element name: %s\n",[elementName cString]);
#endif

    if ([elementName isEqualToString:@"note"]) {

#if DEBUG
        printf("Hurray - note parser got its own end tag!\n");
#endif

        if ([dict objectForKey:@"chord"]) {
            [dict setObject:[NSNumber numberWithDouble:info->startOfLastNote]
                     forKey:@"start_counter"];
        }
        else {
            [dict setObject:[NSNumber numberWithDouble:info->startOfNextNote]
                     forKey:@"start_counter"];
        }

        [(MKXMLPartParser *)parent addNote:dict];

        [self remove];
        return; // we don't care
    }
}

@end
