// $Id$

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#ifdef NeXT
#import <synthpatches/Pluck.h> // TODO: MOXS MusicKit can't compile synthpatches yet.
#endif
#import "PlayScore.h"
#import "Distributor.h"
#import "Document.h"
#import "PartView.h"
#import "TadPole.h"

@implementation Distributor

- init
{
	[super init];
	if (!scorePlayer) scorePlayer = [[PlayScore alloc] init];
	docList = [[NSMutableArray alloc] init];
	return self;
}

- setTadList:theList
{
	tadList = theList;
	return self;
}

- returnTadList
{
	return tadList;
}

- (void)newDoc:sender
{
     
}

- (void)openDoc:sender
{
	NSArray *fileTypes = [NSArray arrayWithObjects: @"score", @"playscore", nil];
        NSString *errorMsg = @"Can't find scorefile ";
	MKScore *aScore;
	Document *newDoc;

        if (!scorePlayer) scorePlayer = [[PlayScore alloc] init];
	if (!openPanel)
		openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
        if (![openPanel runModalForDirectory:@"" file:@"" types:fileTypes])
		return;
	aScore = [[MKScore alloc] init];
	if (![aScore readScorefile:[openPanel filename]]) {
		NSRunAlertPanel(@"PianoRoll", [errorMsg stringByAppendingString: [openPanel filename]], @"OK", nil, nil);
		return;
	}
	if ([[aScore parts] count] == 0) {
		NSRunAlertPanel(@"PianoRoll", @"No parts in file.", @"OK", nil, nil);
		return;
	}
	newDoc = [[Document alloc] initWithScore:aScore];
        [aScore release];
	[newDoc setName:[openPanel filename]];
	[[newDoc docWindow] setTitleWithRepresentedFilename:[openPanel filename]];
	[docList addObject:newDoc]; 
}

- (void)saveDocAs:sender
{
        MKScore *aScore;
	
	aScore = [[self findCurrent] whatScore];
	if (!aScore)
		return;
	if (!savePanel)
		savePanel = [NSSavePanel savePanel];
	if (![savePanel runModal]) {
		NSRunAlertPanel(@"PianoRoll", @"Error with save panel.", @"OK", nil, nil);
		return;
	}
	[aScore writeScorefile:[savePanel filename]]; 
}

- (void)play:sender 
{
	MKScore *aScore;
	
	aScore = [[self findCurrent] whatScore];
	if (aScore) {
		[scorePlayer setUpPlay:aScore];
		[scorePlayer play:aScore];
	} 
}

- (void)stopPlay:sender
{
	[scorePlayer stop];
}


- (void)saveDoc:sender
{
	id aDoc;
	
	aDoc = [self findCurrent];
	if (!aDoc)
		return;
	[[aDoc whatScore] writeScorefile:[aDoc whatName]]; 
}

- (void)closeDoc:sender
{
	id aDoc;
	
	aDoc = [self findCurrent];
	if (!aDoc)
		return;
	[[aDoc docWindow] close];
	[[aDoc whatScore] release];
	[[aDoc whatName] release]; 
}

- (void)showInfo:sender
{
	if (!infoPanel)
		[NSBundle loadNibNamed:@"Info.nib" owner:self];
	[infoPanel makeKeyAndOrderFront:self]; 
}

- (void)showHelp:sender
{
	if (!helpPanel)
		[NSBundle loadNibNamed:@"Help.nib" owner:self];
	[helpPanel makeKeyAndOrderFront:self]; 
}

- (Document *) findCurrent
{
	int i;
	id aDoc;
	
	for (i = 0; i < [docList count]; i++) {
		aDoc = [docList objectAtIndex:i];
		if ([aDoc isCurrent])
			return aDoc;
	}
	NSRunAlertPanel(@"findCurrent", @"Can't find current document.", @"OK", nil, nil);
	return nil;
}


@end
