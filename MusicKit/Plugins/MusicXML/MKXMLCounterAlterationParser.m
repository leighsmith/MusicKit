//
//  MKXMLCounterAlterationParser.m
//  XML
//
//  Created by Stephen Brandon on Mon Apr 22 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import "MKXMLCounterAlterationParser.h"
#import "MKXMLPartParser.h"


@implementation MKXMLCounterAlterationParser
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"counter alteration parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"forward"] ||
        [elementName isEqualToString:@"backup"]) {
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"duration", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }
}

- (void) endElement: (NSString*)elementName
{
    id dur = [dict objectForKey:@"duration"];
    int duration = [dur intValue];

    if ([elementName isEqualToString:@"forward"]) {
        if (dur) [(MKXMLPartParser*)parent forwardBy:duration];
        [self remove];
        return; // we don't care
    }

    if ([elementName isEqualToString:@"backup"]) {
        if (dur) [(MKXMLPartParser*)parent backupBy:duration];
        [self remove];
        return; // we don't care
    }
}

@end
