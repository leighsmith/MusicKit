/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLPartParser.h"
#import "MKXMLNoteParser.h"
#import <MusicKit/MusicKit.h>

@implementation MKXMLPartParser

-(void) dealloc
{
    [partID release];
    [super dealloc];
}

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"part parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"part"]) {
        NSString *asName;
        id st;

        //    MKXMLAttributeStack *attributeStack;
        partID = [[elementAttributes objectForKey:@"id"] retain];
        asName = [NSString stringWithFormat:@"Att-%@",partID];
        // is there already an attribute stack for this partname?
        st = [info->infoDict objectForKey:asName];
        if (!st) {
            attributeStack = [MKXMLAttributeStack new]; // we hold a retain as well as the infodict holding one
            [info->infoDict setObject:attributeStack forKey:asName];
        }
        else {
            attributeStack = [st retain];
        }
        // we're now the current part
        [info->currentPart release];
        info->currentPart = [partID retain];
        mkp = [info->parts objectForKey: partID];
        info->startOfNextNote = [[mkp infoNote] parAsDouble:[MKNote parTagForName:@"MKXML_beat_counter"]];
        if (MKIsNoDVal(info->startOfNextNote)) {
            info->startOfNextNote = 0;
        }
        info->startOfLastNote = info->startOfNextNote;
        return;
    }

    if ([elementName isEqualToString:@"attributes"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLAttributesParser"];
    }

    if ([elementName isEqualToString:@"backup"] ||
        [elementName isEqualToString:@"forward"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLCounterAlterationParser"];
    }

    if ([elementName isEqualToString:@"note"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLNoteParser"];
    }

    if ([elementName isEqualToString:@"direction"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLDirectionParser"];
    }
    
}


- (void) setChildData:(id)elementAttributes forKey:(id)elementName
{
    if ([elementName isEqualToString:@"attributes"]) {
        [attributeStack addAttributes:elementAttributes];
    }
    if ([elementName isEqualToString:@"direction"]) {
        // pull out certain attributes which will be useful to us
        NSMutableDictionary *s = [elementAttributes objectForKey:@"sound"];
        if (s) {
            MKNote *n = [MKNote new];
            id tempo = [s objectForKey:@"tempo"];
            id dynamics = [s objectForKey:@"dynamics"];
            if (tempo) {
                [[mkp infoNote] setPar:[MKNote parTagForName:@"MKXML_current_tempo"]
                              toDouble:[tempo doubleValue]];
                [[mkp infoNote] setPar:[MKNote parTagForName:@"MK_tempo"]
                              toDouble:[tempo doubleValue]];
                [n setPar:[MKNote parTagForName:@"MK_tempo"]
                 toDouble:[tempo doubleValue]];
            }
            if (dynamics) {
                [[mkp infoNote] setPar:[MKNote parTagForName:@"MKXML_current_dynamics"]
                                 toInt:[dynamics intValue]];
                [n setPar:MK_velocity toDouble:(double)[dynamics doubleValue] * 90.0 / 100.0f];
            }
            [n setTimeTag:info->startOfNextNote];
            [n setNoteType:MK_noteUpdate]; // should set as default for following notes
            [mkp addNote: n];
            [n release];
        }
    }
    // stick em on our local stack too, though not particularly necessary
    [super setChildData:elementAttributes forKey:elementName];
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"(part) end element name: %s\n",[elementName cString]);
#endif
    // we only get this message if THIS tag, or any tags we deal with ourselves are
    // being closed
    if ([elementName isEqualToString:@"part"]) {
#if DEBUG
        printf("Hurray - part parser got its own end tag!\n");
#endif
        // here I need to decide what to do with this (portion) of part data.
        // it's not a complete part (probably), just a measure or so.
        if (notes) {
            if (!dict) dict = [NSMutableDictionary new];
            [dict setObject:notes forKey:@"notes"];
        }

        if (dict) {
            [parent setChildData:dict forKey:partID]; //parent is likely a "measure"
        }
        
        // update the part with our current notion of where the next note would lie
        [[mkp infoNote] setPar:[MKNote parTagForName:@"MKXML_beat_counter"]
                      toDouble:info->startOfNextNote];

#if DEBUG
        NSLog(@"part has these attributes: %@ And these notes: %@\n",dict, notes);
#endif
        [self remove];
        return; // we don't care
    }
}

@end
