////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//  SndKit
//
//  Description:
//     Snd subclass reading MP3 files. 
//
//  Super experimental - to be folded back into Snd eventually, but we want
//  mp3 power NOW!
//
//  TODO: - This is only good for 44.1 stereo MP3s at the moment.
//        - need to dynamically unpack bitstream to linear on as-needed basis
//          (support on-the-fly fillAudioBuffer type action), currently we
//          decode on loading
//        - Seek support - the frame header table is constructed and ready to go.
//
//  Original Author: SKoT McDonald <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <lame/lame.h>
#import "SndMP3.h"
#import "SndError.h"
#import "SndAudioBuffer.h"

#define SNDMP3_DEBUG_READING 0
#define SNDMP3_DEBUG 0
#define SNDMP3_DEBUG_FRAME_COUNTING 0

// This defines that we decode the entire MP3 into memory (yikes!) then fetch from there.
#define DECODE_ENTIRE_INTO_MEMORY 0

#define MP3_BITRATE_BAD  -1
#define MP3_BITRATE_FREE -2
#define MP3_BITRATEINDEX_BAD  0
#define MP3_BITRATEINDEX_FREE 15

static NSLock *decoderLock;

#if 0 // disable this until we need it to stop warnings
static const char *const genre_names[] =
{
  /*
   * NOTE: The spelling of these genre names is identical to those found in
   * Winamp and mp3info.
   */
  "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge",
  "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
  "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska",
  "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop",
  "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", "Instrumental",
  "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise", "Alt. Rock",
  "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop",
  "Instrumental Rock", "Ethnic", "Gothic", "Darkwave", "Techno-Industrial",
  "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy",
  "Cult", "Gangsta Rap", "Top 40", "Christian Rap", "Pop/Funk", "Jungle",
  "Native American", "Cabaret", "New Wave", "Psychedelic", "Rave",
  "Showtunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz",
  "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock", "Folk",
  "Folk/Rock", "National Folk", "Swing", "Fast-Fusion", "Bebob", "Latin",
  "Revival", "Celtic", "Bluegrass", "Avantgarde", "Gothic Rock",
  "Progressive Rock", "Psychedelic Rock", "Symphonic Rock", "Slow Rock",
  "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech",
  "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass",
  "Primus", "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba",
  "Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet",
  "Punk Rock", "Drum Solo", "A Cappella", "Euro-House", "Dance Hall",
  "Goa", "Drum & Bass", "Club-House", "Hardcore", "Terror", "Indie",
  "BritPop", "Negerpunk", "Polsk Punk", "Beat", "Christian Gangsta Rap",
  "Heavy Metal", "Black Metal", "Crossover", "Contemporary Christian",
  "Christian Rock", "Merengue", "Salsa", "Thrash Metal", "Anime", "JPop",
  "Synthpop"
};

#define GENRE_NAME_COUNT \
((int)(sizeof genre_names / sizeof (const char *const)))
#endif

////////////////////////////////////////////////////////////////////////////////
// SndMP3DecodeJob
////////////////////////////////////////////////////////////////////////////////

@interface SndMP3DecodeJob : NSObject {
  double startTime;
  double duration;
}

- initWithStartTime: (double) _startTime duration: (double) _duration;
- (double) startTime;
- (double) duration;

@end

@implementation SndMP3DecodeJob

- initWithStartTime: (double) _startTime duration: (double) _duration
{
  self = [super init];
  if (self) {
    startTime = _startTime;
    duration  = _duration;
  }
  return self;
}

- (double) startTime { return startTime; }
- (double) duration  { return duration;  }
- (double) endTime   { return startTime + duration;   }

@end

////////////////////////////////////////////////////////////////////////////////
// SndMP3
////////////////////////////////////////////////////////////////////////////////

@implementation SndMP3

// YES to use separate threaded predecoder (more memory hungry), NO to decode on the fly (more processor hungry)
//static BOOL preDecode = YES; 
static BOOL preDecode = DECODE_ENTIRE_INTO_MEMORY;

static int bitrateLookupTable[16][6] = {
  { MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD, MP3_BITRATE_BAD },
  {  32,  32,  32,  32,   8,   8 },
  {  64,  48,  40,  48,  16,  16 },
  {  96,  56,  48,  56,  24,  24 },
  { 128,  64,  56,  64,  32,  32 },
  { 160,  80,  64,  80,  40,  40 },
  { 192,  96,  80,  96,  48,  48 },
  { 224, 112,  96, 112,  56,  56 },
  { 256, 128, 112, 128,  64,  64 },
  { 288, 160, 128, 144,  80,  80 },
  { 320, 192, 160, 160,  96,  96 },
  { 352, 224, 192, 176, 112, 112 },
  { 384, 256, 224, 192, 128, 128 },
  { 416, 320, 256, 224, 144, 144 },
  { 448, 384, 320, 256, 160, 160 },
  { MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE, MP3_BITRATE_FREE }
};

