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

#import "SndMP3.h"
#import <lame/lame.h>

#define SNDMP3_DEBUG_READING 0
#define SNDMP3_DEBUG 0
// This defines that we decode the entire MP3 into memory (yikes!) then fetch from there.
#define DECODE_ENTIRE_INTO_MEMORY 1

#define MP3_BITRATE_BAD  -1
#define MP3_BITRATE_FREE -2
#define MP3_BITRATEINDEX_BAD  0
#define MP3_BITRATEINDEX_FREE 15

static NSLock *decoderLock;

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

+ (NSArray *) soundFileExtensions
{
  return [[super soundFileExtensions] arrayByAddingObject: @"mp3"];
}

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

- (void) checkID3Tag: (NSData*) _mp3Data
{
  const unsigned char *pData = [_mp3Data bytes];
  long length = [_mp3Data length];

  if (length >= 128 &&
      strcmp(pData + length - 128, "TAG") == 0) {
    const char *id3base = pData + length - 128;
    const char *title   = id3base + 3;
    const char *artist  = title  + 30;
    const char *album   = artist + 30;
    const char *year    = album  + 30;
    const char *comment = year   + 4;
    const char *trackNumber = id3base + 126;
    const char *genre   = id3base + 127;

    printf("ID3 tag\n");
    printf("Title:       %30s\n", title);
    printf("Artist:      %30s\n", artist);
    printf("Album:       %30s\n", album);
    printf("year:        %4s\n", year);
    printf("Comment:     %30s\n", comment);
    printf("TrackNumber: %d\n", trackNumber[0]);
    printf("Genre:       %d\n", genre[0]);
  }
  else {
//    printf("No ID3 tag found\n");
  }
}

- (void) dumpFrameHeader: (unsigned long) frameHeader
{
    int frameSize, samplingRate = 44100;
    float framesPerSecond;
    int layer, bitrateIndex, version = 0, bitrate, samplesPerFrame = 1152;

    if ((frameHeader >> 21) & 0x07FF)
	printf("frame sync is ok\n");
    else
	printf("bad frame sync\n");

    printf("version: ");
    switch ((frameHeader >> 19) & 0x03) {
	case 0: printf("MPEG 2.5\n"); break;
	case 1: printf("reserved\n"); break;
	case 2: printf("MPEG v2\n"); version = 2; samplesPerFrame = 576; break;
	case 3: printf("MPEG v1\n"); version = 1; break;
    }
    layer =  4 - ((frameHeader >> 17) & 0x03);
    switch (layer) {
	case 3: printf("Layer 3\n"); break;
	case 2: printf("Layer 2\n"); break;
	case 1: printf("Layer 1\n"); break;
	case 0:
	default:
	    printf("reserved\n");
    }
    printf("Protected by CRC: %s\n", (frameHeader >> 16) & 0x1 ? "no" : "yes");

    bitrateIndex = (frameHeader >> 12) & 0xF;
    bitrate = bitrateLookupTable[bitrateIndex][(version-1)*3 + layer-1];
    printf("Bitrate: %i (index: %i)\n", bitrate, bitrateIndex);

    printf("Sampling frequency index: %li\n", (frameHeader >> 10) & 0x3);
    printf("Padding: %s\n", (frameHeader >> 9) & 0x1 ? "yes" : "no");
    printf("Channel Mode: %li\n", (frameHeader >> 6) & 0x3);
    printf("Mode extension: %li\n", (frameHeader >> 4) & 0x3);
    printf("Copyright: %s\n", (frameHeader >> 3) & 0x1 ? "yes" : "no");
    printf("Original: %s\n", (frameHeader >> 2) & 0x1 ? "yes" : "no");
    printf("Emphasis: %li\n", frameHeader & 0x3);

    printf("Samples per frame: %i\n",samplesPerFrame);
    framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
    printf("FramesPerSecond: %f\n", framesPerSecond);
    frameSize = bitrate * 125 / framesPerSecond; // 125 = 100 / 8
    printf("FrameSize: %i\n", frameSize);
}    

