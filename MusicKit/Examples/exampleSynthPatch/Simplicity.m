#import <MKUnitGenerators/UnitGenerators.h> 
#import "Simplicity.h"

/* We call our simple SynthPatch 'Simplicity'. */
@implementation Simplicity

/* A static integer is created for each synthElement. */
static int	osc,        	/* sine wave UnitGenerator */
		stereoOut,	/* sound output UnitGenerator */
		outPatchpoint;	/* SynthData */		

+ patchTemplateFor:aNote
/* The argument is ignored in this implementation. */
{
    /* Step 1: Create an instance of the PatchTemplate class.  This
       method is automatically invoked each time the SynthPatch
       receives a Note.  However, the PatchTemplate should only be 
       created the first time this method is invoked.  If the 
       object has already been created, it's immediately returned.  
	  */
    static MKPatchTemplate *theTemplate = nil;
    if (theTemplate)
	return theTemplate;
    theTemplate = [[PatchTemplate alloc] init];

    /* Step 2: Add synthElement specifications to the PatchTemplate.  
	  The first two are UnitGenerators; the last is a SynthData 
	  that's used as a patchpoint. 
	  */
    osc = [theTemplate addUnitGenerator:[OscgUGxy class]];
    stereoOut = [theTemplate addUnitGenerator:[Out2sumUGx class]];
    outPatchpoint = [theTemplate addPatchpoint:MK_xPatch];

    /* Step 3:  Specify the connections between synthElements. */
    [theTemplate to:osc sel:@selector(setOutput:) arg:outPatchpoint];

    /* Always return the PatchTemplate. */	
    return theTemplate;
}

#define valid(_x) (!MKIsNoDVal(_x))

- applyParameters:aNote
  /* This is a private method to the Simplicity class. 
     It is used internally only.
     */
{
    /* Retrieve and store the parameters. */	
    double	myFreq = [aNote freq];
    double	myAmp = [aNote parAsDouble:MK_amp];
    double	myBearing = [aNote parAsDouble:MK_bearing];		   	

    /* Apply frequency if present. */
    if (valid(myFreq))
	[[self synthElementAt:osc] setFreq:myFreq];	

    /* Apply amplitude if present. */
    if (valid(myAmp))
	[[self synthElementAt:osc] setAmp:myAmp];

    /* Apply bearing if present. */
    if (valid(myBearing))
	[[self synthElementAt:stereoOut] setBearing:myBearing];
}

- noteOnSelf:aNote
{
    /* Step 1: Read the parameters in the Note and apply them to the patch. */
    [self applyParameters:aNote];

    /* Step 2: Turn on the patch by connecting the Out2sumUGx object to the
	patchpoint and sending the run message to all the synthElements. */

    [[self synthElementAt:stereoOut] 
     setInput:[self synthElementAt:outPatchpoint]];
    [synthElements makeObjectsPerform:@selector(run)]; 

    return self;
}

- noteUpdateSelf:aNote
{
  /* This method can be omitted, if you don't need your patch to respond to
     noteUpdates. */
    [self applyParameters:aNote];
    return self;	
}

- noteEndSelf
{
    /* Deactivate the SynthPatch by idling the output. */
    [[self synthElementAt:stereoOut] idle]; 
    return self;
}

@end

