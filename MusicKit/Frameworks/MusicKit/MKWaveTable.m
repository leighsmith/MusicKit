/*
  $Id$
  Defined In: The MusicKit

  Description:
    MKWaveTable is an abstract class inherited by classes which produce or store
    an array of data to be used as a lookup table in a MKUnitGenerator.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-, The MusicKit Project.
*/

#import "_musickit.h"
#import "_MKParameter.h"  /* Has double to fix 24 conversion */
#import "_scorefile.h"
#import "_error.h"
#import "MKWaveTable.h"

@implementation MKWaveTable

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKWaveTable class])
      return;
    [MKWaveTable setVersion: VERSION2];//sb: suggested by Stone conversion guide (replaced self)
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving. Writes the receiver to archive file.
     Archives itself by writing its name (using MKGetObjectName()), if any.
     All other data archiving is left to the subclass. 
     */
{
    NSString *str;
    str = MKGetObjectName(self);
    [aCoder encodeValueOfObjCType:"@" at:&str];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* TYPE: Archiving. Reads the receiver from archive file.
     Archives itself by reading its name, if any, and naming the
     object using MKGetObjectName(). 
     */
{
    if ([aDecoder versionForClassName: @"MKWaveTable"] == VERSION2) {
	NSString *str;
	[aDecoder decodeValueOfObjCType: "@" at: &str];
	if (str) {
	    MKNameObject(str,self);
	}
    }
    return self;
}

- init
    /* This method is ordinarily invoked only when an 
    instance is created. 
    A subclass should send [super init] if it overrides this 
    method. */ 
{
    self = [super init];
    if (self != nil) {
	if (dataDSP) {
	    free(dataDSP);
	    dataDSP = NULL;
	}
	if (dataDouble) {
	    free(dataDouble);
	    dataDouble = NULL;
	}
	length = 0;
	scaling = 0.0;
    }
    return self;
}

- (NSUInteger) hash
{
// trivial hash
  return length;
}

- (BOOL) isEqual: (MKWaveTable*)anObject
{
    double *otherDataDouble;
    if (!anObject)                           return NO;
    if (self == anObject)                    return YES;
    if ([self class] != [anObject class])    return NO;
    if ([self hash] != [anObject hash])      return NO;
    if (scaling != [anObject scaling])       return NO;
    if (length != [anObject length])         return NO;
    // FIXME: if we ever really intend to use this class, then need
    // to compare all the underlying data points as well. The above checks
    // are just a stub for basic comparison.
    
    otherDataDouble = [anObject dataDouble];
    if (otherDataDouble == dataDouble) {
      return YES;
    }
    
    if (memcmp(dataDouble,otherDataDouble,length * sizeof(double))) {
      return NO;
    }
    return YES;
}

/* Copies the receiver, setting all cached data arrays to NULL. 
   The scaling and length are copied from the receiver. */
- copyWithZone: (NSZone *) zone
{
    MKWaveTable *newObj = (MKWaveTable *) [[MKWaveTable allocWithZone: zone] init];
    newObj->dataDSP = NULL;
    newObj->dataDouble = NULL;
    newObj->length = length;
    newObj->scaling = scaling;
    return newObj;
}

/* Frees cached data arrays then sends [super free].
 It also removes the name, if any, from the Music Kit name table. */
- (void) dealloc
{
    if (dataDSP) {
	free(dataDSP);
	dataDSP = NULL;
    }
    if (dataDouble) {
	free(dataDouble);
	dataDouble = NULL;
    }
    MKRemoveObjectName(self);
    [super dealloc];
}

- (unsigned int)length
/* Returns the length in samples of the cached data arrays.  If it is 0,
   neither the DSPDatum nor real buffer has been allocated nor computed. */
{
    return length;
}
 
- (double)scaling
/* Scaling returns the current scaling of the data buffers. A value of 0
   indicates normalization scaling. */
{
    return scaling;
}

- (DSPDatum *) dataDSPLength:(unsigned int) aLength scale: (double) aScaling
/* Returns the MKWaveTable as an array of DSPDatums, recomputing 
   the data if necessary at the requested scaling and length. If the 
   subclass has no data, returns NULL. The data should neither be modified
   nor freed by the sender. */
{
   if ((length != aLength) || (scaling != aScaling) || (length == 0))
     if (![self fillTableLength: aLength scale: aScaling])
       return NULL;
   if (!dataDSP && dataDouble) {
	_MK_MALLOC(dataDSP, DSPDatum, (unsigned int) length);
	if (!dataDSP) 
	    return NULL;
	_MKDoubleToFix24Array(dataDouble, dataDSP, (unsigned int) length);
    } 
   return dataDSP;
}

- (double *) dataDoubleLength: (unsigned int) aLength scale: (double) aScaling
/* Returns the MKWaveTable as an array of doubles, recomputing 
   the data if necessary at the requested scaling and length. If the 
   subclass has no data, returns NULL. The data should neither be modified
   nor freed by the sender. */
{  
   if ((length != aLength) || (scaling != aScaling) || (length == 0))
       if (![self fillTableLength: aLength scale: aScaling])
	   return NULL;
   if (!dataDouble && dataDSP) {
	_MK_MALLOC (dataDouble, double, (unsigned int) length);
	if (!dataDouble) 
	    return NULL;
        _MKFix24ToDoubleArray (dataDSP, dataDouble, (unsigned int) length);
    } 
    return dataDouble;
}

- fillTableLength: (int) aLength scale: (double) aScaling 
/* This method is a subclass responsibility.

   This method computes the data. It allocates or reuses either (or 
   both) of the data arrays with the specified length and fills it with data, 
   appropriately scaled. 

   If only one of the data arrays is computed, the other should be freed
   and its pointer set to NULL. If data cannot be computed, 
   nil should be returned with both arrays freed and their pointers set to 
   NULL. 
*/
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %@", NSStringFromSelector(_cmd)]; return nil;
}

