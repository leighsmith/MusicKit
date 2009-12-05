//
//  MKXMLIdentificationParser.m
//  XML
//
//  Created by Stephen Brandon on Wed Apr 24 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import <MusicKit/MusicKit.h>
#import "MKXMLIdentificationParser.h"

@implementation MKXMLIdentificationParser
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
    if ([elementName isEqualToString:@"identification"]) {
        return;
    }

     // need to do miscellaneous / miscellaneous-field too
    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"creator", @"rights", @"source", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }

    if ([elementName isEqualToString:@"encoding"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLEncodingParser"];
    }
}

- (void) setChildData:(id)c forKey:(id)k
{
    // avoid conflict with things being passed up to as as strings
    // in dict called rights, vs the new dict we set up with attributes,
    // with the same name. This prevents the former taking place.
    if (![k isEqualToString:@"rights"]) {
        [super setChildData:c forKey:k];
    }
}

// trap anything coming up from the children that has important attributes
- (void) setChildData:(id)c attributes:(id)a forKey:(id)k
{
    if ([k isEqualToString:@"creator"]) {
        id d = [self dictForKey:@"creators"];
        id nameArray = [self arrayFromDict:d forKey:@"names"];
        id typeArray = [self arrayFromDict:d forKey:@"types"];
        id type = [a objectForKey:@"type"];
        [nameArray addObject:(c)?c:@""];
        [typeArray addObject:(type)?type:@""];
    }
    if ([k isEqualToString:@"rights"]) {
        id d = [self dictForKey:@"rights"];
        id nameArray = [self arrayFromDict:d forKey:@"names"];
        id typeArray = [self arrayFromDict:d forKey:@"types"];
        id type = [a objectForKey:@"type"];
        [nameArray addObject:(c)?c:@""];
        [typeArray addObject:(type)?type:@""];
    }
}

- (void) endElement: (NSString*)elementName
{
    if ([elementName isEqualToString:@"identification"]) {
        id n = [MKGetNoteClass() new];
        id o;
        if ((o = [dict objectForKey:@"creators"])) { 
//            [n setPar:[MKNote parTagForName:@"MK_creators"] toObject:o];
            NSArray *names = [o objectForKey:@"names"];
            NSArray *types = [o objectForKey:@"types"];
            MKNote *n1 = [MKXMLParser noteWithParametersFromStringArray:names
                                                           withBaseName:@"MKXML_creator_name"];
            MKNote *n2 = [MKXMLParser noteWithParametersFromStringArray:types
                                                           withBaseName:@"MKXML_creator_type"];
            [n copyParsFrom:n1];
            [n copyParsFrom:n2];
        }
        if ((o = [dict objectForKey:@"rights"])) {
            NSArray *names = [o objectForKey:@"names"];
            NSArray *types = [o objectForKey:@"types"];
            MKNote *n1 = [MKXMLParser noteWithParametersFromStringArray:names
                                                           withBaseName:@"MKXML_rights_name"];
            MKNote *n2 = [MKXMLParser noteWithParametersFromStringArray:types
                                                           withBaseName:@"MKXML_rights_type"];
            [n copyParsFrom:n1];
            [n copyParsFrom:n2];

//            [n setPar:[MKNote parTagForName:@"MK_rights"] toObject:o];
        }
        if ((o = [dict objectForKey:@"source"])) {
            [n setPar:[MKNote parTagForName:@"MK_work_source"] toString:o];
        }
        if ((o = [dict objectForKey:@"encoding"])) {
            [[info->score infoNote] copyParsFrom:o];
        }
        
        [parent setChildData:n forKey:@"identification"];
        [self remove];
        return;
    }
}

@end
