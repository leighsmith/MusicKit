/*
  $Id$
  Defined In: The MusicKit

  Description:
    The MusicKit supports a Timbre Data Base.  Each element in the data base
    is an MKTimbre.  MKTimbres map a timbre name to an NSArray of MKWaveTable objects
    and a parallel list of frequencies for those MKWaveTables.  The Data Base
    is initialized with an extensive set of timbres.  These timbres may be
    removed or modified, additional timbres may be added, etc.

    The waveTables list is a NSArray of MKWaveTables sorted according to
    freq, with the table corresponding to the lowest frequency first.
    freqs is a NSArray containing the frequencies corresponding to
    each MKWaveTable.  The name may be any string, but should not have a number
    in it and should not be longer than MK_MAXTIMBRENAMELEN.

    You normally create or retrieve an MKTimbre with +newTimbre:, passing the
    name of the timbre you want.  If that timbre exists, it is retrieved,
    otherwise it is created and installed in the Data Base.  Alternatively,
    you can create a new anonymous timbre with +alloc and init.  In this case,
    the timbre is not put in the Data Base until its name is set with
    -setTimbreName:.  -setTimbreName: can also be used to change the name of a
    timbre that is already in the Data Base.  -timbreName may be used to
    retrieve the name of an MKTimbre.  An anonymous timbre has a name field of
    NULL.

    The Music Kit MKSynthPatches use the Data Base by passing it a "timbre key".
    A timbre key is a timbre name with an optional integer appended to it and
    an optional 0 or 1 prepended to it. The trailing number in a timbre key
    specifies a particular table (1-based).  A leading 0 or 1 specifies use of
    freq0 or freq1 respectively to determine the appropriate MKWaveTable.
    For convenience in supporting this functionality in your own MKSynthPatch
    subclasses, we provide the function MKWaveTableForTimbreKey().

    The Data Base is stored in a NSDictionary object that maps names to
    MKTimbre objects.  This NSDictionary can be retrieved by the +timbres method.
    See <Foundation/NSDictionary.h> for how to enumerate the objects in a NSDictionary.

    An individual timbre can be written to an archive file.  Alternatively, the
    entire Data Base can be saved to an archive file using the +timbres method
    to retrieve the Data Base and then archiving that object.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.6  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.5  2000/11/25 23:23:15  leigh
  Removed redundant freeSelfOnly

  Revision 1.4  2000/06/27 18:08:41  leigh
  Converted hashtable into a NSDictionary timbreDictionary

  Revision 1.3  2000/04/25 22:07:46  leigh
  Doco cleanup and redundant headers removed

  Revision 1.2  1999/07/29 01:25:51  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKTimbre
  @discussion

The Music Kit supports a Timbre Data Base.  Each element in the data base is a
MKTimbre.  Each MKTimbre maps a timbre name to a NSArray of MKWaveTable objects and a
parallel list of frequencies for those MKWaveTables.  The Data Base is initialized
with an extensive set of timbres.  These timbres may be removed or modified,
additional timbres may be added, etc. 

The <i>waveTables</i> List is a List object of WaveTables sorted according to
frequency.  The table that corresponds to the lowest frequency is first in the
List.   <i>freqs</i> is a Storage object containing the frequencies
corresponding to each MKWaveTable.  The<i> timbreName</i> may be any string, but
should not have a number in it and should not be longer than
MK_MAXTIMBRENAMELEN, which is defined in <b>MKTimbre.h.</b>
   
You normally create or retrieve an MKTimbre with<b> +newTimbre:</b>, passing the
name of the timbre you want.  If that timbre exists, it is retrieved, otherwise
it is created and installed in the Data Base.  Alternatively, you can create a
new anonymous timbre with <b>+alloc</b> and <b>init</b>.  In this case, the
timbre is not put in the Data Base until its name is set with
<b>setTimbreName:</b>.  <b>setTimbreName:</b> can also be used to change the
name of a  timbre that is already in the Data Base.  <b>timbreName</b> may be
used to retrieve the name of an MKTimbre.  An anonymous timbre has a name field of
NULL.

The Music Kit SynthPatches use the Data Base by passing it a "timbre key".   A
timbre key is a timbre name with an optional integer appended to it and an
optional 0 or 1 prepended to it.   The trailing number in a timbre key specifies
a particular table (1-based).  A leading 0 or 1 specifies use of  the
<b>freq0</b> or <b>freq1</b> parameter, respectively, to determine the
appropriate MKWaveTable.   For convenience in supporting this functionality in
your own MKSynthPatch  subclasses, we provide the function<b> MKWaveTableForTimbreKey()</b>. 

The Data Base is stored in a HashTable object that maps names to MKTimbre objects.
 This HashTable can be retrieved by the <b>+timbres</b> method.  See
<b>&lt;objc/HashTable.h&gt;</b> for how to enumerate the objects in a
HashTable.

An individual timbre can be written to an archive file.  Alternatively, the
entire Data Base can be saved to an archive file using the <b>+timbres</b>
method  to retrieve the Data Base and then archiving that object.

See also:  MKWaveTable, MKPartials, MKSamples, SynthPatchLibrary.rtf
*/
#ifndef __MK_Timbre_H___
#define __MK_Timbre_H___

#import <Foundation/Foundation.h>

