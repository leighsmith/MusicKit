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
/*!
  @class MKTimbre
  @brief The MusicKit supports a Timbre Data Base. Each element in the data base is a MKTimbre.
 
Each MKTimbre maps a timbre name to a NSArray of MKWaveTable objects and a
parallel list of frequencies for those MKWaveTables.  The Data Base is initialized
with an extensive set of timbres.  These timbres may be removed or modified,
additional timbres may be added, etc. 

The <i>waveTables</i> List is a List object of WaveTables sorted according to
frequency.  The table that corresponds to the lowest frequency is first in the
List.  <i>freqs</i> is a NSMutableArray object containing the frequencies
corresponding to each MKWaveTable.  The <i>timbreName</i> may be any string, but
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

The MusicKit MKSynthPatches use the Data Base by passing it a "timbre key".  A
timbre key is a timbre name with an optional integer appended to it and an
optional 0 or 1 prepended to it.  The trailing number in a timbre key specifies
a particular table (1-based).  A leading 0 or 1 specifies use of  the
<b>freq0</b> or <b>freq1</b> parameter, respectively, to determine the
appropriate MKWaveTable.  For convenience in supporting this functionality in
your own MKSynthPatch  subclasses, we provide the function<b> MKWaveTableForTimbreKey()</b>. 

The Data Base is stored in a HashTable object that maps names to MKTimbre objects.
 This HashTable can be retrieved by the <b>+timbres</b> method.  See
<b>&lt;objc/HashTable.h&gt;</b> for how to enumerate the objects in a
HashTable.

An individual timbre can be written to an archive file.  Alternatively, the
entire database can be saved to an archive file using the +<b>timbres</b>
method  to retrieve the database and then archiving that object.

  @see  MKWaveTable, MKPartials, MKSamples, SynthPatchLibrary.rtf
*/
#ifndef __MK_Timbre_H___
#define __MK_Timbre_H___

#import <Foundation/Foundation.h>

@interface MKTimbre : NSObject
{
    /*! Name of this timbre */
    NSString *timbreName;
    /*! Array object of frequencies */
    NSMutableArray *freqs;
    /*! Array object of MKWaveTables */
    NSMutableArray *waveTables;
}

/*! @def MK_MAXTIMBRENAMELEN Maximum length of the name of a MKTimbre object. */
#define MK_MAXTIMBRENAMELEN 64

/*!
  @brief Retrieve timbre if it exists, otherwise create it and install it in Data Base.
  @param  name is an NSString.
  @return Returns an id.
*/
+ newTimbre: (NSString *) name;

/*!
  @brief Initialize timbre to be a new anonymous timbre.
  @return Returns an id.
*/
-init;

/*!
  Abrief Copy timbre from specified zone.
 
  The new timbre is "anonymous", i.e. it's name is NULL. 
 */
- copyWithZone: (NSZone *) zone;

/*!
  @brief Add the specified MKWaveTable/frequency pair.

  For speed, no check is made as to whether the given MKWaveTable is already
  present.   If you're not sure, send <b>removeWaveTable: </b>first. 
  @param  obj is a MKWaveTable *.
  @param  freq is a double.
  @return Returns self.
 */
- addWaveTable: (MKWaveTable *) obj forFreq: (double) freq;

/*!
  @brief Removes the given MKWaveTable and its corresponding frequency.
  
  Returns <b>nil</b> if the <i>obj</i> is not found, otherwise self. 
  @param  obj is a MKWaveTable *.
  @return Returns <b>self</b>.
*/  
-removeWaveTable:(MKWaveTable *)obj;

/*!
  @brief Returns the MKWaveTable object corresponding to the
  specified freq, if any.
  @param  freq is a double.
  @return Returns an MKWaveTable instance.
*/
- (MKWaveTable *) waveTableForFreq: (double) freq;

/*!
  @brief Returns the freq corresponding to the specified freq, if any.

  Returns MK_NODVAL if none.  
  @param  obj is a MKWaveTable *.
  @return Returns a double.
*/
- (double) freqForWaveTable: (MKWaveTable *) obj;

/*!
  @brief Returns the MKWaveTable object corresponding to the specified index, if any.

  Index is zero-based.  
  @param  index is an int.
  @return Returns an MKWaveTable instance.
*/
- (MKWaveTable *) waveTableAt: (int) index;

/*!
  @brief Returns the freq corresponding to the specified index, if any.

  Otherwise, returns MK_NODVAL. Index is zero-based.
  @param  index is an int.
  @return Returns a double.
*/
- (double) freqAt: (int) index;

/*!
  @brief Returns the timbre data base, a NSDictionary mapping names to MKTimbres.
  
  The table is not copied.  You should not free it or alter it.  To
  delete a MKTimbre, first find the MKTimbre and then send it the
  <b>free</b> or <b>freeSelfOnly</b> message.
  @return Returns an NSDictionary.
*/
+ (NSDictionary *) timbres;

/*!
  @brief if successful or <b>nil</b> if <i>newName</i> is already in use.
  @param  newName is a NSString instance.
  @return Returns <b>self</b>.
*/
- setTimbreName: (NSString *) newName;

/*!
  @brief Frees receiver and removes it from Data Base.  Frees WaveTables. 
 */
- (void) dealloc;

/*!
  @brief Empties the MKWaveTable and freqs NSArrays.
*/
- (void) removeAllObjects;

/*!
  @brief Returns <i>timbreName</i>.
 
  The string is not copied and should not be altered or freed.
  @return Returns an NSString.
*/
- (NSString *) timbreName;

/*!
  @brief Returns <i>waveTables</i> object.

  The NSMutableArray is not copied and should not be altered.
  @return Returns an NSMutableArray.
*/
- (NSMutableArray *) waveTables;

/*!
  @brief Returns <i>freqs</i>.

  <i>freqs</i> NSMutableArray is not copied.
  @return Returns an NSMutableArray.
*/
- (NSMutableArray *) freqs;

/* Reads object from archive file. */
- (id) initWithCoder: (NSCoder *) aDecoder;

/* Writes object to archive file. */
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* If name is already in use, frees newly unarchived object and returns
     existing MKTimbre for that name.   */
- awakeAfterUsingCoder: (NSCoder *) aDecoder;

/*!
  @brief Extracts the timbre name from timbreKey (by removing leading and 
  trailing numbers) and looks up that name in the Data Base.
 
 If there is a no timbre with that name, returns nil.  Otherwise, looks
 for a trailing number in the timbreKey.  If there is one, uses this
 as a 1-based index into the List of WaveTables and returns that MKWaveTable.
 Otherwise, looks for a 0 or 1 prepended to the timbreKey.  If there is 
 one, uses this to determine whether freq0 or freq1 is to be used to
 chose the MKWaveTable.  If no number is prepended, uses freq1.  Returns
 the MKWaveTable with frequency greater than or equal to the specified
 frequency. 
 */
MKWaveTable *MKWaveTableForTimbreKey(NSString *timbreKey, 
				   double freq0, 
				   double freq1);
   
@end

#endif
