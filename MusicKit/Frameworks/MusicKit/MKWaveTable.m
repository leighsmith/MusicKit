#ifdef SHLIB
#include "shlib.h"
#endif

/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.7  2002/04/15 14:25:03  sbrandon
  - added -hash and -isEqual: methods to aid in situations where object is
    used as a key in dictionaries or maptables.

  Revision 1.6  2002/04/03 03:59:41  skotmcdonald
  Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

  Revision 1.5  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2001/08/07 16:10:32  leighsmith
  Corrected class name during en/decode to match latest MK prefixed name

  Revision 1.3  2001/07/02 16:52:20  sbrandon
  - replaced sel_getName with NSStringFromSelector (hopefully more OpenStep
    compliant)

  Revision 1.2  1999/07/29 01:16:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/27/90/daj - Changed to zone API.
  06/29/98/sb - changed length to unsigned int. Hope compares still work.
*/

#import "_musickit.h"
#import "_MKParameter.h"  /* Has double to fix 24 conversion */
#import "_scorefile.h"
#import "_error.h"
#import "MKWaveTable.h"

@implementation MKWaveTable : NSObject
/* MKWaveTable is an abstract class inherited by classes which produce or store 
   an array of data to be used as a lookup table in a MKUnitGenerator.
   Subclasses provided by the Music Kit are

   * * MKPartials computes a MKWaveTable given an arrays of harmonic amplitudes, 
   frequency ratios, and phases.

   * * MKSamples stores a MKWaveTable of existing samples read in from a Sound 
   object or soundfile.

   The MKWaveTable class caches multiple formats for the data. This is
   usefuly because it is expensive to recompute the data.
   Access to the data is through one of the "data" methods (-dataDSP, 
   -dataDouble, etc.).  The method
   used depends on the data type needed (type DSPDatum for the DSP
   or type double), the scaling needed, and the length of the array needed.
   The caller should not free nor alter the array of data.

   If necessary, the subclass is called upon to recompute the data.
   The computation of the data is handled by the subclass method 
   fillTableLength:scale:.
*/
{
    unsigned int length;	         /* Non-0 if a data table exists, 0 otherwise */
    double scaling;      /* Scaling or 0.0 for normalization. */
    DSPDatum *dataDSP;   /* Computed DSPDatum data */
    double *dataDouble;  /* Computed double data */
    void *_reservedWaveTable1;
}

+  new
  /* This is how you make up an empty seg envelope */
{
    self = [super allocWithZone:NSDefaultMallocZone()];
    [self init];
//    [self initialize]; /* Avoid breaking pre-2.0 apps. */
    return self;
}


#define VERSION2 2

+ (void)initialize
{
    if (self != [MKWaveTable class])
      return;
    [MKWaveTable setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
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

#if 0
- (void)initialize 
  /* For backwards compatibility */
{ 
    
} 
#endif

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

- (unsigned) hash
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

- copyWithZone:(NSZone *)zone
  /* Copies the receiver, setting all cached data arrays to NULL. 
     The scaling and length are copied from the receiver. */
{
    MKWaveTable *newObj = NSCopyObject(self, 0, zone);
    newObj->dataDSP = NULL;
    newObj->dataDouble = NULL;
    return newObj;
}

- copy
{
    return [self copyWithZone:[self zone]];
}

- (void)dealloc
/* Frees cached data arrays then sends [super free].
   It also removes the name, if any, from the Music Kit name table. */
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

- (DSPDatum *)dataDSPLength:(int)aLength scale:(double)aScaling
/* Returns the MKWaveTable as an array of DSPDatums, recomputing 
   the data if necessary at the requested scaling and length. If the 
   subclass has no data, returns NULL. The data should neither be modified
   nor freed by the sender. */
{
   if (((unsigned int)length != (int)aLength) || (scaling != aScaling) || (length == 0))
     if (![self fillTableLength:aLength scale:aScaling])
       return NULL;
   if (!dataDSP && dataDouble) {
	_MK_MALLOC(dataDSP, DSPDatum, (unsigned int)length);
	if (!dataDSP) return NULL;
	_MKDoubleToFix24Array (dataDouble, dataDSP, (unsigned int)length);
	} 
   return dataDSP;
}

- (double *)dataDoubleLength:(int)aLength scale:(double)aScaling
/* Returns the MKWaveTable as an array of doubles, recomputing 
   the data if necessary at the requested scaling and length. If the 
   subclass has no data, returns NULL. The data should neither be modified
   nor freed by the sender. */
{  
   if (((unsigned int)length != (int)aLength) || (scaling != aScaling) || (length == 0))
     if (![self fillTableLength:aLength scale:aScaling])
       return NULL;
   if (!dataDouble && dataDSP) {
	_MK_MALLOC (dataDouble, double, (unsigned int)length);
	if (!dataDouble) return NULL;
        _MKFix24ToDoubleArray (dataDSP, dataDouble, (unsigned int)length);
	} 
   return dataDouble;
}

- fillTableLength:(int)aLength scale:(double)aScaling 
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
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", NSStringFromSelector(_cmd)]; return nil;
}

- (DSPDatum *)dataDSP
/* Returns the MKWaveTable as an array of DSPDatums
   with the current length and scaling, computing the data if it has
   not been computed yet. Returns NULL if the subclass cannot compute the
   data.  You should neither alter nor free the data. */
{
    return [self dataDSPLength:(unsigned int)length scale:scaling];
}

- (double *)dataDouble
/* Returns the MKWaveTable as an array of doubles, 
   with the current length and scaling, computing the data if it has
   not been computed yet. Returns NULL if the subclass cannot compute the
   data.  You should neither alter nor free the data. */
{
    return [self dataDoubleLength:(unsigned int)length scale:scaling];
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