+ (NSArray *) soundFileExtensions
{
    return [[super soundFileExtensions] arrayByAddingObject: @"mp3"];
}

+ (void) setPreDecode: (BOOL) yesOrNo
{
    // Set the class to use a separate threaded predecoder if YES, if NO, decode MP3 data when reading it.
    preDecode = yesOrNo;
}

+ (BOOL) preDecode
{
    return preDecode;
}

- (void) checkID3Tag: (NSData*) _mp3Data
{
  const unsigned char *pData = [_mp3Data bytes];
  long length = [_mp3Data length];

  if (length >= 128 && strcmp(pData + length - 128, "TAG") == 0) {
    const char *id3base = pData + length - 128;
    const char *title   = id3base + 3;
    const char *artist  = title  + 30;
    const char *album   = artist + 30;
    const char *year    = album  + 30;
    const char *comment = year   + 4;
    const char *trackNumber = id3base + 126;
    const char *genre   = id3base + 127;

    NSLog(@"ID3 tag\n");
    NSLog(@"Title:       %30s\n", title);
    NSLog(@"Artist:      %30s\n", artist);
    NSLog(@"Album:       %30s\n", album);
    NSLog(@"year:        %4s\n", year);
    NSLog(@"Comment:     %30s\n", comment);
    NSLog(@"TrackNumber: %d\n", trackNumber[0]);
    NSLog(@"Genre:       %d\n", genre[0]);
  }
  else {
//    NSLog(@"No ID3 tag found\n");
  }
}

static unsigned long getFrameHeaderAt(const unsigned char *bitstream)
{
    return (unsigned long) (bitstream[0] << 24) + (bitstream[1] << 16) + (bitstream[2] << 8) + bitstream[3];
}

// Return -1 on error, otherwise size of frame in bytes.
- (int) frameSizeOfHeader:  (unsigned long) frameHeader
{
    int frameSize, samplingRate = [self samplingRate];
    float framesPerSecond;
    int layer, bitrateIndex, version = 0, bitrate, samplesPerFrame = SND_MPEGV1_SAMPLES_PER_FRAME;

    if (!((frameHeader >> 21) & 0x07FF))
        return -1;

    switch ((frameHeader >> 19) & 0x03) {
	case 0: 
	case 1: break;
	case 2: version = 2; samplesPerFrame = SND_MPEGV2_SAMPLES_PER_FRAME; break;
	case 3: version = 1; break;
    }
    layer =  4 - ((frameHeader >> 17) & 0x03);

    bitrateIndex = (frameHeader >> 12) & 0xF;
    bitrate = bitrateLookupTable[bitrateIndex][(version - 1) * 3 + layer - 1];
    //NSLog(@"Samples per frame: %i\n",samplesPerFrame);
    framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
    //NSLog(@"FramesPerSecond: %f\n", framesPerSecond);

    // 125 = 100 / 8, rounded up.
    frameSize = (bitrate * 125 / framesPerSecond) + 0.5;
    NSLog(@"FrameSize: %i\n", frameSize);
    return frameSize;
}

- (void) dumpFrameHeader: (unsigned long) frameHeader
{
    int frameSize, samplingRate = [self samplingRate];
    float framesPerSecond;
    int layer, bitrateIndex, version = 0, bitrate, samplesPerFrame = SND_MPEGV1_SAMPLES_PER_FRAME;

    if ((frameHeader >> 21) & 0x07FF)
	NSLog(@"frame sync is ok\n");
    else
	NSLog(@"bad frame sync\n");

    NSLog(@"version: ");
    switch ((frameHeader >> 19) & 0x03) {
	case 0: NSLog(@"MPEG 2.5\n"); break;
	case 1: NSLog(@"reserved\n"); break;
	case 2: NSLog(@"MPEG v2\n"); version = 2; samplesPerFrame = SND_MPEGV2_SAMPLES_PER_FRAME; break;
	case 3: NSLog(@"MPEG v1\n"); version = 1; break;
    }
    layer =  4 - ((frameHeader >> 17) & 0x03);
    switch (layer) {
	case 3: NSLog(@"Layer 3\n"); break;
	case 2: NSLog(@"Layer 2\n"); break;
	case 1: NSLog(@"Layer 1\n"); break;
	case 0:
	default:
	    NSLog(@"reserved\n");
    }
    NSLog(@"Protected by CRC: %s\n", (frameHeader >> 16) & 0x1 ? "no" : "yes");

    bitrateIndex = (frameHeader >> 12) & 0xF;
    bitrate = bitrateLookupTable[bitrateIndex][(version - 1) * 3 + layer - 1];
    NSLog(@"Bitrate: %i (index: %i)\n", bitrate, bitrateIndex);

    NSLog(@"Sampling frequency index: %li\n", (frameHeader >> 10) & 0x3);
    NSLog(@"Padding: %s\n", (frameHeader >> 9) & 0x1 ? "yes" : "no");
    NSLog(@"Channel Mode: %li\n", (frameHeader >> 6) & 0x3);
    NSLog(@"Mode extension: %li\n", (frameHeader >> 4) & 0x3);
    NSLog(@"Copyright: %s\n", (frameHeader >> 3) & 0x1 ? "yes" : "no");
    NSLog(@"Original: %s\n", (frameHeader >> 2) & 0x1 ? "yes" : "no");
    NSLog(@"Emphasis: %li\n", frameHeader & 0x3);

    NSLog(@"Samples per frame: %i\n",samplesPerFrame);
    framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
    NSLog(@"FramesPerSecond: %f\n", framesPerSecond);
    frameSize = bitrate * 125 / framesPerSecond; // 125 = 100 / 8
    NSLog(@"FrameSize: %i\n", frameSize);
}    