- (int) findMP3FrameHeadersInData: (NSData *) mp3DataToSearch
	    storeFrameLocationsAt: (long **) ppFrameLocations
			    count: (long *) numOfFrameLocations
{
    int layer, bitrateIndex, version = 0, bitrate = 0, samplesPerFrame = 1152;
    int frameSize, samplingRate = 44100;
    float framesPerSecond;
    const unsigned char *pData = [mp3DataToSearch bytes];
    long mp3Length = [mp3DataToSearch length];
    long maxFrameLocationsCount = 512;
    long  position = 0;

    *numOfFrameLocations = 0;

    if (*ppFrameLocations)
	free(*ppFrameLocations);

    if((*ppFrameLocations = (long*) malloc(sizeof(long) * maxFrameLocationsCount)) == NULL) {
	NSLog(@"Unable to allocate memory for frame locations\n");
	return -1;
    }
	
    // ok, we are going looking for frame headers:
    // float time;
    // unsigned char *pCh = (unsigned char*) &frameHeader;

    while (position < mp3Length) {
	while (pData[position] != (unsigned char) 0xFF && (position < mp3Length)) {
	    position++;
	}
	if (position < mp3Length-1 && (pData[position+1] & 0xE0) == 0xE0) {
	    unsigned long frameHeader = (pData[position] << 24) + (pData[position+1] << 16) + (pData[position+2] << 8) + pData[position+3];
	    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileFormat"]) {
		[self dumpFrameHeader: frameHeader];
	    }

	    position += 4;

	    if (((frameHeader >> 24) & 0xE0) == 0xE0) {
		// if (frameCount == 0) { //

		switch ((frameHeader >> 19) & 0x03) {
		    case 0: //printf("MPEG 2.5\n");
			break;
		    case 1: //printf("reserved\n");
			break;
		    case 2: //printf("MPEG v2\n");
			version = 2;
			samplesPerFrame = 576;
			break;
		    case 3: // printf("MPEG v1\n");
			version = 1;
			samplesPerFrame = 1152;
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
			int formatIndex = (version-1)*3 + layer-1;
			bitrate = bitrateLookupTable[bitrateIndex][formatIndex];
		    }
		    framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
		    frameSize = bitrate * 125 / framesPerSecond; // 125 = 100 / 8
		    // time = (float) (*numOfFrameLocations) * samplesPerFrame / (float) samplingRate;
	            // printf("[Frame: %li] Header found at: %li  (t:%.2f sam:%li)\n",
                    //        (*numOfFrameLocations), position - 4, time, ((*numOfFrameLocations) - 1) * samplesPerFrame);

		    if ((*numOfFrameLocations) == maxFrameLocationsCount) {
			maxFrameLocationsCount <<= 1;
			(*ppFrameLocations) = (long*) realloc((*ppFrameLocations), sizeof(long) * maxFrameLocationsCount);
			if(*ppFrameLocations == NULL) {
			    NSLog(@"Unable to reallocate frame location memory to %ld longs\n", maxFrameLocationsCount);
			    return -1;
			}
		    }
		    (*ppFrameLocations)[(*numOfFrameLocations)] = position;
		    (*numOfFrameLocations)++;
		    position += frameSize - 4;
		}
	    }
	}
	else {
	    position++;
	}
    }
    // condense allocated memory to just the frame locations found...
    *ppFrameLocations = (long*) realloc((*ppFrameLocations), sizeof(long) * (*numOfFrameLocations));
    if(*ppFrameLocations == NULL) {
	NSLog(@"Unable to reallocate frame location memory to %ld longs\n", *numOfFrameLocations);
	return -1;
    }
    
    /*
     {
	 long i;
	 for (i = 0; i < *numOfFrameLocations; i++) {
	     printf("frame: %04li location: %07li\n", i, (*ppFrameLocations)[i]);
	 }
     }
     */
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Snd overrides required for simple playback operation
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    frameLocations = NULL;
    frameLocationsCount = 0;
    if (decoderLock == nil)
      decoderLock = [NSLock new];
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
    SndSoundStruct nativeFormat;

    SNDStreamNativeFormat(&nativeFormat);
    
    if(nativeFormat.samplingRate != [self samplingRate] || nativeFormat.channelCount != [self channelCount]) {
	NSLog(@"MP3 file sample rate %d, channels %d not of native format sample rate %lf, channels %d\n",
	    [self samplingRate], [self channelCount], nativeFormat.samplingRate, nativeFormat.channelCount);
	return SND_ERR_UNKNOWN;
    }
    return SND_ERR_NONE;
}

