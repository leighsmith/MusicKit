/* Envelope.m -- Implementation of Envelope class
 *
 * See Envelope.h for details
 *
 * jwp@silvertone.Princeton.edu, 1/90
 *
 * Version 1.31, 03/90
 *	-- Gets current Sound from EdsndApp
 */

#import "Envelope.h"
#import "EnvelopeView.h"
#import "EdsndApp.h"
#import "SoundDocument.h"
#import "ScrollingSound.h"
#import "EdSoundView.h"
#import "UpPanel.h"
#import <appkit/Application.h>
#import <appkit/Panel.h>
#import <appkit/Form.h>
#import <string.h>

@implementation Envelope

/* new
 *	We need this to load the .nib file.
 */
+ new
{
	self = [super new];
	[NXApp loadNibSection:"Envelope.nib" owner:self];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* doEnvelope: -- do the enveloping.
 * This message sent by Envelope's button
 */
- doEnvelope:sender
{
	NXPoint *env;
	int npoints;

/* Get the envelope and pass it to the current EdSoundView.
 */
	npoints = [envView envelope:&env];
	if ([NXApp currentSound])
		[[NXApp currentSound] envelope:env Points:npoints];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* point:MovedTo: -- delegate method for EnvelopeView
 * This updates the X and Y forms while the envelope is being altered
 */
- point:(int) n MovedTo:(NXPoint *)p
{
	[pointForm setIntValue:n];
	[xForm setFloatValue:p->x];
	[yForm setFloatValue:p->y];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* envelopeChanged: -- delegate method for EnvelopeView
 * This updates the textField that displays all the envelope data at
 * once
 */
- envelopeChanged:sender
{
	char s[1024];
	char tmp[64];
	NXPoint *env;
	int i,npoints;

	npoints = [sender envelope:&env];
	for (i = 0; i < npoints; i++,env++) {
		sprintf(tmp,"(%5.3f,%5.3f)\n",env->x,env->y);
		strcat(s,tmp);
	}
	[envText setStringValue:s];
	NXPing();
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* Get/set instance variables:
 */
- setEnvPanel:anObject
{
	envPanel = anObject;
	[envPanel setUpdateAction:@selector(panelUpdate:) by:NXApp];
	return self;
}
- envPanel
{
	return envPanel;
}
- setEnvView:anObject
{
	envView = anObject;
	[envView setDelegate:self];
	return self;
}
- setPointForm:anObject
{
	pointForm = anObject;
	return self;
}
- setXForm:anObject
{
	xForm = anObject;
	return self;
}
- setYForm:anObject
{
	yForm = anObject;
	return self;
}
- setEnvText:anObject
{
	envText = anObject;
	return self;
}

@end

