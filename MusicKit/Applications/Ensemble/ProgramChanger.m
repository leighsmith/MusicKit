#import "ProgramChanger.h"
#import "EnsembleDoc.h"
#import "EnsembleApp.h"
#import <musickit/Note.h>
#import <musickit/Conductor.h>
#import <musickit/params.h>

extern id documents;

@implementation ProgramChanger
{
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	[self addNoteReceiver:[[NoteReceiver alloc] init]];
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	if (([aNote noteType] == MK_noteUpdate) &&
		(MKIsNoteParPresent(aNote, MK_programChange))) {
		id     *doc;
		int     n, program;
		BOOL    changeOk = NO, usingDSP = NO;

		program = MKGetNoteParAsInt(aNote, MK_programChange);

		/* See if we have anything to do */
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if (changeOk = (![*doc isConnected]) && ([*doc program] == program))
				break;

		/* If not, at least reset all note filters and instruments */
		if (!changeOk) {
			[NXApp sendRealTimeNote:MK_sysReset];
			return self;
		}
		/* Disconnect all connected docs with a different program number.
		 * A program number > 127 means always stay connected. */
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if (([*doc program] != program) && ([*doc program] < 128)
				&& [*doc isConnected]) {
				[NXApp sendRealTimeNote:MK_sysStop];
				[*doc disconnect];
			}
		/* Connect all disconnected docs with the new program number */
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if (([*doc program] == program) || ([*doc program] > 127)) {
				if (![*doc isConnected])
					[*doc connect];
				usingDSP = (usingDSP || [*doc usesDSP]);
			}
		if (![Conductor inPerformance] ||
			(usingDSP &&
			 ([[Orchestra nthOrchestra:0] deviceStatus] != MK_devRunning)))
			[NXApp reset];
		else if (usingDSP)
			[NXApp synchDSPDelayed:.5];
		else if ([[Orchestra nthOrchestra:0] deviceStatus] == MK_devRunning) {
			[Conductor lockPerformance];
			[[Orchestra nthOrchestra:0] abort];
			[Conductor unlockPerformance];
		}
	}
	if (MKIsNoteParPresent(aNote, MK_sysRealTime))
		switch (MKGetNoteParAsInt(aNote, MK_sysRealTime)) {
		  case MK_sysStart:
			break;
		  case MK_sysContinue:
			break;
		  case MK_sysStop:
			break;
		  case MK_sysReset:
			break;
		}
	return self;
}

@end
