/******************************************************************************
LEGAL:
This framework and all source code supplied with it, except where specified,
are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free
to use the source code for any purpose, including commercial applications, as
long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be
error free.  Further, we will not be liable to you if the Software is not fit
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#ifndef __SNDDISPLAYDATALIST_H__
#define __SNDDISPLAYDATALIST_H__

#import <AppKit/AppKit.h>

/*!
@class      SndDisplayDataList
@abstract   Maintain a sorted list of cached display data for SndViews
@discussion If it was easy to subclass NSMutableArray this would be one. However
            it was easier to simply hold an instance variable of a NSMutableArray
            and send it all messages which we outselves do not recognise. The
            special things we want to add to NSMutableArray are a specialised
            sort routine, and a method to return the underlying data object
            holding the data for a given pixel.
*/

@interface SndDisplayDataList: NSObject
{
    NSMutableArray *embeddedArray;
}

/*!
  @method sort
  @result Returns self.
  @discussion Sorts the underlying list of display data for the current display
              resolution into chronological order. Elements may be discontiguous.
              INTERNAL USE ONLY.
*/
- sort;

/*!
  @method findObjectContaining:next:leadsOnFrom:
  @result Returns the index of the object containing the given pixel, or -1 if the
          pixel is before the start of the cached data. On return, next is filled
          with the index of the following data segment (if it exists), and
          leadsOnFrom is filled with the index of the preceding data segment, if
          it exits AND if the data in the two segments is continuous.
  @discussion Sorts the underlying list of display data for the current display
              resolution into chronological order. Elements may be discontiguous.
              INTERNAL USE ONLY.
*/
- (int) findObjectContaining: (int)   pixel 
	                next: (int *) next 
	         leadsOnFrom: (int *) leadsOnFrom;
@end

#endif
