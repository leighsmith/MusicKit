//
//  MusicXML.h
//  MusicXML
//
//  Created by Stephen Brandon on Tue Apr 30 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MusicKit/MKPlugin.h>

@interface MusicXML :  NSObject <MusicKitPlugin>
{
}
+ (NSString *) protocolVersion;
- setDelegate:(id)delegate;
- (NSArray*)fileSavingSuffixes;
- (NSArray*)fileOpeningSuffixes;
- (MKScore*)openFileName:(NSString *)f forScore:(MKScore*)s;

@end
