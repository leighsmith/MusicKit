/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is a private class holding patch lists.
    There are one of these for each MKSynthInstrument template.
    At the moment this definition of the class is wierd to accomodate the behaviour
    of MKSynthInstrument. Eventually the public accessibility of the ivars should disappear
    and the Patch list functions in MKSynthPatch should somehow migrate over to here.

  Original Author: Leigh M. Smith <leigh@tomandandy.com>

  Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
/*
Modification history:

 $Log$
 Revision 1.1  2000/05/24 03:47:39  leigh
 Removed use of Storage, replacing with SynthPatchList object

*/
#import <Foundation/Foundation.h>

@interface SynthPatchList : NSObject
{
@public
    id idleNewest;
    id idleOldest;
    id activeNewest;
    id activeOldest;
    int idleCount,totalCount,manualCount;
    id template;
}

- init;
- (void) setTemplate: (id) newTemplate;
- (void) setActiveNewest: (id) newActiveNewest;
- (void) setActiveOldest: (id) newActiveOldest;

@end