// Creates the encodedFrameLocations array and it's count.
- (int) findFrameHeadersInBitstream: (NSData *) mp3DataToSearch
{
    int layer, bitrateIndex, version = 0, bitrate = 0, samplesPerFrame = SND_MPEGV1_SAMPLES_PER_FRAME;
    int frameSize, samplingRate = [self samplingRate];
    float framesPerSecond;
    const unsigned char *bitstream = [mp3DataToSearch bytes];
    long mp3LengthInBytes = [mp3DataToSearch length];
    long maxencodedFrameLocationsCount = 512;  // mp3LengthInBytes/ length
    long  position = 0;

    encodedFrameLocationsCount = 0;

    if (encodedFrameLocations)
	free(encodedFrameLocations);

    if((encodedFrameLocations = (long *) malloc(sizeof(long) * maxencodedFrameLocationsCount)) == NULL) {
	NSLog(@"Unable to allocate memory for frame locations\n");
	return -1;
    }
	
    // ok, we are going looking for frame headers:
    // unsigned char *pCh = (unsigned char*) &frameHeader;

    while (position < mp3LengthInBytes) {
        // Scan until we find a 0xFF, followed by the top three bits (0xE0) of the following byte set.
	while (bitstream[position] != (unsigned char) 0xFF && (position < mp3LengthInBytes)) {
	    position++;
	}
	if (position < mp3LengthInBytes - 1 && (bitstream[position+1] & 0xE0) == 0xE0) {
            unsigned long frameHeader = getFrameHeaderAt(bitstream + position);

	    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileFormat"]) {
		[self dumpFrameHeader: frameHeader];
	    }

	    position += 4;

	    if (((frameHeader >> 24) & 0xE0) == 0xE0) {

		switch ((frameHeader >> 19) & 0x03) {
		    case 0:
                        //NSLog(@"MPEG 2.5\n");
			break;
		    case 1:
                        //NSLog(@"reserved\n");
			break;
		    case 2:
                        //NSLog(@"MPEG v2\n");
			version = 2;
			samplesPerFrame = SND_MPEGV2_SAMPLES_PER_FRAME;
			break;
		    case 3:
                        //NSLog(@"MPEG v1\n");
			version = 1;
			samplesPerFrame = SND_MPEGV1_SAMPLES_PER_FRAME;
			break;
		}
		layer =  4 - ((frameHeader >> 17) & 0x03);
		if (layer == 4) { // something is wrong!
		    position++;
		}
		else {
		    bitrateIndex = (frameHeader >> 12) & 0x0F;
		    if (bitrateIndex == MP3_BITRATEINDEX_BAD) {
			position++;
			continue;
		    }
		    if (bitrateIndex != MP3_BITRATEINDEX_FREE) { // free
			int formatIndex = (version - 1) * 3 + layer - 1;
			bitrate = bitrateLookupTable[bitrateIndex][formatIndex];
		    }
		    framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
		    frameSize = bitrate * 125 / framesPerSecond; // 125 = 100 / 8
#if SNDMP3_DEBUG_FRAME_COUNTING
                    {
                        float time = (float) encodedFrameLocationsCount * samplesPerFrame / (float) samplingRate;
                        NSLog(@"[Frame: %li] Header found at: %li  (t:%.2f sample:%li)\n",
                                encodedFrameLocationsCount, position - 4, time, (encodedFrameLocationsCount - 1) * samplesPerFrame);
                    }
#endif
                    // Each time we exceed the maximum frame locations count, we double that number and reallocate.
		    if (encodedFrameLocationsCount == maxencodedFrameLocationsCount) {
			maxencodedFrameLocationsCount <<= 1;
			encodedFrameLocations = (long *) realloc(encodedFrameLocations, sizeof(long) * maxencodedFrameLocationsCount);
			if(encodedFrameLocations == NULL) {
			    NSLog(@"Unable to reallocate frame location memory to %ld longs\n", maxencodedFrameLocationsCount);
			    return -1;
			}
		    }
		    encodedFrameLocations[encodedFrameLocationsCount] = position - 4;
		    encodedFrameLocationsCount++;
		    position += frameSize - 4;
		}
	    }
	}
	else {
	    position++;  // byte following 0xFF didn't have it's top three bits set, skip over and continue.
	}
    }
    // condense allocated memory to just the frame locations found...
    encodedFrameLocations = (long *) realloc(encodedFrameLocations, sizeof(long) * encodedFrameLocationsCount);
    if(encodedFrameLocations == NULL) {
	NSLog(@"Unable to reallocate frame location memory to %ld longs\n", encodedFrameLocationsCount);
	return -1;
    }
    
