/*
  $Id$
  Defined In: The MusicKit

  Description:
    Rewritten from original code by Michael McNabb as part of the Ensemble open source program.
    Each MKSamplerInstrument holds a collection of performances of sound files indexed by noteTag.
    There is a SndPerformance for each note which indicates which sound file to play and when.
    A MKNote has a MK_filename parameter which is the soundfile to be played, together with any
    particular tuning deviation to be applied to it using a keynumber or frequency which forms a ratio
    from the unity key number located in the (AIFF or RIFF (.wav)). That does imply being able to load the file
    immediately (within the Delta) for playback. But then, we should be spooling from disk anyway.

  Original Author: Leigh M. Smith <leigh@tomandandy.com>

  Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/

#import "_musickit.h"
#import "MKSamplerInstrument.h"
#import "MKConductor.h"

#define UNASSIGNED_SAMPLE_KEYNUM (-1)

@implementation MKSamplerInstrument

- reset
{
  //int i;
  // this should be taken from the note parameter
  //	amp = (double)strtol([ampField stringValue], NULL, 10);
  linearAmp = MKdB(amp);
  // this should be taken from the note parameter
  //	bearing = [bearingField doubleValue];
  keyNum = c4k;
  testKey = keyNum;
  voiceCount = 3;
  volume = 1.0;
  pitchBend = 0.0;
  pitchbendSensitivity = 0.0;
  pbSensitivity = (pitchbendSensitivity / 12.0) / 8192.0;
  recordModeController = UNASSIGNED_SAMPLE_KEYNUM;  // LMS probably wrong definition
  volume = 1.0;
  pitchBend = 1.0;
//  for (i = 0; i < MAX_PERFORMERS; i++) {
//    if (playingSamples[i]) {
//      [MKConductor lockPerformance];
//      [playingSamples[i] reset];
//      [playingSamples[i] setAmp:linearAmp volume:volume bearing:bearing/45.0];
//      [MKConductor unlockPerformance];
//    }
//  }
  return self;
}

// Initialize the sound objects.
- init
{
    [super init];
    [self addNoteReceiver:[MKNoteReceiver new]];

    playingNotes = [[NSMutableDictionary dictionaryWithCapacity: 20] retain]; 
    // since we update the playingNotes queue (actually a dictionary) via an abort/stop routine from
    // the application and from the asynchronous didPlay: delegate message, we protect it with a lock.
    [self reset];
    return self;
}

- (void) removePreparedSounds
{
    [Snd removeAllSounds];
}

/* Free the playnotes list and remove the named sounds */
- (void) dealloc
{
    [playingNotes release];
    [self removePreparedSounds];
    [super dealloc];
}

// Prepare by preparing the PlayingSound instance
- prepareSoundWithNote: (MKNote *) aNote
{
    int key;
    int baseKey;
    Snd *newSound;
    NSString *filePath;

    // NSLog(@"Preparing %@\n", aNote);
    // only prepare those notes which are samples.
    if(![aNote isParPresent: MK_filename])
        return nil;

    key = [aNote keyNum];
    baseKey = key;   // should be baseKey = [sound unityKeyNum];

    filePath = [aNote parAsString: MK_filename];
    // either retrieve playingSample from the table of playing sounds according to the filename or create afresh.
    if ([Snd soundNamed: filePath] != nil) {     // check if the sound file is already loaded.
        // NSLog(@"Already loaded for keyNum %d %@\n", key, filePath);
        return nil;
    }

    // Not loaded, load it now. Read soundfile, for now loading it into a Snd object, eventually 
    // priming the buffers for play direct from disk.
    if ((newSound = [Snd addName: filePath fromSoundfile: filePath]) == nil) {
        MKErrorCode(MK_cantOpenFileErr, filePath);
        return nil;
    }
    return self;
}

- playSampleNote: (MKNote *) aNote inFuture: (double) inSeconds
{
    Snd *existingSound;
    NSString *filePath;
    SndPerformance *newPerformance;

    // only play those notes which are samples.
    if(![aNote isParPresent: MK_filename])
        return nil;
    filePath = [aNote parAsString: MK_filename];
    // NSLog(@"playing file %@\n", filePath);

    if ((existingSound = [Snd soundNamed: filePath]) == nil) { // Ouch! better check the disk-load times here
        MKErrorCode(MK_cantOpenFileErr, filePath);
        return nil;
    }
    // needed to remove notes when sounds complete playing.
    [existingSound setDelegate: self];
    // NSLog(@"playInFuture:inSeconds = %lf\n", inSeconds);
    newPerformance = [existingSound playInFuture: inSeconds];
    // NSLog(@"newPerformance = %@\n", newPerformance);
    // keep a dictionary of playing notes (keyed by note instance, added in time order) and their performances.
    [playingNotes setObject: newPerformance forKey: aNote];
    return self;
}

