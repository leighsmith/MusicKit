/*
  $Id$
  Defined In: The MusicKit

  Description:
    Rewritten from original code by Michael McNabb as part of the Ensemble open source program.
    Each MKSamplerInstrument holds a collection of sound files indexed by noteTag.
    There is a PlayingSound for each sound file.
    A MKNote has a MK_filename parameter which is the soundfile to be played, together with any
    particular tuning deviation to be applied to it using a keynumber or frequency which forms a ratio
    from the unity key number located in the (AIFF or RIFF (.wav)). That does imply being able to load the file
    immediately (within the Delta) for playback. But then, we should be spooling from disk anyway.

  Original Author: Leigh M. Smith <leigh@tomandandy.com>

  Copyright (c) 1999 tomandandy, Inc.
*/
/*
  $Log$
  Revision 1.6  2000/04/12 00:36:28  leigh
  Hacked to use either SndKit or NSSound, depending on which is more complete on each platform, added uglySamplerTimingHack, hopefully this is only a momentary lapse of reason

  Revision 1.5  2000/03/31 00:11:31  leigh
  Cleaned up cruft

  Revision 1.4  2000/03/11 01:16:21  leigh
  Now using NSSound to replace Snd

  Revision 1.3  1999/09/26 20:05:31  leigh
  Removed definition of MK_filename

  Revision 1.2  1999/09/24 16:47:20  leigh
  Ensures only stopping a note with a filename

  Revision 1.1  1999/09/22 16:06:31  leigh
  Added sample playback support

*/
// 1 to use the SndKit, 0 to use NSSound
// MacOsX-Server works more reliably with SndKit, NSSound is more complete on MacOsX DP3.
#define USE_SNDKIT 1  
#import "_musickit.h"
#import "MKSamplerInstrument.h"

#define UNASSIGNED_SAMPLE_KEYNUM (-1)

static int activeSoundCount = 0;

// This should be zero or I should rot in purgatory for my sins.
// This can typically be expected to be so dependent on operating system and platform that it will be
// nearly impossible to set correctly. See realizeNote: for why this has to exist.
static float uglySamplerTimingHack = 0.0;

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
    if (!soundTable) {
        soundTable = [NSMutableDictionary dictionaryWithCapacity: 32];
        [soundTable retain];
    }
    else
        [soundTable removeAllObjects];
    uglySamplerTimingHack = [[NSUserDefaults standardUserDefaults] floatForKey: @"MKUglySamplerTimingHack"];
    [self addNoteReceiver:[[MKNoteReceiver alloc] init]];

    conductor = [[MKConductor defaultConductor] retain];
    playingNotes = [[NSMutableArray arrayWithCapacity: 20] retain]; 

    [self reset];
    return self;
}

- releaseSounds
  /* Free all the sound structs */
{
    [MKConductor lockPerformance];
    [soundTable removeAllObjects];
    [MKConductor unlockPerformance];
    return self;
}

- (void) dealloc
  /*
  * Free the sound structs, the filename strings, the hash tables, and the
  * window.
  */
{
    [self releaseSounds];
    [soundTable release];
    [playingNotes release];
    [conductor release];
}

- clearAll:sender
{
//  [soundOutDevice abortStreams:nil];
    [self releaseSounds];
    return self;
}