#if SNDMP3_DEBUG_FRAME_COUNTING
     {
	 long i;
	 for (i = 0; i < encodedFrameLocationsCount; i++) {
	     NSLog(@"frame: %04li location: %07li\n", i, encodedFrameLocations[i]);
	 }
     }
#endif
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Snd overrides required for simple playback operation
////////////////////////////////////////////////////////////////////////////////

+ (void) initialize
{
    decoderLock = [NSLock new];
}

- init
{
    self = [super init];
    if (self) {
        encodedFrameLocations = NULL;
        encodedFrameLocationsCount = 0;
        currentMP3FrameID = -1;
        pcmDataLock = [NSLock new];
    }
    return self;
}

- (long) lengthInSampleFrames
{
    // [pcmData length] / (sizeof(short) * 2);
    return lengthInSampleFrames;
}

- (double) duration
{
    return duration;
    //  return [self lengthInSampleFrames] / [self samplingRate];
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@ with duration: %.2f samples: %i sampleRate: %.2f channels: %i",
        [super description], [self duration], [self lengthInSampleFrames], [self samplingRate], [self channelCount]];
}

- (double) samplingRate
{
    return 44100.0;
}

- (int) channelCount
{
    return 2;
}

// We completely spoof this for now. This will cause us problems if the native format is anything other
// than 44100 and 2 channels. However, the data format can differ and we will convert correctly in
// insertIntoAudioBuffer:
- (int) convertToNativeFormat
{
    SndFormat nativeFormat = [Snd nativeFormat];

#if 0    
    if(nativeFormat.sampleRate != [self samplingRate] || nativeFormat.channelCount != [self channelCount]) {
	NSLog(@"MP3 file sample rate %lf, channels %d not of native format sample rate %lf, channels %d\n",
	    [self samplingRate], [self channelCount], nativeFormat.sampleRate, nativeFormat.channelCount);
	return SND_ERR_UNKNOWN;
    }
#else
    if(nativeFormat.sampleRate != [self samplingRate]) {
	NSLog(@"MP3 file sample rate %lf not native format sample rate %lf\n", [self samplingRate], nativeFormat.sampleRate);
	return SND_ERR_UNKNOWN;
    }
    else {
        return [super convertToNativeFormat];
    }
#endif
    
    return SND_ERR_NONE;
}

