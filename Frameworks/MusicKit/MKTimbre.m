/*
  $Id$
  Defined In: The MusicKit

  Description:
    See MKTimbre.h

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
Modification history:

  $Log$
  Revision 1.10  2005/04/15 04:18:25  leighsmith
  Cleaned up for gcc 4.0's more stringent checking of ObjC types

  Revision 1.9  2004/12/06 18:27:37  leighsmith
  Renamed _MKErrorf() to meaningful MKErrorCode(), now void, rather than returning id

  Revision 1.8  2002/04/03 03:59:41  skotmcdonald
  Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

  Revision 1.7  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.6  2001/08/07 16:11:52  leighsmith
  Corrected class name during decode to match latest MK prefixed name

  Revision 1.5  2000/11/25 22:39:30  leigh
  Removed redundant -freeSelfOnly and release

  Revision 1.4  2000/06/27 18:08:41  leigh
  Converted hashtable into a NSDictionary timbreDictionary

  Revision 1.3  2000/04/25 22:07:25  leigh
  Doco cleanup

  Revision 1.2  1999/07/29 01:16:43  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/22/89/daj - Changed _MKNameTableAddNameNoCopy() call to conform
  with changes to _MKNameTable. Added init of hashtable to 
  nil.
  09/22/89/daj - Changed synth definition to have const data.
  10/15/89/daj - Changed to use HashTable instead of _MKNameTable (because
  of changes to the latter. Also, added some optimizations.
  04/23/90/daj - Changed to partialsDB.m (made it no longer a class).
  07/24/90/daj - Changed sscanf to atoi to support separate-threaded Music Kit
  performance.
  08/17/90/daj - Changed to use new float/int format MKPartials objects. It saves
                 300K in the size of libmusic and in vmem space. Also changed 
                 to use MKGetPartialsClass(). I experimented with more radical
                 changes: Initializing of data base could be made lazy, but
		 it would only make a 40 or 50K difference at most. Harmonic
		 number arrays could be made into ranges, but this would only
		 save about 75K at most. Short arrays could be made into 
		 unsigned char arrays but that would only save about 50K.
		 These are small wins compared with 300K, so I'm calling it
		 a day.  Note, however, that a lot of ugly hacking was done
		 to MKPartials to accomodate this change.  MKPartials should be
		 cleaned up (and the data base made public) in a future 
		 release. Made nameStr not static -- there's no need for it 
		 to be.

  03/02/91/daj - Added public data base support; moved to musickit_proj.
  05/06/91/daj - Created MKTimbre.m from other version.
  07/12/91/daj - Changed waveTableForFreq to interpret frequencies as center
                 frequencies.
  08/22/91/daj - Changed to new Storage API.
  09/31/92/daj - Changed "name" method to "timbreName", to avoid conflict with
                 Object. Changed "setName:" to "setTimbreName:" for consistancy
  11/17/92/daj - Small changes to shut up compiler warnings. Fixed bug in -empty.
 */

#import <Foundation/NSArray.h>
#import "_musickit.h"
#import "_error.h"
#import <string.h>
#import <stdlib.h>
#import <ctype.h>

@implementation MKTimbre

#define VERSION3 3

static NSMutableDictionary *timbreDictionary = nil;

struct synth {
    const double frq;
    const int numharms;
    const short * const hrms;
    const float * const amps; };

#import "partialsDBInclude.m"

static MKTimbre *newNeXTTimbre(NSString *newName,int count)
    /* We don't use newTimbre: because we want to go as fast as possible
       and we can omit some checks -- also, we know in advance how
       many WaveTables we have. */
{
    MKTimbre *timbre = [MKTimbre alloc];
    /* init by hand */
    timbre->waveTables = [[NSMutableArray arrayWithCapacity:count] retain];
/*    timbre->freqs = [Storage newCount:count
		   elementSize:sizeof(double) description:"d"];
 */
    timbre->freqs = [[NSMutableArray arrayWithCapacity:count] retain];
    [timbre->freqs removeAllObjects];  /* Necessary! */
    /* No need to make the timbreName kosher -- we know it's ok. */
    timbre->timbreName = [newName retain];
    [timbreDictionary setObject: timbre forKey: timbre->timbreName];
    return (MKTimbre *)timbre;
}

