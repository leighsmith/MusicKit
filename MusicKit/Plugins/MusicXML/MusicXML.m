//
//  MusicXML.m
//  MusicXML
//
//  Created by Stephen Brandon on Tue Apr 30 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import "MusicXML.h"
#import "MKXMLSAXHandler.h"

@implementation MusicXML
+ (NSString *) protocolVersion
{
    return @"1";
}

- (id)setDelegate:(id)d
{
    return self;
}

- (NSArray*)fileOpeningSuffixes
{
    return [NSArray arrayWithObjects:@"xml",@"musicxml",@"MusicXML",nil];
}

- (NSArray*)fileSavingSuffixes
{
    return nil;
}

- (MKScore*)openFileName:(NSString *)f forScore:(MKScore*)s
{
    return [MKXMLSAXHandler parseFile:f intoScore:s];
}

@end
