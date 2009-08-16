//
//  MKXMLScorePartwiseParser.m
//  XML
//
//  Created by Stephen Brandon on Tue Apr 30 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import "MKXMLScorePartwiseParser.h"
#import <MusicKit/MusicKit.h>


@implementation MKXMLScorePartwiseParser
- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"score-partwise parser got start element: %s\n",[elementName cString] );
#endif
    if ([elementName isEqualToString:@"score-timewise"]) { //that's us - no param to do
        return;
    }

    if ([self checkForSingleValues:[NSArray arrayWithObjects:@"movement-title", @"movement-number", nil]
                       elementName:elementName
                 elementAttributes:elementAttributes]) {
        return;
    }

    if ([elementName isEqualToString:@"part-list"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLPartListParser"];
    }

    if ([elementName isEqualToString:@"work"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLWorkParser"];
    }

    if ([elementName isEqualToString:@"part"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLPartParser"];
    }

    if ([elementName isEqualToString:@"identification"]) {
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLIdentificationParser"];
    }

    if ([elementName isEqualToString:@"direction"]) { //hmmm... may not need it here (try Part, Measure)
        [self passElementName:elementName elementAttributes:elementAttributes
               toChildOfClass:@"MKXMLDirectionParser"];
    }
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
    fprintf(stderr,"end element name: %s\n",[elementName cString]);
#endif
    if ([elementName isEqualToString:@"score-partwise"]) { //that's us - no param to do
        id o;
#ifdef DEBUG
# ifndef GNUSTEP
        NSLog(@"ALL INFORMATION FROM SCORE: %@",[dict descriptionInStringsFileFormat]);
        NSLog(@"ALL INFORMATION FROM infodict: %@",[info->infoDict descriptionInStringsFileFormat]);
# endif
#endif
        if ((o = [dict objectForKey:@"movement-title"])) {
            [[info->score infoNote] setPar:[MKNote parTagForName:@"MK_movement_title"] toString:o];
        }
        if ((o = [dict objectForKey:@"movement-number"])) {
            [[info->score infoNote] setPar:[MKNote parTagForName:@"MK_movement_number"] toString:o];
        }
        if ((o = [dict objectForKey:@"work"])) {
            [[info->score infoNote] copyParsFrom:o];
        }
        if ((o = [dict objectForKey:@"identification"])) {
            [[info->score infoNote] copyParsFrom:o];
        }
        NSLog(@"ALL INFORMATION FROM score object: %@",[info->score description]);

        [self remove];
        return;
    }
}

@end
