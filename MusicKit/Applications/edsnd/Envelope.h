/* Envelope.h -- Interface for Envelope class
 *
 * This handles the envelope generator for edsnd.  It owns a panel with
 * an EnvelopeView, three Forms to display envelope point data,
 * a textField to display the total envelope data,
 * and a Button to cause the actual enveloping of the current sound.
 * Enveloping message is sent to current firstResponder.
 *
 * jwp@silvertone.Princeton.edu, 1/90
 */

#import <objc/Object.h>
#import <appkit/graphics.h>

@interface Envelope:Object
{
	id envPanel;		/* Pointers to all outlets */
	id envView;
	id pointForm;
	id xForm;
	id yForm;
	id envText;
}

+ new;			/* Needed to load the .nib file */

/* INSTANCE METHODS:
 *	- doEnvelope:		-- message from button
 *	- point:MovedTo: 	-- delegate methods for EnvelopeView
 *	- envelopeChanged:
 */
- doEnvelope:sender;
- point:(int)n MovedTo:(NXPoint *)p;
- envelopeChanged:sender;

/* Get/set instance variables:
 */
- setEnvPanel:anObject;
- envPanel;
- setEnvView:anObject;
- setPointForm:anObject;
- setXForm:anObject;
- setYForm:anObject;
- setEnvText:anObject;

@end


