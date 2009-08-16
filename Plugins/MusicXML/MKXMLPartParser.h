/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLObjectContainerParser.h"
#import "MKXMLAttributeStack.h"

@class NSString;
@class MKPart;

@interface MKXMLPartParser : MKXMLObjectContainerParser
{
    NSString *partID;
    /* in timewise scores, counter and counterPrevious are used
        * by note objects to know when their onsets occur. This is
        * because in this case part objects directly contain notes.
    */
    unsigned currentDynamics;
}


@end
