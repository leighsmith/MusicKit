#ifndef __MK_FileWriter_H___
#define __MK_FileWriter_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  MKFileWriter.h
  DEFINED IN: The Music Kit
*/

//sb:
#import <Foundation/Foundation.h>

#import "MKInstrument.h"
#import "timeunits.h"

@interface MKFileWriter : MKInstrument
{
    MKTimeUnit timeUnit;
    NSMutableString *filename;
    NSMutableData *stream;
    double timeShift;
    BOOL compensatesDeltaT;
    int _fd;
}
 
- init; 
-setTimeUnit:(MKTimeUnit)aTimeUnit;
-(MKTimeUnit)timeUnit;
+(NSString *)fileExtension;
-(NSString *)fileExtension;
- setFile:(NSString *)aName; 
- setStream:(NSMutableData *)aStream; 
- (NSMutableData *) stream; 
- copyWithZone:(NSZone *)zone; 
- (NSString *) file; 
- finishFile; 
- initializeFile; 
- firstNote:aNote; 
- afterPerformance; 
- (double)timeShift;
- setTimeShift:(double)timeShift;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end



#endif