- (void) dealloc
{
  if (mp3Data) {
    [mp3Data release];
    mp3Data = nil;
  }
  if (pcmData) {
    [pcmData release];
    pcmData = nil;
  }
  if (pcmDataLock) {
    [pcmDataLock release];
    pcmDataLock = nil;
  }
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// decodeThread
////////////////////////////////////////////////////////////////////////////////

- (void) decodeThread: (SndMP3DecodeJob*) job
{
  NSAutoreleasePool *localPool = [NSAutoreleasePool new];

  int growSize = 44100 * 4;
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

  requestedStartSample = [job startTime] * 44100;
  requestedSampleCount = [job duration]  * 44100;

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
    printf("[%04li] Decoded: %li/%li\n",iterations,decodedSampledCount,lengthInSampleFrames);
#endif
    if (samplesRecovered >= requestedSampleCount)
      break;
  }
  lengthInSampleFrames = samplesRecovered;
  duration    = lengthInSampleFrames / 44100.0;
  [pcmDataLock lock];
  [pcmData setLength: lengthInSampleFrames * sizeof(short) * 2];
  duration = lengthInSampleFrames / 44100.0;
  [pcmDataLock unlock];

  [decoderLock unlock];
  bDecoding = FALSE;
  [localPool release];
//  printf("Finished decoding...\n");
  [NSThread exit];
}

////////////////////////////////////////////////////////////////////////////////
// readSoundfile:
////////////////////////////////////////////////////////////////////////////////

- (void) loadMP3DataWithURL: (NSURL*) soundURL
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
  [self checkID3Tag: mp3Data];
  [self findMP3FrameHeadersInData: mp3Data
            storeFrameLocationsAt: &frameLocations
			    count: &frameLocationsCount];
      
  lengthInSampleFrames = frameLocationsCount * 1152.0;
  duration    = lengthInSampleFrames / 44100.0;
  
  [localPool release];
}

