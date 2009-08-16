/* UpPanel.m -- Implementation of UpPanel class.
 *
 * See UpPanel.h for info
 *
 * jwp@silvertone.Princeton.edu, 11/89
 */

#import "UpPanel.h"

@implementation UpPanel

/* setUpdateAction:by: -- Set up the updating action and the object
 *	that implements it.  This message can be sent by any object,
 *	and the updating object need not be the sender.
 */
- setUpdateAction:(SEL)action by:anObject
{
	if ([anObject respondsTo:action]) {
		upAction = action;
		upObject = anObject;
	}
	return self;
}

/* update -- This method overrides the default (null) method of Panel.
 *	It sends an 'UpAction:' message to 'UpObject', using an id
 *	pointer to this UpPanel as an argument.  The return value of
 *	the UpAction is ignored.
 */
- update
{
	if (upObject && upAction)
		[upObject perform:upAction with:self];
	return self;
}

@end
