//
//  MKXMLEncodingParser.m
//  XML
//
//  Created by Stephen Brandon on Wed Apr 24 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import "MKXMLEncodingParser.h"
#import <MusicKit/MusicKit.h>


@implementation MKXMLEncodingParser
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
    if ([elementName isEqualToString:@"encoding"]) {
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"encoding-date", @"encoder", @"software",
        @"encoding-description", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}

// trap anything coming up from the children that has attributes
- (void) setChildData:(id)c attributes:(id)a forKey:(id)k
{
    if ([k isEqualToString:@"encoder"]) {
        id d = [self dictForKey:@"encoders"];
        id nameArray = [self arrayFromDict:d forKey:@"names"];
        id typeArray = [self arrayFromDict:d forKey:@"types"];
        id type = [a objectForKey:@"type"];
        [nameArray addObject:(c)?c:@""];
        [typeArray addObject:(type)?type:@""];
    }
}

- (void) endElement: (NSString*)elementName
{
    if ([elementName isEqualToString:@"encoding"]) {
        id n = [MKGetNoteClass() new];
        id o;
        if ((o = [dict objectForKey:@"encoders"])) {
            [n setPar:[MKNote parTagForName:@"MK_encoders"] toObject:o];
        }
        if ((o = [dict objectForKey:@"encoding-date"])) {
            [n setPar:[MKNote parTagForName:@"MK_encoding_date"] toString:o];
        }
        if ((o = [dict objectForKey:@"encoding-description"])) {
            [n setPar:[MKNote parTagForName:@"MK_encoding_description"] toString:o];
        }
        if ((o = [dict objectForKey:@"software"])) {
            [n setPar:[MKNote parTagForName:@"MK_encoding_software"] toString:o];
        }

        [parent setChildData:n forKey:@"encoding"];
        [self remove];
        return;
    }
}

@end
