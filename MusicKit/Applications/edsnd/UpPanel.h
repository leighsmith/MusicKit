/* UpPanel.h -- Interface for UpPanel class.
 *
 * This is a subclass of Panel that allows custom update methods.
 *
 * To use within Interface Builder, parse this class (via class
 * window) and use Panel Inspector to assign any given panel to this
 * class.
 *
 * To use, send following message to an instance to set up updating
 * via an Object 'anObject' with method name 'updater:'
 *	[anUpPanel setUpdateAction:@selector(updater:) by:anObject];
 * The 'updater:' method will receive an id pointer to the UpPanel
 * when called.
 *
 * jwp@silvertone.Princeton.edu, 11/89
 */

#import <appkit/Panel.h>

@interface UpPanel : Panel
{
	id	upObject;		/* The object that updates */
	SEL	upAction;		/* The action to take */
}

- setUpdateAction:(SEL)action by:anObject;
- update;				/* This overrides Panel definition */

@end
