//
//  MKXMLDirectionParser.m
//  XML
//
//  Created by Stephen Brandon on Mon Apr 29 2002.
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

#import "MKXMLDirectionParser.h"
#import <MusicKit/MusicKit.h>


@implementation MKXMLDirectionParser
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
    if ([elementName isEqualToString:@"direction"]) {
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"staff", @"offset", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }

    if ([elementName isEqualToString:@"sound"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLSoundParser"];
    }
}

// trap anything coming up from the children that has attributes
- (void) setChildData:(id)c attributes:(id)a forKey:(id)k
{
    // this is redundant - sound passes things up in the main dict, not as attributes.
    if ([k isEqualToString:@"sound"]) {
    }
}

- (void) endElement: (NSString*)elementName
{
    if ([elementName isEqualToString:@"direction"]) {
//        id n = [MKGetNoteClass() new];
//        id o;

//        if ((o = [dict objectForKey:@"software"])) {
//            [n setPar:[MKNote parTagForName:@"MK_encoding_software"] toString:o];
//        }
        if (dict) {
            [parent setChildData:dict forKey:@"direction"];
        }
        [self remove];
        return;
    }
}

@end