- playSampleNote: (MKNote *) aNote
{
    Snd            *existingSound;
    NSString       *filePath;
    SndPerformance *newPerformance;
    MKConductor    *conductor = [aNote conductor]; 
    double          factor    = 60 / [conductor tempo];
    double          noteTime  = [aNote timeTag] * factor;  // for now - static tempo time. Urk!
    double          duration  = 1;

    // only play those notes which are samples.
    if(![aNote isParPresent: MK_filename])
        return nil;
    filePath = [aNote parAsString: MK_filename];
    // NSLog(@"playing file %@\n", filePath);

    if ((existingSound = [Snd soundNamed: filePath]) == nil) { 
        MKErrorCode(MK_cantOpenFileErr, filePath);
        return nil;
    }
    // needed to remove notes when sounds complete playing.
    [existingSound setDelegate: self];
    

    if ([aNote noteType] == MK_noteDur) {
      duration  = [aNote dur] * factor;
    }
    
//    fprintf(stderr,"[MKSampler] Note timeTag:%f clientTime:%f\n",[aNote timeTag],[[SndStreamManager defaultStreamManager] nowTime]);
    
    newPerformance = [existingSound playAtTimeInSeconds:  noteTime  // + [MKConductor deltaT]
                                  withDurationInSeconds: duration];

    // keep a dictionary of playing notes (keyed by note instance, added in time order) and their performances.
    [playingNotes setObject: newPerformance forKey: aNote];
    return self;
}


/*
- playSampleNote: (MKNote *) aNote
{
    return [self playSampleNote: aNote inFuture: 0.0];
}
*/

// schedule stopping a sample at some time in the future.
- stopSampleNote: (MKNote *) aNote inFuture: (double) inSeconds
{
    SndPerformance *performingSound;

    // NSLog(@"stopping sample note %@ at time %f\n", aNote, inSeconds);

    // only stop playing those sounds which are currently in the playing note dictionary.
    performingSound = [playingNotes objectForKey: aNote];

    if(performingSound) {
        // NSLog(@"sound is playing %@\n", performingSound);
        [performingSound stopInFuture: inSeconds];
        // We don't remove the note from the playingNotes dictionary now, since we are only scheduling a stop.
        // We preserve the dictionary of performances until the didPlay: delegate message. 
    }
    return self;
}

// Stop any playing notes.
- allNotesOff
{
    MKNote *note;
    NSEnumerator *noteEnumerator;

    noteEnumerator = [playingNotes keyEnumerator];
    while ((note = [noteEnumerator nextObject])) {
	[self stopSampleNote: note inFuture: 0.0];
    }
    // [ stopRecording];
    return self;
}

// first warning of the impending stream of notes with sounds to be loaded from disk.
- firstNote: (MKNote *) aNote
{
    [super firstNote: aNote];
    [self prepareSoundWithNote: aNote];
    return self;
}

- performerDidActivate: (id) sender
{
    NSLog(@"Got playingSample delegate activation notice\n");
    return self;
}

- performerDidDeactivate: (id) sender
{
    NSLog(@"Got playingSample delegate deactivation notice\n");
    return self;
}

- setAmp: (int) noteTag
{
#if 0
  PlayingSound **p = playingSamples;
  PlayingSound **end = p + MAX_PERFORMERS;
  while (p < end) {
    if (*p && ((noteTag == MAXINT) || (noteTag == [*p noteTag])))
      [*p setAmp:linearAmp];
    p++;
  }
#endif
  return self;
}

- setVolume: (int) noteTag
{
//  int i;
//  for (i = 0; i < MAX_PERFORMERS; i++)
//    if ((noteTag == MAXINT) || (noteTag == [playingSamples[i] noteTag]))
//      [playingSamples[i] setVolume:volume];
  return self;
}

- setBearing: (int) noteTag
{
//  int i;
//  float tmp = bearing/45.0;

//  for (i = 0; i < MAX_PERFORMERS; i++)
//    if ((noteTag == MAXINT) || (noteTag == [playingSamples[i] noteTag]))
//      [playingSamples[i] setBearing:tmp];
  return self;
}