- (DSPDatum *) dataDSP
/* Returns the MKWaveTable as an array of DSPDatums
   with the current length and scaling, computing the data if it has
   not been computed yet. Returns NULL if the subclass cannot compute the
   data.  You should neither alter nor free the data. */
{
    return [self dataDSPLength: (unsigned int) length scale: scaling];
}

- (double *) dataDouble
/* Returns the MKWaveTable as an array of doubles, 
   with the current length and scaling, computing the data if it has
   not been computed yet. Returns NULL if the subclass cannot compute the
   data.  You should neither alter nor free the data. */
{
    return [self dataDoubleLength: (unsigned int) length scale: scaling];
}

- (DSPDatum *)dataDSPLength:(int)aLength
/* Returns the MKWaveTable as an array of DSPDatums, recomputing 
   the data if necessary to make the array the requested length.
   Returns NULL if the subclass cannot compute the data.
   You should neither alter nor free the data. */
{
    return [self dataDSPLength:aLength scale:scaling];
}

- (double *)dataDoubleLength:(int)aLength
/* Returns the MKWaveTable as an array of doubles, recomputing 
   the data if necessary to make the array the requested length.
   Returns NULL if the subclass cannot compute the data.
   You should neither alter nor free the data. */
{
    return [self dataDoubleLength:aLength scale:scaling];
}

- (DSPDatum *)dataDSPScale:(double)aScaling
/* Returns the MKWaveTable as an array of DSPDatums, recomputing 
   the data if necessary with the requested scaling. 
   Returns NULL if the subclass cannot compute the data.
   You should neither alter nor free the data. */
{
    return [self dataDSPLength:(unsigned int)length scale:aScaling];
}

- (double *)dataDoubleScale:(double)aScaling
/* Returns the MKWaveTable as an array of doubles, recomputing 
   the data if necessary with the requested scaling.
   Returns NULL if the subclass cannot compute the data.
   You should neither alter nor free the data. */
{
    return [self dataDoubleLength:(unsigned int)length scale:aScaling];
}

@end