// Prepare by preparing the PlayingSound instance
- prepareSoundWithNote: (MKNote *) aNote
{
    int velocity;
    int key;
    int baseKey;
    int noteTag;
    WorkingSoundClass *newSound;
    NSString *filePath;

    // NSLog(@"Preparing %@\n", aNote);
    // only prepare those notes which are samples.
    if(![aNote isParPresent: MK_filename])
        return nil;

    key = [aNote keyNum];
    baseKey = key;   // should be baseKey = [sound unityKeyNum];
    noteTag = [aNote noteTag];

    filePath = [aNote parAsString: MK_filename];
    // either retrieve playingSample from the table of playing sounds according to the filename or create afresh.
    if ([WorkingSoundClass soundNamed: filePath] != nil) {     // check if the sound file is already loaded.
        // NSLog(@"Already loaded for keyNum %d %@\n", key, filePath);
        return nil;
    }

    // not loaded, load it now.
    // read soundfile, for now loading it into a WorkingSoundClass object, eventually priming the buffers for play direct from disk.
#if USE_SNDKIT
    if ((newSound = [Snd addName: filePath fromSoundfile: filePath]) == nil) {
#else
    if ((newSound = [[NSSound alloc] initWithContentsOfFile: filePath byReference: NO]) == nil) {
#endif
        _MKErrorf(MK_cantOpenFileErr, filePath);
        return nil;
    }
    [newSound setName: filePath];
    velocity = [aNote parAsInt: MK_velocity];
    return self;
}

- playSampleNote: aNote
{
    WorkingSoundClass *existingSound;
    NSString *filePath;

    // only play those notes which are samples.
    if(![aNote isParPresent: MK_filename])
        return nil;
    filePath = [aNote parAsString: MK_filename];
    // NSLog(@"playing file %@\n", filePath);

    if ((existingSound = [WorkingSoundClass soundNamed: filePath]) == nil) {
        _MKErrorf(MK_cantOpenFileErr, filePath);
        return nil;
    }
    [existingSound setDelegate:self];
    [playingNotes addObject: aNote];    // keep a list (ordered oldest to youngest) of playing notes.
    [existingSound play]; // just do it.
    return self;
}

// Probably should revamp this to determine the playingSound instance to send the stop to.
- stopSampleNote: aNote
{
    WorkingSoundClass *existingSound;
    NSString *filePath;

    //NSLog(@"stopping sample note %@\n", aNote);

    // only stop playing those notes which are samples.
    if(![aNote isParPresent: MK_filename]) {
        // NSLog(@"Not a sample note, can't stop!\n");
        return nil;
    }
    filePath = [aNote parAsString: MK_filename];

    if ((existingSound = [WorkingSoundClass soundNamed: filePath]) == nil) {
        _MKErrorf(MK_cantOpenFileErr, filePath);
        return nil;
    }
    // locking playback
    // NSLog(@"sound is playing %d\n", [existingSound isPlaying]);
    [playingNotes removeObject: aNote];
    [existingSound stop]; // just do it.
    return self;
}


- stop
{
    unsigned int noteIndex;

    for(noteIndex = 0; noteIndex < [playingNotes count]; noteIndex++)
	[self stopSampleNote: [playingNotes objectAtIndex: noteIndex]];
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

- performerDidActivate:sender
{
    NSLog(@"Got playingSample delegate activation notice\n");
    activeVoices++;
    activeSoundCount++;
    return self;
}

- performerDidDeactivate:sender
{
    NSLog(@"Got playingSample delegate deactivation notice\n");
    if (activeVoices > 0) activeVoices--;
    if (activeSoundCount > 0) activeSoundCount--;
    return self;
}

// set the limit of voices to simultaneously play
// FIXME needs a value to prevent limiting.
- (void) setVoiceCount:(int) newVoiceCount
{
    voiceCount = newVoiceCount;
}

- (int) voiceCount
{
    return voiceCount;
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
//  int i;

#if 0 // only needed when we are recording.
  if (noteTag == recordTag) {
    WorkingSoundClass *newSound, *oldSound;

    [recorder stopRecording];
    newSound = [recorder soundStruct];
    oldSound = [soundTable insertKey:(const void *)recordKey value:(void *)newSound];
    [self clearAtKey:recordKey];
    if (!playingSamples[recordKey]) {
    playingSamples[recordKey] = [[WorkingSoundClass alloc] initWithSound:newSound];
      [playingSamples[recordKey] setDelegate:self];
      [playingSamples[recordKey] enablePreloading:preloadingEnabled];
    }
    else
      [playingSamples[recordKey] setSoundStruct:newSound];
    recordTag = recordKey = UNASSIGNED_SAMPLE_KEYNUM; // LMS not the right definition.
  }
#endif
#if 0
  if (noteTag >= 0)
    for (i = 0; i < MAX_PERFORMERS; i++)
      if (playingSamples[i] && ((noteTag == MAXINT) || (noteTag == [playingSamples[i] noteTag]))) {
	[playingSamples[i] deactivate];
	sustained[i] = NO;
      }
#endif
  
  return self;
}

- abort
{
//  int i;
#if 0
  if ([recorder isActive])
    [recorder stopRecording];
#endif
//  for (i = 0; i < MAX_PERFORMERS; i++) {
//    [playingSamples[i] abort];
//    sustained[i] = NO;
//  }
  return self;
}

#if 0 // antiquated
- recordSound:note
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

#define TIMEDSENDTO(receiver,selector,dt,arg) \
  { if (dt) [conductor sel:selector to:receiver withDelay:(dt) argCount:1,arg]; \
    else objc_msgSend(receiver,selector,arg); \
  }

// The problem is currently we can't request a WorkingSoundClass instance to play at some future moment in time
// with respect to the playback clock like we can with the MIDI driver used within MKMidi.
// Therefore we use the conductor to time sending a message in the future to play the sound file at the
// deltaT offset and pray there isn't too much overhead playing the sound.
// Future playback methods should be introduced into NSSound to take advantage of any 
// operating system support for playback scheduling.
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    MKNoteType type = [aNote noteType];
    int     noteTag = [aNote noteTag];
    // [MKConductor sel:to:withDelay:argCount:] takes delay parameters in beats.
    double  deltaT = (MKGetDeltaT() + uglySamplerTimingHack) / [conductor beatSize]; 

    // NSLog(@"deltaT = %lf beatSize = %lf tempo = %lf\n", deltaT, [conductor beatSize], [conductor tempo]);
    if ((type == MK_noteOn) || (type == MK_noteDur)) {
        [self prepareSoundWithNote: aNote];
        TIMEDSENDTO(self, @selector(playSampleNote:), deltaT, aNote);
        if (type == MK_noteDur) {
            TIMEDSENDTO(self, @selector(stopSampleNote:), deltaT+[aNote dur], aNote);
        }
    }
    else if ((type == MK_noteOff) && !damperOn) {
        TIMEDSENDTO(self, @selector(stopSampleNote:), deltaT, aNote);
    }

    if (MKIsNoteParPresent(aNote, MK_amp)) {
        linearAmp = MKGetNoteParAsDouble(aNote, MK_amp);
        TIMEDSENDTO(self, @selector(setAmp:), deltaT, noteTag);
    }
    if (MKIsNoteParPresent(aNote, MK_bearing)) {
        bearing = MKGetNoteParAsDouble(aNote, MK_bearing);
        TIMEDSENDTO(self, @selector(setBearing:), deltaT, noteTag);
    }
    if (MKIsNoteParPresent(aNote, MK_pitchBendSensitivity)) {
        pitchbendSensitivity = MKGetNoteParAsDouble(aNote, MK_pitchBendSensitivity);
        pbSensitivity = (pitchbendSensitivity / 12.0) / 8192.0;
    }
    if (MKIsNoteParPresent(aNote, MK_pitchBend)) {
        double bend = MKGetNoteParAsDouble(aNote, MK_pitchBend);
        pitchBend = pow(2.0, (bend - 8192.0) * pbSensitivity);
        TIMEDSENDTO(self, @selector(setPitchBend:), deltaT, noteTag);
    }
    // control value to perform recording. Needs updating
    //if (isControlPresent(aNote, recordModeController))
    //	recordMode = getControlValAsInt(aNote, recordModeController) > 0;
    if (MKIsNoteParPresent(aNote, MK_controlChange)) {
#if 0
        int controller = MKGetNoteParAsInt(aNote, MK_controlChange);

        if (controller == MIDI_DAMPER) {
        damperOn = (MKGetNoteParAsInt(aNote, MK_controlVal) >= 64);
        if (!damperOn)
            TIMEDSENDTO(self, @selector(stopSampleNote:), deltaT, aNote);
        }
        else if (controller == MIDI_MAINVOLUME) {
            volume = (float)MKGetNoteParAsInt(aNote, MK_controlVal) / 127.0;
            TIMEDSENDTO(self, @selector(setVolume:), deltaT, noteTag);
        }
        else if (controller == MIDI_PAN) {
            bearing = -45 + 90.0 * (MKGetNoteParAsInt(aNote, MK_controlVal)/127.0);
            TIMEDSENDTO(self,@selector(setBearing:), deltaT, noteTag);
        }
        else if (controller == 14) {
            /* Mostly for 2.1 compatibility */
            int headphoneLevel =
                (int)(-84.0 + MKGetNoteParAsDouble(aNote, MK_controlVal)*.66142);
            [soundOutDevice setAttenuationLeft: headphoneLevel right: headphoneLevel];
        }
#endif
    }

    if (((type == MK_noteOn) || (type == MK_noteDur)) && !recordMode) {
        //TIMEDSENDTO(self, @selector(activate:), deltaT, noteTag);
    }
    else if (type == MK_mute) {
        if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysReset)
            [self reset];
        else if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysStop)
            TIMEDSENDTO(self, @selector(stopSampleNote:), 0.0, aNote);
    }

    return self;
}

// NSSound delegate
- (void) sound:(WorkingSoundClass *) sound didFinishPlaying:(BOOL) finished
{
    NSLog(@"did finish playing %d sound named %@\n", finished, [sound name]);
    if(finished) {
        // unlock playback
    }
}

- (void) encodeWithCoder:(NSCoder *) coder
  /* Archive the instrument to a typed stream. */
{
  [super encodeWithCoder:coder];
  [coder encodeValuesOfObjCTypes:"ii@iccci", &keyNum, &testKey, &soundTable,
	 &voiceCount, &diatonic, &tieRepeats, &preloadingEnabled,
	 &recordModeController];
}

- (id)initWithCoder:(NSCoder *) decoder
  /* Unarchive the instrument from a typed stream. */
{
  [super initWithCoder: decoder];
  if ([decoder versionForClassName:@"SamplerInstrument"] == 1) {
    [decoder decodeValuesOfObjCTypes:"ii@iccci", &keyNum, &testKey, &soundTable,
	     &voiceCount, &diatonic, &tieRepeats, &preloadingEnabled, &recordModeController];
  }
  /* Initialize certain non-archived data */
  linearAmp = MKdB(amp);
  [self reset];
  [self init];
  return self;
}

@end