- setPitchBend: (int) noteTag
{
//  int i;

//  for (i = 0; i < MAX_PERFORMERS; i++)
//    if ((noteTag == MAXINT) || (noteTag == [playingSamples[i] noteTag]))
//      [playingSamples[i] setPitchBend:pitchBend];
  return self;
}

- activate:(int)noteTag
{
//  int i;

//  for (i = 0; i < MAX_PERFORMERS; i++)
//    if (playingSamples[i] && ((noteTag == MAXINT) || (noteTag == [playingSamples[i] noteTag]))) {
//      NSLog(@"Playing playingSample keyNum = %d, noteTag = %d\n", i, noteTag);
//      [playingSamples[i] activate];
//    }
  return self;
}

- deactivate:(int)noteTag
{
    
    NSLog(@"in MKSamplerInstrument deactivate:\n");
#if 0 // only needed when we are recording.
    if (noteTag == recordTag) {	
	[recorder stopRecording];
	[self clearAtKey: recordKey];
	if (!playingSamples[recordKey]) {
	    playingSamples[recordKey] = [[Snd alloc] initWithSound: recorder];
	    [playingSamples[recordKey] setDelegate: self];
	    [playingSamples[recordKey] enablePreloading: preloadingEnabled];
	}
	else
	    [playingSamples[recordKey] setSound: recorder];
	recordTag = recordKey = UNASSIGNED_SAMPLE_KEYNUM; // TODO not the right definition.
    }
#endif
#if 0
    if (noteTag >= 0) {
	int i;
	
	for (i = 0; i < MAX_PERFORMERS; i++) {
	    if (playingSamples[i] && ((noteTag == MAXINT) || (noteTag == [playingSamples[i] noteTag]))) {
		[playingSamples[i] deactivate];
		sustained[i] = NO;
	    }	    
	}	
    }
#endif
		
    return self;
}

// Early out, no different from just stopping all playing samples.
- abort
{
    return [self allNotesOff];
}

#if 0 // antiquated
- recordSound: (MKNote *) note
{
  if (!recorder)
    recorder = [[SoundRecorder allocFromZone:[self zone]] init];
  else if ([recorder isActive])
    [self deactivate:UNASSIGNED_SAMPLE_KEYNUM]; // LMS this should be some sort of unassigned noteTag, not KeyNum
  recordKey = [note keyNum];
  recordTag = [note noteTag];
  [recorder startRecording];
  return self;
}
#endif

#ifdef GNUSTEP
#define TIMEDSENDTO(conductor,receiver,selector,dt,arg) \
  { /* NSLog(@"dt=%lf\n",dt); */ \
    if (dt) [conductor sel:selector to:receiver withDelay:(dt) argCount:1,arg]; \
    else (*(objc_msg_lookup(receiver, selector)))(receiver, selector); \
  }

#else
#define TIMEDSENDTO(conductor,receiver,selector,dt,notetag_arg) \
  { /* NSLog(@"dt=%lf\n",dt); */ \
    if (dt) [conductor sel:selector to:receiver withDelay:(dt) argCount:1,notetag_arg]; \
    else [receiver performSelector: selector withObject: (id) notetag_arg]; \
  }
#endif

/*
NSInvocation *untimedMessage = [NSInvocation invocationWithMethodSignature:(NSMethodSignature *)signature
    [untimedMessage setSelector: selector];
    [untimedMessage setArgument: notetag_arg atIndex: 1];
    [untimedMessage invokeWithTarget: receiver];
*/

// The problem is currently we can't request a Snd instance to play at some future moment in time
// with respect to the playback clock like we can with the MIDI driver used within MKMidi.
// Therefore we use the conductor to time sending a message in the future to play the sound file at the
// deltaT offset and pray there isn't too much overhead playing the sound.
// Future playback methods should be introduced into Snd to take advantage of any 
// operating system support for playback scheduling.
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    MKNoteType type = [aNote noteType];
    int     noteTag = [aNote noteTag];
    MKConductor *conductor = [aNote conductor];

    // [MKConductor sel:to:withDelay:argCount:] takes delay parameters in beats.
    double  deltaT = MKGetDeltaT() / [conductor beatSize]; 