static void initNeXTTimbres(void)
    /* Creates a set of MKPartials objects which contain the spectra of analyzed
       voices and instruments. Created by Michael McNabb.  We may want to 
       put these in a file instead of having them in memory. */
{
    int i, j;
    id p,partialsClass;
    MKTimbre *timbre;
    IMP setAll,addObj; 
    struct synth *s, **ss;
    partialsClass = MKGetPartialsClass();
    setAll = [partialsClass instanceMethodForSelector:@selector(_setPartialNoCopyCount:freqRatios:ampRatios:
		      phases:orDefaultPhase:)];  
    addObj = [MKTimbre instanceMethodForSelector:@selector(addWaveTable:forFreq:)];  
    for (i=0; i<NUMTIMBRES; i++) {
	timbre = newNeXTTimbre(mmm_table_names[i],mmm_table_lens[i]);
	ss = (struct synth **)mmm_tables[i];
	for (j=0; j<mmm_table_lens[i]; j++) {
	    p = [partialsClass new];
	    s = ss[j];
	    (*setAll)(p,
		      @selector(_setPartialNoCopyCount:freqRatios:ampRatios:
			      phases:orDefaultPharse:),
		      (int) s->numharms,
		      (int *) s->hrms,
		      (float *) s->amps,
		      NULL,0.0);
	    (*addObj)(timbre,@selector(addWaveTable:forFreq:),p,
		      (double)s->frq);
	}
    }
}

static void initHashTable(void)
{
    timbreDictionary = [[NSMutableDictionary dictionaryWithCapacity: NUMTIMBRES] retain];
    initNeXTTimbres();
}

+ (void)initialize
{
    if (!timbreDictionary)
	initHashTable();
    return;
}

#define NONE 0
#define BAD -1
#define PREFIX_OR_SUFFIX 1

#if 0
/* sbrandon: re-did the following */
static int getPureName(char *originalName,
		       char *pureName,
		       int *prefixVal,
		       int *suffixVal)
    /* Searches str for a number. Returns NONE if no number, BAD, if 
       there's a problem, else OK.

       If there is a number, copies that portion of the name that doesn't
       have numbers to nameString.  Sets prefixNum
       */
{
    /* Note: sscanf cannot be used here because it is thread-unsafe. */
    int rtn = NONE;
    int len = strlen(originalName);
    int prefixLen,rootLen;
    char *p;
    if (!len)
      return BAD;
    for (prefixLen = 0, p = originalName; *p && isdigit(*p); p++, prefixLen++);
    if (prefixLen) {  /* We've got a number prefix */
	*prefixVal = atoi((const char *)(originalName));
	originalName += prefixLen;
	rtn = PREFIX_OR_SUFFIX;
    } else *prefixVal = 1; /* Freq1 is the default */
    rootLen = strcspn(originalName,"0123456789"); /* Length up to suffix */
    if (rootLen < len) {                      /* We've got a numbered suffix */
	*suffixVal = atoi((const char *)(originalName + rootLen));
	rtn = PREFIX_OR_SUFFIX;
    } else *suffixVal = 0;
    if (rtn == PREFIX_OR_SUFFIX) {
	if (rootLen >= MK_MAXTIMBRENAMELEN)
	  return BAD;
	strncpy(pureName,originalName,rootLen);
	pureName[rootLen] = '\0';
    }
    return rtn;
}
#endif

static int getPureName(NSString *originalName,
                       NSString **pureName,
                       int *prefixVal,
                       int *suffixVal)
    /* Searches str for a number. Returns NONE if no number, BAD, if
       there's a problem, else OK.

       If there is a number, copies that portion of the name that doesn't
       have numbers to nameString.  Sets prefixNum
       */
{
    /* Note: sscanf cannot be used here because it is thread-unsafe. */
    int rtn = NONE;
    int len = [originalName length];

    NSScanner *theScanner = [NSScanner scannerWithString:originalName];
    if (!len)
      return BAD;

    if (![theScanner scanInt:prefixVal]) *prefixVal = 1;
    else rtn = PREFIX_OR_SUFFIX;
    [theScanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:pureName];
    if (![theScanner scanInt:suffixVal]) *suffixVal = 0;
    else rtn = PREFIX_OR_SUFFIX;

    if ([*pureName length] > MK_MAXTIMBRENAMELEN)
        return BAD;

    return rtn;
}

static MKWaveTable *waveTableForIndex(MKTimbre *timbre,
				    int index)
    /* The index here is 0-based! */
{
    NSMutableArray *list = timbre->waveTables;
    int count = [list count];
    if (!timbre->waveTables)
	return nil;
    if (index < 0) 
	return nil;
    if (index >= count) 
	return nil;

    return (MKWaveTable *)[[[list objectAtIndex:index] retain] autorelease]; //sb: was (NX_ADDRESS(list)[index]);
}