@interface MKTimbre : NSObject
{
    NSString *timbreName;               /* Name of this timbre */
    NSMutableArray *freqs;              /* Array object of frequencies */
    NSMutableArray *waveTables;         /* Array object of MKWaveTables */
}

#define MK_MAXTIMBRENAMELEN 64

/*!
  @method newTimbre:
  @param  name is an NSString.
  @result Returns an id.
  @discussion Retrieve timbre if it exists, otherwise create it and install it in
              Data Base.
*/
+newTimbre:(NSString *)name;

/*!
  @method newTimbre:
  @result Returns an id.
  @discussion Initialize timbre to be a new anonymous timbre. 
*/
-init;

- copyWithZone:(NSZone *)zone;
 /* Copy timbre from specified zone.  The new timbre is "anonymous", i.e.
    it's name is NULL. */

/*!
  @method addWaveTable:forFreq:
  @param  obj is a MKWaveTable *.
  @param  freq is a double.
  @result Returns an id.
  @discussion Add the specified MKWaveTable/frequency pair. Returns self.  For
              speed, no check is made as to whether the given MKWaveTable is already
              present.   If you're not sure, send <b>removeWaveTable: </b>first. 
*/
-addWaveTable:(MKWaveTable *)obj forFreq:(double)freq;

/*!
  @method removeWaveTable:
  @param  obj is a MKWaveTable *.
  @result Returns <b>self</b>.
  @discussion Removes the given MKWaveTable and its corresponding frequency.  
              Returns <b>nil</b> if the <i>obj</i> is not found, otherwise self. 
*/                            
-removeWaveTable:(MKWaveTable *)obj;

/*!
  @method waveTableForFreq:
  @param  freq is a double.
  @result Returns an id.
  @discussion Returns the MKWaveTable object corresponding to the
              specified freq, if any.
*/
-waveTableForFreq:(double)freq;

/*!
  @method freqForWaveTable:
  @param  obj is a MKWaveTable *.
  @result Returns a double.
  @discussion Returns the freq corresponding to the specified freq, if any. 
              Returns MK_NODVAL if none.  
*/
-(double)freqForWaveTable:(MKWaveTable *)obj;

/*!
  @method waveTableAt:
  @param  index is an int.
  @result Returns an id.
  @discussion Returns the MKWaveTable object corresponding to the specified index,
              if any.  Index is zero-based.  
*/
-waveTableAt:(int)index;

/*!
  @method freqAt:
  @param  index is an int.
  @result Returns a double.
  @discussion Returns the freq corresponding to the specified index, if any. 
              Otherwise, returns MK_NODVAL. Index is zero-based.
              
*/
-(double)freqAt:(int)index;

/*!
  @method timbres
  @result Returns an NSDictionary.
  @discussion Returns the timbre data base, a NSDictionary mapping names to MKTimbres. 
              The table is not copied.  You should not free it or alter it.  To
              delete a MKTimbre, first find the MKTimbre and then send it the
              <b>free</b> or <b>freeSelfOnly</b> message.
*/
+(NSDictionary *)timbres;

/*!
  @method setTimbreName:
  @param  newName is a char *.
  @result Returns <b>self</b>.
  @discussion if successful or <b>nil</b> if <i>newName</i> is already in use.
*/
-setTimbreName:(NSString *)newName;

- (void)dealloc;
  /* Frees receiver and removes it from Data Base.  Frees WaveTables. */

/*!
  @method removeAllObjects
  @discussion Empties the MKWaveTable Lits and freqs NSArray.
*/
- (void)removeAllObjects;

/*!
  @method timbreName
  @result Returns an NSString.
  @discussion Returns <i>timbreName<b>.</b></i>  The string is not copied and
              should not be altered or freed.
*/
-(NSString *)timbreName;  /* String is not copied */

/*!
  @method waveTables
  @result Returns an NSMutableArray.
  @discussion Returns <i>waveTables</i> object.  The NSMutableArray is not copied and should
              not be altered.
*/
-(NSMutableArray *)waveTables; /* MKWaveTable List is not copied */

/*!
  @method freqs
  @result Returns an NSMutableArray.
  @discussion Returns <i>freqs</i>.<i>freqs</i> NSMutableArray is not copied.              
*/
-(NSMutableArray *)freqs;  /* freqs NSArray is not copied. */

  /* Reads object from archive file. */
- (id)initWithCoder:(NSCoder *)aDecoder;

  /* Writes object to archive file. */
- (void)encodeWithCoder:(NSCoder *)aCoder;

  /* If name is already in use, frees newly unarchived object and returns
     existing MKTimbre for that name.   */
- awakeAfterUsingCoder:(NSCoder *)aDecoder;

  /* Extracts the timbre name from timbreKey (by removing leading and 
     trailing numbers) and looks up that name in the Data Base.  If 
     there is a no timbre with that name, returns nil.  Otherwise, looks
     for a trailing number in the timbreKey.  If there is one, uses this
     as a 1-based index into the List of WaveTables and returns that MKWaveTable.
     Otherwise, looks for a 0 or 1 prepended to the timbreKey.  If there is 
     one, uses this to determine whether freq0 or freq1 is to be used to
     chose the MKWaveTable.  If no number is prepended, uses freq1.  Returns
     the MKWaveTable with frequency greater than or equal to the specified
     frequency. */
MKWaveTable *MKWaveTableForTimbreKey(NSString *timbreKey, 
				   double freq0, 
				   double freq1);
   
@end

#endif