//    NSLog(@"MKSamplePLayer::realizeNote - deltaT = %lf beatSize = %lf tempo = %lf\n", deltaT, [conductor beatSize], [conductor tempo]);
    if ((type == MK_noteOn) || (type == MK_noteDur)) {
        [self prepareSoundWithNote: aNote];
        
        {
          [self playSampleNote: aNote];
        }
    }
    else if ((type == MK_noteOff) && !damperOn) {
        [self stopSampleNote: aNote inFuture: deltaT];
    }

    if (MKIsNoteParPresent(aNote, MK_amp)) {
        linearAmp = MKGetNoteParAsDouble(aNote, MK_amp);
        TIMEDSENDTO(conductor, self, @selector(setAmp:), deltaT, noteTag);
    }
    if (MKIsNoteParPresent(aNote, MK_bearing)) {
        bearing = MKGetNoteParAsDouble(aNote, MK_bearing);
        TIMEDSENDTO(conductor, self, @selector(setBearing:), deltaT, noteTag);
    }
    if (MKIsNoteParPresent(aNote, MK_pitchBendSensitivity)) {
        pitchbendSensitivity = MKGetNoteParAsDouble(aNote, MK_pitchBendSensitivity);
        pbSensitivity = (pitchbendSensitivity / 12.0) / 8192.0;
    }
    if (MKIsNoteParPresent(aNote, MK_pitchBend)) {
        double bend = MKGetNoteParAsDouble(aNote, MK_pitchBend);
        pitchBend = pow(2.0, (bend - 8192.0) * pbSensitivity);
        TIMEDSENDTO(conductor, self, @selector(setPitchBend:), deltaT, noteTag);
    }
    // control value to perform recording. Needs updating
    //if (isControlPresent(aNote, recordModeController))
    //	recordMode = getControlValAsInt(aNote, recordModeController) > 0;
    if (MKIsNoteParPresent(aNote, MK_controlChange)) {
        int controller = MKGetNoteParAsInt(aNote, MK_controlChange);

        if (controller == MIDI_DAMPER) {
            damperOn = (MKGetNoteParAsInt(aNote, MK_controlVal) >= 64);
            if (!damperOn)
                [self stopSampleNote: aNote inFuture: deltaT];
        }
        else if (controller == MIDI_MAINVOLUME) {
            volume = (float)MKGetNoteParAsInt(aNote, MK_controlVal) / 127.0;
            TIMEDSENDTO(conductor, self, @selector(setVolume:), deltaT, noteTag);
        }
        else if (controller == MIDI_PAN) {
            bearing = -45 + 90.0 * (MKGetNoteParAsInt(aNote, MK_controlVal)/127.0);
            TIMEDSENDTO(conductor, self, @selector(setBearing:), deltaT, noteTag);
        }
    }

    if (type == MK_mute) {
        if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysReset)
            [self reset];
        else if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysStop)
            [self stopSampleNote: aNote inFuture: 0.0];
    }

    return self;
}

// When the sound completes playing, either through premature stopping or coming to the end of the sound,
// we need to remove the note and the performance it points to from the playingNotes dictionary.
// Ideally we need a double linked dictionary, that allows us to find a key given it's object, but for now
// we can be inefficient and use an exhaustive search.
- (void) didPlay: (Snd *) sound duringPerformance: (SndPerformance *) performance
{
    NSArray *notesPlayingPerformance;

    // NSLog(@"did finish playing sound named %@, performance %@\n", [sound name], performance);
    notesPlayingPerformance = [playingNotes allKeysForObject: performance];
    // NSLog(@"playingNotes %@, notesPlayingPerformance = %@\n", playingNotes, notesPlayingPerformance);
    
    // since each performance is unique, there will only be one note playing that performance,
    // so we could skip iterating.
    [playingNotes removeObjectForKey: [notesPlayingPerformance objectAtIndex: 0]];
}

- (void) encodeWithCoder:(NSCoder *) coder
  /* Archive the instrument to a typed stream. */
{
  [super encodeWithCoder:coder];
  [coder encodeValuesOfObjCTypes:"iiiccci", &keyNum, &testKey, 
	 &voiceCount, &diatonic, &tieRepeats, &preloadingEnabled,
	 &recordModeController];
}

- (id)initWithCoder:(NSCoder *) decoder
  /* Unarchive the instrument from a typed stream. */
{
  [super initWithCoder: decoder];
  if ([decoder versionForClassName: @"MKSamplerInstrument"] == 1) {
    [decoder decodeValuesOfObjCTypes:"iiiccci", &keyNum, &testKey,
	     &voiceCount, &diatonic, &tieRepeats, &preloadingEnabled, &recordModeController];
  }
  /* Initialize certain non-archived data */
  linearAmp = MKdB(amp);
  [self init];
  return self;
}

@end