////////////////////////////////////////////////////////////////////////////////
// readSoundURL:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundURL: (NSURL*) soundURL
{
  SndMP3DecodeJob *job = nil;
  
  [self loadMP3DataWithURL: soundURL];
#if SNDMP3_DEBUG_READING
  printf("Found %li frames\n", frameLocationsCount);
#endif

  job = [[SndMP3DecodeJob alloc] initWithStartTime: 0.0
                                          duration: duration];

  [pcmDataLock lock];
  [NSThread detachNewThreadSelector: @selector(decodeThread:)
                           toTarget: self
                         withObject: job];
  [pcmDataLock lock];
  [pcmDataLock unlock];
  [job autorelease];
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
  
  [self loadMP3DataWithURL: soundURL];

  if (segmentDuration == -1.0)
    segmentDuration = duration;
    

  if (segmentStartTime > duration) 
    return SND_ERR_BAD_STARTTIME;
  else if (segmentStartTime + segmentDuration > duration)
    return SND_ERR_BAD_DURATION;

  duration = segmentDuration;

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

////////////////////////////////////////////////////////////////////////////////
// insertIntoAudioBuffer:intoFrameRange:samplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (long) insertIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
		intoFrameRange: (NSRange) bufferRange
	        samplesInRange: (NSRange) sndReadingRange;
{
  // This version of insertIntoAudioBuffer: assumes that the entire MP3 has been decoded
  // into memory. We also assume the buffer sample rate matches the MP3sample rate
#if DECODE_ENTIRE_INTO_MEMORY
    int buffChans = [anAudioBuffer channelCount];
    const short *pData = nil;

    [pcmDataLock lock];
    pData = [pcmData bytes];

    switch ([anAudioBuffer dataFormat]) {
    case SND_FORMAT_FLOAT: {
	float *pBuff = [anAudioBuffer bytes];
	
	if (buffChans == 2) {
	    long frameIndex = 0;
	    long sndDataLength = [pcmData length] / (sizeof(short) * 2);  // determine length in frames.
	    
	    if (sndReadingRange.location < sndDataLength) {
		// Since we do no resampling, we can use bufferRange.length here
		int numOfFramesToCopy = MIN(bufferRange.length, sndReadingRange.length);

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
	    long frameIndex = 0;
	    long sndDataLength = [pcmData length] / (sizeof(short) * 2);  // determine length in frames.

	    if (sndReadingRange.location < sndDataLength) {
		// Since we do no resampling, we can use bufferRange.length here
		int numOfFramesToCopy = MIN(bufferRange.length, sndReadingRange.length);
		
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
		NSLog(@"s SndMP3: min: %5.3f max: %5.3f [dataLen:%li buffLen:%i loc:%li len:%i]\n",MAX(-1, min), MIN(1,max), sndDataLength, bufferRange.length, sndReadingRange.location, bufferRange.length);
	    }
#endif
	}
	else
	    NSLog(@"SndMP3 -insertIntoAudioBuffer: %@ - Unhandled number of channels %d of SND_FORMAT_LINEAR_16 data", anAudioBuffer, buffChans);
    }
	break;
	
    default:
	NSLog(@"SndMP3 -insertIntoAudioBuffer: - unhandled data format %d", [anAudioBuffer dataFormat]);
    }
    [pcmDataLock unlock];

#else
    
    /* TODO Decode on the fly */

    int startFrameID = floor(sndReadingRange.location / 1152.0);
    int startSamplePosition = startFrameID * 1152;
    int endFrameID   = floor(sndReadingRange.location + bufferRange.length / 1152.0);
    int endSamplePosition = (endFrameID + 1) * 1152;
    int currentFrameID = startFrameID;

    short decode_pcm_l[10000];
    short decode_pcm_r[10000];

    const short *pData = [pcmData bytes];
    float *pBuff = [anAudioBuffer bytes];
    long   samsCreated      = 0;
    long   totalSamsCreated = 0;

    /*
     while (totalSamsCreated < playRegion.length) {
	 long decodePos        = frameLocations[currentFrameID];
	 long decodeFeedAmount = frameLocations[currentFrameID + 1] - frameLocations[currentFrameID];

	 sams_created = lame_decode1(mp3DataBytes + decodePos, decodeFeedAmount, pcm_l, pcm_r);

	 if (sams_created > 0) {
	     totalSamsCreated ;
	 }
	 currentFrameID++;
     }
     */

#endif
    return bufferRange.length;
}

- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) r
{
  SndAudioBuffer *ab  = [SndAudioBuffer alloc];
  //  int   samSize       = 4; // hardcoded for 16 bit, 2 chans
  //  SndSoundStruct s;

  long endIndex = r.length + r.location;

  while (bDecoding && decodedSampledCount < endIndex)
    [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.25]];

#if SNDMP3_DEBUG_READING
  printf("requested: [%li, %li] decoded: %li  %s\n",
         r.location, endIndex, decodedSampledCount, decodedSampledCount > endIndex?"":"***");
#endif
  [ab initWithFormat: SND_FORMAT_FLOAT
        channelCount: 2
        samplingRate: 44100
            duration: r.length / 44100.0];

  [self fillAudioBuffer: ab toLength: r.length samplesInRange: r];

  return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////

@end