- (void) dealloc
{
    [mp3Data release];
    mp3Data = nil;
    [pcmData release];
    pcmData = nil;
    [pcmDataLock release];
    pcmDataLock = nil;
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// decodeThread
////////////////////////////////////////////////////////////////////////////////

- (void) decodeThread: (SndMP3DecodeJob*) job
{
  NSAutoreleasePool *localPool = [NSAutoreleasePool new];

  int growSize = [self samplingRate] * 4;
  int pcmSize  = growSize;
  short pcm_l[10000], pcm_r[10000]; // conversion buffers
  long mp3DataPos    = 0;
  long mp3DataLength = [mp3Data length];
  //    long length = 0;
  long sams_created = 0;
  long sams_created_total = 0;
  unsigned char* mp3DataBytes = (unsigned char*) [mp3Data bytes];
  long requestedStartSample = 0, requestedSampleCount = 0, iterations = 0;
  long samplesToStartIndex = 0;
  long samplesRecovered = 0;
  //    long frameID = 0;

  bDecoding = TRUE;

  requestedStartSample = [job startTime] * [self samplingRate];
  requestedSampleCount = [job duration]  * [self samplingRate];

  samplesToStartIndex = requestedStartSample;

  [decoderLock lock]; 
  lame_decode_init();

  pcmData = [[NSMutableData alloc] initWithLength: pcmSize * sizeof(short) * 2];
  [pcmDataLock unlock];

  while (mp3DataPos < mp3DataLength || sams_created > 0) {
    int mp3FeedAmount = 417; // a frame
    if (mp3DataPos + mp3FeedAmount > mp3DataLength)
      mp3FeedAmount = mp3DataLength - mp3DataPos;

    sams_created = lame_decode1(mp3DataBytes + mp3DataPos, mp3FeedAmount, pcm_l, pcm_r);
    // NSLog(@"sams_created = %d\n", sams_created);
    mp3DataPos += mp3FeedAmount;

    if (sams_created > 0) {
      long i, offset = 0, pos = samplesRecovered * 2;
      long sams_to_unpack = sams_created;

      if (sams_created_total + sams_created > requestedStartSample) {
        short *pData = NULL;
        offset = requestedStartSample - sams_created_total;

        if (offset < 0)
          offset = 0;

        if (sams_to_unpack + samplesRecovered > requestedSampleCount)
          sams_to_unpack = requestedSampleCount - samplesRecovered;

        [pcmDataLock lock];
        while (samplesRecovered + sams_to_unpack > pcmSize) {
          pcmSize += growSize;
          [pcmData setLength: pcmSize * sizeof(short) * 2];
        }
        pData = [pcmData mutableBytes]; // get fresh pointer in case resize moved our data
        for (i = offset; i < sams_to_unpack; i++) {
          pData[pos++] = pcm_l[i];
          pData[pos++] = pcm_r[i];
          samplesRecovered++;
        }
        [pcmDataLock unlock];
      }
    }
    sams_created_total  += sams_created;
    decodedSampledCount += sams_created;
    iterations++;
#if SNDMP3_DEBUG_READING
    NSLog(@"[%04li] Decoded: %li/%li\n", iterations, decodedSampledCount, lengthInSampleFrames);
#endif
    if (samplesRecovered >= requestedSampleCount)
      break;
  }
  lengthInSampleFrames = samplesRecovered;
  duration    = lengthInSampleFrames / [self samplingRate];
  [pcmDataLock lock];
  [pcmData setLength: lengthInSampleFrames * sizeof(short) * 2];
  duration = lengthInSampleFrames / [self samplingRate];
  [pcmDataLock unlock];

  [decoderLock unlock];
  bDecoding = FALSE;
  [localPool release];
//  NSLog(@"Finished decoding...\n");
  [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
// readSoundfile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) loadMP3DataWithURL: (NSURL*) soundURL
{
    NSAutoreleasePool *localPool = [NSAutoreleasePool new];
    
    if (mp3Data) {
        [mp3Data release];
        mp3Data = nil;
    }
    [pcmDataLock lock];
    if (pcmData) {
        [pcmData release];
        pcmData = nil;
    }
    [pcmDataLock unlock];
    mp3Data = [[NSData alloc] initWithContentsOfURL: soundURL];
    if(mp3Data != nil) {
        [self checkID3Tag: mp3Data];
        [self findFrameHeadersInBitstream: mp3Data];
      
        lengthInSampleFrames = encodedFrameLocationsCount * SND_MPEGV1_SAMPLES_PER_FRAME;
        duration = lengthInSampleFrames / [self samplingRate];
    }
    [localPool release];
    return mp3Data != nil;
}

////////////////////////////////////////////////////////////////////////////////
// readSoundURL:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundURL: (NSURL *) soundURL
{
    SndMP3DecodeJob *job = nil;
  
    if(![self loadMP3DataWithURL: soundURL])
        return SND_ERR_CANNOT_OPEN;
#if SNDMP3_DEBUG_READING
    NSLog(@"Found %li frames\n", encodedFrameLocationsCount);
#endif

    if(preDecode) {
        job = [[SndMP3DecodeJob alloc] initWithStartTime: 0.0
                                                duration: duration];
    
        [pcmDataLock lock];
        [NSThread detachNewThreadSelector: @selector(decodeThread:)
                                 toTarget: self
                               withObject: job];
        [pcmDataLock lock];
        [pcmDataLock unlock];
        [job autorelease];
    }
    else { // initialise LAME now since it is otherwise initialised in the decodeThread:
        lame_decode_init();
    }
    // This is probably a bit kludgy but it will do for now.
    loopEndIndex = [self lengthInSampleFrames] - 1;
    return SND_ERR_NONE;
}

////////////////////////////////////////////////////////////////////////////////
// readSoundURL:startTimePosition:duration:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundURL: (NSURL*) soundURL
   startTimePosition: (double) segmentStartTime
            duration: (double) segmentDuration
{
    SndMP3DecodeJob *job = nil;
  
    if(![self loadMP3DataWithURL: soundURL])
        return SND_ERR_CANNOT_OPEN;
    if (segmentDuration == -1.0)
        segmentDuration = duration;
    

    if (segmentStartTime > duration) 
        return SND_ERR_BAD_STARTTIME;
    else if (segmentStartTime + segmentDuration > duration)
        return SND_ERR_BAD_DURATION;

    duration = segmentDuration;

    if(preDecode) {
        job = [[SndMP3DecodeJob alloc] initWithStartTime: segmentStartTime
                                                duration: segmentDuration];
    
        [pcmDataLock lock];
        [NSThread detachNewThreadSelector: @selector(decodeThread:)
                                 toTarget: self
                               withObject: job];
        [pcmDataLock lock];
        [pcmDataLock unlock];
        duration = segmentDuration;
        [job autorelease];
    }
    else { // initialise LAME now since it is otherwise initialised in the decodeThread:
        lame_decode_init();
    }
    return SND_ERR_NONE;
}

////////////////////////////////////////////////////////////////////////////////
// initFromSoundURL:
////////////////////////////////////////////////////////////////////////////////

- initFromSoundURL: (NSURL *) url
{
  self = [self init];
  if (self != nil) {
    if ([self readSoundURL: url] != SND_ERR_NONE) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (int) readSoundfile: (NSString*) filename
{

  if (![[NSFileManager defaultManager] fileExistsAtPath: filename]) {
//    NSLog(@"Snd::readSoundfile: sound file %@ doesn't exist",filename);
    return SND_ERR_CANNOT_OPEN;
  }
  else {
    NSURL *soundURL = [NSURL fileURLWithPath: filename];
    return [self readSoundURL: soundURL];
  }
}

- (long) insertIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
                intoFrameRange: (NSRange) bufferRange
           fromDecodedMP3Frame: (NSRange) decodedFrameRange
{
    int numOfChannelsInBuffer = [anAudioBuffer channelCount];
    // We could simply store all pcm data into a 2 channel (stereo) buffer and then do the conversion to larger
    // number of channels later, but in the interests of efficiency and the mess of not properly filling our given
    // buffer, we move the pcm channels into the stereo channels of the audio buffer.
    // Left channel in 0th element, Right channel in 1st element.
    // [anAudioBuffer stereoChannels]
    short stereoChannels[2] = { 0, 1 };

    switch ([anAudioBuffer dataFormat]) {
    case SND_FORMAT_FLOAT: {
        // Our buffer is in an array of floats, numOfChannelsInBuffer per frame.
        // TODO we should rewrite this to manipulate the audio data as array of bytes until we need to actually do the conversion.
        // This is preferable to having duplicated code with just a couple of changes for type definitions and arithmetic.
        // So the switch statement should be moved inside the loops.
        float *buff = [anAudioBuffer bytes];  
        unsigned long frameIndex;
        unsigned long sampleIndex;
        unsigned short channelIndex;

        for (frameIndex = 0; frameIndex < decodedFrameRange.length; frameIndex++) {
            long currentBufferSample = (bufferRange.location + frameIndex) * numOfChannelsInBuffer;
            // LAME always produces stereo data in two separate buffers
            long currentDecodedSample = decodedFrameRange.location + frameIndex;

            buff[currentBufferSample + stereoChannels[0]] = decodedLeftPCM[currentDecodedSample] / 32768.0;
            buff[currentBufferSample + stereoChannels[1]] = decodedRightPCM[currentDecodedSample] / 32768.0;
            // buff[currentBufferSample + stereoChannels[1]] = 0.0;
            // Silence any other (neither L or R) channels in the buffer.
            for(channelIndex = 0; channelIndex < numOfChannelsInBuffer; channelIndex++) {
                if(channelIndex != stereoChannels[0] && channelIndex != stereoChannels[1]) {
                    // we use integer values for zero so they will cast appropriate to the size of buff[x].
                    buff[currentBufferSample + channelIndex] = 0;
                }
            }
        }
        // Silence the rest of the buffer, all channels
        for (sampleIndex = (bufferRange.location + frameIndex) * numOfChannelsInBuffer; sampleIndex < (bufferRange.location + bufferRange.length) * numOfChannelsInBuffer; sampleIndex++) {
            buff[sampleIndex] = 0;
        }

        break;
    }
    default:
        NSLog(@"SndMP3 -insertIntoAudioBuffer: - unhandled data format %d", [anAudioBuffer dataFormat]);
    }
    return decodedFrameRange.length;
}

// Decode on the fly.
- (long) decodeIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
		intoFrameRange: (NSRange) bufferRange
                samplesInRange: (NSRange) sndReadingRange;
{
    // Since we do no resampling, we can use bufferRange.length here
    unsigned int numOfFramesToCopy = MIN(bufferRange.length, sndReadingRange.length);
    // Note we distinguish encoded (MP3 data) frames from our typical use of the term frame.
    int samplesPerMP3Frame = SND_MPEGV1_SAMPLES_PER_FRAME;
    //
    // sndReadingRange.length = numOfFramesToCopy
    // NSRange bitstreamFrames = [self findInBitstreamSamplesInRange: sndReadingRange];
    int startMP3FrameID = floor(sndReadingRange.location / samplesPerMP3Frame);
    int endMP3FrameID   = floor((sndReadingRange.location + numOfFramesToCopy) / samplesPerMP3Frame);

    long framesCreated = 0;
    long totalFramesCreated = 0;
    unsigned char *mp3DataBytes = (unsigned char *) [mp3Data bytes];
    
    // Use a combination of cached and newly decoded MP3 frames to fill the buffer.
    // Typically however, the buffer to fill will be less than one MP3 decoded frame.
    while (totalFramesCreated < numOfFramesToCopy) {
        NSRange decodedFrameRange;

        // Check if we can use the cached PCM data.
        if(currentMP3FrameID != startMP3FrameID) {  // No, we need to decode the data
            long decodeFeedAmount;
            long decodeFrom = encodedFrameLocations[startMP3FrameID];
            
            currentMP3FrameID = startMP3FrameID;  // retain the current bitstream frame ID.

            // decodeFeedAmount = [self frameSizeOfHeader: getFrameHeaderAt(mp3DataBytes + encodedFrameLocations[startMP3FrameID])];
            if(currentMP3FrameID < encodedFrameLocationsCount - 1)
                decodeFeedAmount = encodedFrameLocations[currentMP3FrameID + 1] - encodedFrameLocations[currentMP3FrameID];
            else
                decodeFeedAmount = [mp3Data length] - encodedFrameLocations[currentMP3FrameID];

            // LAME only gives us back stereo data. The decoded data is cached.
            framesCreated = lame_decode1(mp3DataBytes + decodeFrom, decodeFeedAmount, decodedLeftPCM, decodedRightPCM);
            // NSLog(@"framesCreated = %d, decodeFrom = %d, decodeFeedAmount = %d\n", framesCreated, decodeFrom, decodeFeedAmount);
            /* framesCreated = 0:  need more data to decode */
            /* framesCreated = -1:  error.  Lets assume 0 pcm output */
            /* framesCreated = number of samples output */
            if(framesCreated < 0) {
                NSLog(@"Error: lame decode error framesCreated = %d, decodeFrom = %d, decodeFeedAmount = %d\n", framesCreated, decodeFrom, decodeFeedAmount);
                return 0;
            }
            if(framesCreated == 0) {
                NSLog(@"Need more data, framesCreated == 0\n");
            }
        }
        decodedFrameRange.location = (sndReadingRange.location + totalFramesCreated) % samplesPerMP3Frame;
        // We copy the number of frames remaining in the decoded MP3 frame or the number of frames remaining to copy, whichever is less.
        decodedFrameRange.length = MIN((samplesPerMP3Frame - decodedFrameRange.location), (numOfFramesToCopy - totalFramesCreated));
        // update the buffer range to copy into, based on any frames copied in a previous iteration.
        bufferRange.location += totalFramesCreated;
        bufferRange.length -= totalFramesCreated;
        
#if SNDMP3_DEBUG
        NSLog(@"inserting intoFrameRange: [%d,%d] from decoded MP3 frame %d in the range [%d,%d]\n", 
            bufferRange.location, bufferRange.length, startMP3FrameID, decodedFrameRange.location, decodedFrameRange.length);
#endif
        totalFramesCreated += [self insertIntoAudioBuffer: anAudioBuffer 
                                           intoFrameRange: bufferRange
                                      fromDecodedMP3Frame: decodedFrameRange];

        // decodeFrom += decodeFeedAmount;
        startMP3FrameID++;
    }
#if SNDMP3_DEBUG
    {
        float min, max;
        [anAudioBuffer findMin: &min max: &max];
        NSLog(@"SndMP3: min: %5.3f max: %5.3f [buffLoc:%li buffLen:%i loc:%li len:%i]\n",
            MAX(-1, min), MIN(1,max), bufferRange.location, bufferRange.length, sndReadingRange.location, sndReadingRange.length);
    }
#endif
    return totalFramesCreated;    
}

// This version of insertIntoAudioBuffer: assumes that the entire MP3 has been decoded into memory.
// We also assume the buffer sample rate matches the MP3 sample rate.
- (long) insertPreDecodedIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
		          intoFrameRange: (NSRange) bufferRange
	                  samplesInRange: (NSRange) sndReadingRange;
{
    int buffChans = [anAudioBuffer channelCount];
    const short *pData = NULL;

    [pcmDataLock lock];
    pData = [pcmData bytes];

    switch ([anAudioBuffer dataFormat]) {
    case SND_FORMAT_FLOAT: {
	float *pBuff = [anAudioBuffer bytes];
	
	if (buffChans == 2) {
	    unsigned long frameIndex = 0;
	    unsigned long sndDataLength = [pcmData length] / (sizeof(short) * 2);  // determine length in frames.
	    
	    if (sndReadingRange.location < sndDataLength) {
		// Since we do no resampling, we can use bufferRange.length here
		unsigned int numOfFramesToCopy = MIN(bufferRange.length, sndReadingRange.length);

		for (; frameIndex < numOfFramesToCopy; frameIndex++) {
		    long currentBufferSample = (bufferRange.location + frameIndex) * buffChans;
		    long currentDecodedSample = (sndReadingRange.location + frameIndex) * buffChans;
		    
		    pBuff[currentBufferSample]     = (float) pData[currentDecodedSample]     / 32768.0;
		    pBuff[currentBufferSample + 1] = (float) pData[currentDecodedSample + 1] / 32768.0;
		}
	    }
	    for (; frameIndex < bufferRange.length; frameIndex++) {
		long currentBufferSample = (bufferRange.location + frameIndex) * buffChans;

		pBuff[currentBufferSample]     = 0.0;
		pBuff[currentBufferSample + 1] = 0.0;
	    }
#if SNDMP3_DEBUG
	    {
		float min, max;
		
		[anAudioBuffer findMin: &min max: &max];
		NSLog(@"f SndMP3: min: %5.3f max: %5.3f [dataLen:%i buffLen:%i loc:%li len:%i]\n", MAX(-1, min), MIN(1,max), sndDataLength, bufferRange.length, sndReadingRange.location, bufferRange.length);
	    }
#endif
	}
	else
	    NSLog(@"SndMP3 -insertIntoAudioBuffer: - Unhandled number of channels %d", buffChans);
    }
    break;
    case SND_FORMAT_LINEAR_16: {
	short *pBuff = [anAudioBuffer bytes];
	
	if (buffChans == 2) {
	    unsigned long frameIndex = 0;
	    unsigned long sndDataLength = [pcmData length] / (sizeof(short) * 2);  // determine length in frames.

	    if (sndReadingRange.location < sndDataLength) {
		// Since we do no resampling, we can use bufferRange.length here
		unsigned int numOfFramesToCopy = MIN(bufferRange.length, sndReadingRange.length);
		
		for (; frameIndex < numOfFramesToCopy; frameIndex++) {
		    long currentBufferSample = (bufferRange.location + frameIndex) * buffChans;
		    long currentDecodedSample = (sndReadingRange.location + frameIndex) * buffChans;

		    pBuff[currentBufferSample]     = pData[currentDecodedSample]     / 32768;
		    pBuff[currentBufferSample + 1] = pData[currentDecodedSample + 1] / 32768;
		}
	    }
	    for (; frameIndex < bufferRange.length * buffChans; frameIndex++) {
		long currentBufferSample = (bufferRange.location + frameIndex) * buffChans;

		pBuff[currentBufferSample]     = 0;
		pBuff[currentBufferSample + 1] = 0;
	    }
#if SNDMP3_DEBUG
	    {
		float min, max;
		[anAudioBuffer findMin: &min max: &max];
		NSLog(@"SndMP3: min: %5.3f max: %5.3f [dataLen:%li buffLen:%i loc:%li len:%i]\n",MAX(-1, min), MIN(1,max), sndDataLength, bufferRange.length, sndReadingRange.location, bufferRange.length);
	    }
#endif
	}
	else
	    NSLog(@"SndMP3 -insertIntoAudioBuffer: %@ - Unhandled number of channels %d of SND_FORMAT_LINEAR_16 data", anAudioBuffer, buffChans);
	break;
    }
    default:
	NSLog(@"SndMP3 -insertIntoAudioBuffer: - unhandled data format %d", [anAudioBuffer dataFormat]);
    }
    [pcmDataLock unlock];

    return bufferRange.length;
}

////////////////////////////////////////////////////////////////////////////////
// insertIntoAudioBuffer:intoFrameRange:samplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (long) insertIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
		intoFrameRange: (NSRange) bufferRange
	        samplesInRange: (NSRange) sndReadingRange;
{
    if(preDecode)
        return [self insertPreDecodedIntoAudioBuffer: anAudioBuffer 
                                      intoFrameRange: bufferRange
                                      samplesInRange: sndReadingRange];

    else
        return [self decodeIntoAudioBuffer: anAudioBuffer
                            intoFrameRange: bufferRange
                            samplesInRange: sndReadingRange];
}

- (SndAudioBuffer *) audioBufferForSamplesInRange: (NSRange) r
{
    SndAudioBuffer *ab  = [SndAudioBuffer alloc];

    if(preDecode) {
        long endIndex = r.length + r.location;

        while (bDecoding && decodedSampledCount < endIndex)
            [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.25]];
    }

#if SNDMP3_DEBUG_READING
    NSLog(@"requested: [%li, %li] decoded: %li  %s\n",
          r.location, endIndex, decodedSampledCount, decodedSampledCount > endIndex ? "" : "***");
#endif
    // TODO Should initialize this with the native data format?
    [ab initWithDataFormat: SND_FORMAT_FLOAT
              channelCount: 2
              samplingRate: [self samplingRate]
                  duration: r.length / [self samplingRate]];

    [self fillAudioBuffer: ab toLength: r.length samplesInRange: r];

    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////

@end
