/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:45  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_FilePerformer_H___
#define __MK_FilePerformer_H___
//sb:
#import <Foundation/Foundation.h>

#import "MKPerformer.h"

@interface MKFilePerformer : MKPerformer
{
    NSString *filename;
    double fileTime;
    id stream; /*sb: either NSMutableData or NSData */
    double firstTimeTag;
    double lastTimeTag;
    void *_reservedFilePerformer1;
}
 
- init;
- copyWithZone:(NSZone *)zone;
- setFile:(NSString *)aName;
- setStream:(id)aStream; // either NSMutableData, or NSData
-(id) stream; // either NSMutableData, or NSData
-(NSString *) file; 
- activateSelf; 
+(NSString *)fileExtension;
+(NSString **)fileExtensions;
- perform; 
- performNote:aNote; 
- nextNote; 
- initializeFile; 
- (void)deactivate; 
- finishFile; 
- setFirstTimeTag:(double)aTimeTag; 
- setLastTimeTag:(double)aTimeTag; 
-(double) firstTimeTag; 
-(double) lastTimeTag; 
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end



#endif