static MKWaveTable *waveTableForFreq(MKTimbre *timbre,
				   double freq)
{
//    NXStorageId *freqStorage = (NXStorageId *)timbre->freqs;
//    unsigned int freqStorage = 0;
    NSMutableArray *list;
//    double *d;
    int count, i;
    if (!timbre->freqs || !timbre->waveTables)
	return nil;
    list = timbre->waveTables;
    count = [list count];
    if (count == 0) 
	return nil;
    for (i = 0; i < count; i++) /* i=0; d = (double *)(freqStorage->dataPtr) ... i++, d++*/
//	if (*d >= freq) { /* We've passed it */
	if ([[timbre->freqs objectAtIndex:i] floatValue] >= freq) { /* We've passed it */ 
	    if (i == 0)   /* Requested freq is below lowest freq */
		return [list objectAtIndex:0];
	    else {
                double nextF = [[timbre->freqs objectAtIndex:i] floatValue];
                double lastF = [[timbre->freqs objectAtIndex:i-1] floatValue]; 
		BOOL upper = (nextF/freq) < (freq/lastF);
		return [list objectAtIndex:upper ? i : i-1];
	    }
	}
    return [list objectAtIndex:count-1];
}

- (void)removeAllObjects
{
    NSString *s = [timbreName retain];
    [self init];
    [(timbreName = s) release];
    return;
}

- (void)dealloc
{
  [timbreDictionary removeObjectForKey: timbreName];
  if (waveTables != nil) {
    [waveTables removeAllObjects];
    [waveTables release];
    waveTables = nil;
  }
  if (freqs != nil) {
    [freqs release];
    freqs = nil;
  }
  [super dealloc];
}

- copyWithZone:(NSZone *)zone
    /* Copies object.   Sets timbreName to "".  Doesn't install on global table. */ 
{
    MKTimbre *newObj = [[MKTimbre alloc] init];
    newObj->freqs = [freqs copyWithZone:zone];
    newObj->waveTables = [waveTables copyWithZone:zone];
    newObj->timbreName = @"";
    return newObj;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

-init
{
  self = [super init];
  if (self != nil) {
    
    if (timbreName)
      [timbreDictionary removeObjectForKey: timbreName];
    if (waveTables) {
      [waveTables release];
      waveTables = nil;
    }
    if (freqs) {
      [freqs release];
      freqs = nil;
    }
    waveTables = [[NSMutableArray allocWithZone:[self zone]] init];
    freqs = [[NSMutableArray allocWithZone:[self zone]] init];
    /*    freqs = [Storage newCount:0 elementSize:sizeof(double)
description:"d"];
 */
    timbreName = NULL;
  }
  return self;
}

+newTimbre:(NSString *)newTimbreName;
{
    int suffixVal,prefixVal;
    NSString *pureName;
    MKTimbre *obj;
    if (!timbreDictionary)
      initHashTable();
    if (!newTimbreName)
	return [[self alloc] init];
    if (getPureName(newTimbreName,&pureName,&prefixVal,&suffixVal) == BAD)
	return nil;                                  /* No hope */
    obj = (MKTimbre *) [timbreDictionary objectForKey: pureName];
    if (obj)
	return obj;
    obj = [[self alloc] init];
    obj->timbreName = [pureName retain];
    [timbreDictionary setObject: obj forKey: obj->timbreName];
    return obj;
}

-addWaveTable:(MKWaveTable *)aWaveTable forFreq:(double)freq
{
    int i;
    int count;
//    double *d;
//    id *wt; //sb: seemed to be unused
//    NXStorageId *freqStorage = (NXStorageId *)freqs;
    count = [waveTables count];
    if (!freqs || !waveTables) {
	/* Should never happen */
	return nil;
    }
//    d = (double *)(freqStorage->dataPtr); 

//    wt = NX_ADDRESS(waveTables);
    for (i = 0; i < count;/* d++, */ i++ /*, wt++  */)
//	if (*d >= freq) {
	if ([[freqs objectAtIndex:i] floatValue] >= freq) {
	    [waveTables insertObject:aWaveTable atIndex:i];
            [freqs insertObject:[NSNumber numberWithFloat:freq] atIndex:i];
	    return self;
	}
    [waveTables addObject:aWaveTable];
    [freqs addObject:[NSNumber numberWithFloat:freq]];
    return self;
}

-removeWaveTable:(MKWaveTable *)aWaveTable
{
    int i;
    i = [waveTables indexOfObject:aWaveTable];
    if (i != NSNotFound) {
	[waveTables removeObjectAtIndex:i];
        [freqs removeObjectAtIndex:i];
	return self;
    } 
    return nil;
}

+ (NSDictionary *) timbres
  /* Returns the NSDictionary object containing all timbres. Each timbre is  
     represented as a NSDictionary entry mapping an NSString to a NSArray of
     waveTables.  The NSDictionary is not copied and should not be freed (since it
     is autoreleased). It may be altered providing that a performance is not in progress. */
{
    if (!timbreDictionary)
      initHashTable();
    return [timbreDictionary autorelease];
}

-setTimbreName:(NSString *)newName
{
    MKTimbre *obj;
    int suffixVal,prefixVal;
    NSString *pureName;
    NSString *uniqueStr;
    if (timbreName)
	[timbreDictionary removeObjectForKey: timbreName];
    if (!newName) {
	timbreName = NULL;
	return self;
    }
    if (getPureName(newName,&pureName,&prefixVal,&suffixVal) == BAD)
	return nil;                                  /* No hope */
    uniqueStr = [pureName retain];
    obj = (MKTimbre *)[timbreDictionary objectForKey:uniqueStr];
    if (obj)
	return nil;
    [timbreDictionary setObject: self forKey: uniqueStr];
    obj->timbreName = (NSString *)uniqueStr;
    return self;
}

-(MKWaveTable *)waveTableForFreq:(double)freq
  /* Returns the MKWaveTable object corresponding to the specified freq, if 
     any */
{    return waveTableForFreq(self,freq);  }

- (MKWaveTable *) waveTableAt: (int) index
  /* Returns the MKWaveTable object corresponding to the specified freq, if 
     any */
{    return waveTableForIndex(self, index); }

-(double)freqForWaveTable:(MKWaveTable *)obj
  /* Returns the MKWaveTable object corresponding to the specified freq, if 
     any */
{    
//    MKWaveTable **p;
//    int count;
    int i;
    if (!waveTables || !freqs)
	return MK_NODVAL;

    /* sb: simple case of NSArray method...
    p = (MKWaveTable **)NX_ADDRESS(waveTables);
    count = [waveTables count];
    for (i=0; i<count; p++,i++)
	if (*p == obj)
	    return *((double *)[freqs elementAt:i]);
    */
    if ((i=[waveTables indexOfObjectIdenticalTo:obj]) == NSNotFound)
        return MK_NODVAL;
//    return *((double *)[freqs objectAtIndex:i]);
    return [[freqs objectAtIndex:i] doubleValue];
}

-(double)freqAt:(int)index
  /* Returns, the freq corresponding to the specified index, if any. */
{   
    if (!freqs || ![self waveTableAt:index])
	return MK_NODVAL;
//    return *((double *)[freqs elementAt:index]);
    return [[freqs objectAtIndex:index] doubleValue];
}

-(NSString *)timbreName
{
    return timbreName;
}

-(NSMutableArray *)waveTables
    /* The contents of this object should not be changed by the caller. 
     * Use Timbre's addWaveTable:forFreq: and removeWaveTable: instead.
     */
{
    return waveTables;
}

-(NSMutableArray *)freqs
    /* The contents of this object should not be changed by the caller. 
     * Use Timbre's addWaveTable:forFreq: and removeWaveTable: instead.
     */
{
    return freqs;
}

MKWaveTable *MKWaveTableForTimbreKey(NSString *key, 
				   double freq0, 
				   double freq1)
{
    NSString *pureName;
    int prefixVal,suffixVal;
    MKTimbre *timbre;
    int i;
    MKWaveTable *rtn;
    if (!timbreDictionary)
      return nil;
    i = getPureName(key,&pureName,&prefixVal,&suffixVal);
    if (i == BAD) {
	MKErrorCode(MK_spsInvalidPartialsDatabaseKeywordErr,key);
	return nil;
    }
    timbre = (MKTimbre *) [timbreDictionary objectForKey: ((i == NONE) ? key : pureName)];
    if (!timbre) {
	MKErrorCode(MK_spsInvalidPartialsDatabaseKeywordErr,key);
	return nil;
    }
    if (suffixVal)     /* Direct access */
	rtn = waveTableForIndex(timbre,suffixVal-1); 
        /* SuffixVal is 1-based, but waveTableForIndex uses 0-based index. 
	 * Sigh. */
    else {
	if (prefixVal == 0) 
	    rtn =  waveTableForFreq(timbre,freq0);
	else 
	    rtn =  waveTableForFreq(timbre,freq1);
    }
    return rtn;
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* TYPE: Archiving; Reads object.
     You never send this message directly.  
     Should be invoked with NXReadObject(). 
     See write: and finishUnarchiving.
     */
{
    if ([aDecoder versionForClassName: @"MKTimbre"] == VERSION3) 
	[aDecoder decodeValuesOfObjCTypes: "@@%", &waveTables, &freqs, &timbreName];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [aCoder encodeValuesOfObjCTypes: "@@%", &waveTables, &freqs, &timbreName];
}

- awakeAfterUsingCoder:(NSCoder *)aDecoder
{
    id obj;
    if (timbreName && (obj = (id)[timbreDictionary objectForKey: timbreName])) {
	[waveTables release];
	[freqs release];
	[super release];
	return obj;
    }
    return self;
}

@end

