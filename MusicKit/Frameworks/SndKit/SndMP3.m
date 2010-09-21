////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Snd subclass reading MP3 files. 
//
//    TODO: - This is only good for 44.1 stereo MP3s at the moment.
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

// Only compile this class if the HIP library has been installed.
#if HAVE_CONFIG_H
# import "SndKitConfig.h"
#endif
#if HAVE_LIBMP3HIP

#import "SndMP3.h"
#import "SndError.h"
#import "SndAudioBuffer.h"
#import <math.h> // Required for GNUstep. Should be unnecessary in later versions of GS.

// Debugging print statements. 1 = print out, 0 squelch.
#define DEBUG_READING 0
#define DEBUG_DECODE 0
#define DEBUG_BACKTRACK 0
#define DEBUG_FRAME_COUNTING 0
#define DEBUG_CACHE 0
#define SNDMP3_DEBUG 0

// This defines that we decode the entire MP3 into memory (yikes!) then fetch from there.
// Nowdays, we default to decode on the fly as processors improve in power.
#define DECODE_ENTIRE_INTO_MEMORY 0 

#define MP3_BITRATE_BAD  -1
#define MP3_BITRATE_FREE -2
#define MP3_BITRATEINDEX_BAD  0
#define MP3_BITRATEINDEX_FREE 15

#define SND_LAYER1_SAMPLES_PER_FRAME 384
#define SND_MPEGV1_SAMPLES_PER_FRAME 1152
#define SND_MPEGV2_SAMPLES_PER_FRAME 576
#define MAX_MPEG_SAMPLES_PER_FRAME SND_MPEGV1_SAMPLES_PER_FRAME

// The number of buffers to hold decoded to allow for decoding from more than one location in the file simultaneously.
#define CACHED_DECODED_BUFFERS 32

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

static const long samplingRateLookupTable[4][3] = {
  { 11025, 12000,  8000 }, /* vers 2.5 */
  {    -1,    -1,    -1 }, /* reserved */
  { 22050, 24000, 16000 }, /* vers 2 */
  { 44100, 48000, 32000 }, /* vers 1 */
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

- (void) checkID3Tag: (NSData *) mp3DataToCheck
{
#if 0
  const unsigned char *pData = [mp3DataToCheck bytes];
  long length = [mp3DataToCheck length];
  const char *id3base = pData + length - 128;

  if (length >= 128 && strcmp(id3base, "TAG") == 0) {
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
#endif
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

// Frame header:
//
// 00000000000VVLLCBBBBSSP0HHMMCOEE
//            |||||||||||| ||||||++-> Emphasis
//            |||||||||||| |||||+---> Original
//            |||||||||||| ||||+----> Copyright
//            |||||||||||| ||++-----> Mode extension
//            |||||||||||| ++-------> Channel Mode
//            |||||||||||+----------> Padding
//            |||||||||++-----------> Sampling frequency Index
//            |||||++++-------------> Bitrate Index
//            ||||+-----------------> CRC
//            ||++------------------> Layer
//            ++--------------------> Version
//
- (void) dumpFrameHeader: (unsigned long) frameHeader
{
    int frameSize, samplingRate = [self samplingRate];
    float framesPerSecond;
    int layer, bitrateIndex, version = 0, bitrate, samplesPerFrame = SND_MPEGV1_SAMPLES_PER_FRAME;
    short versionIndex = ((frameHeader >> 19) & 0x3);

    if ((frameHeader >> 21) & 0x07FF)
	NSLog(@"frame sync is ok\n");
    else
	NSLog(@"bad frame sync\n");

    switch (versionIndex) {
	case 0: NSLog(@"version: MPEG 2.5\n"); break;
	case 1: NSLog(@"version: reserved\n"); break;
	case 2: version = 2; samplesPerFrame = SND_MPEGV2_SAMPLES_PER_FRAME; break;
        case 3: version = 1; samplesPerFrame = SND_MPEGV1_SAMPLES_PER_FRAME; break;
    }
    layer = 4 - ((frameHeader >> 17) & 0x03);
    if (layer == 0) {
        NSLog(@"Layer reserved\n");
    }
    else {
        if(layer == 1)
            samplesPerFrame = SND_LAYER1_SAMPLES_PER_FRAME;
        NSLog(@"version: MPEG v%d Layer %d\n", version, layer);
    }

    NSLog(@"Protected by CRC: %s\n", (frameHeader >> 16) & 0x1 ? "no" : "yes");

    bitrateIndex = (frameHeader >> 12) & 0xF;
    bitrate = bitrateLookupTable[bitrateIndex][(version - 1) * 3 + layer - 1];
    NSLog(@"Bitrate: %i (index: %i)\n", bitrate, bitrateIndex);
    NSLog(@"Sampling frequency: %li\n", samplingRateLookupTable[versionIndex][(frameHeader >> 10) & 0x3]); 
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
    int frameSize;
    int samplingRate = [self samplingRate]; 
    float framesPerSecond;
    const unsigned char *bitstream = [mp3DataToSearch bytes];
    long mp3LengthInBytes = [mp3DataToSearch length];
    long maxEncodedFrameLocationsCount = 512;  // mp3LengthInBytes/ length
    long  position = 0;
    BOOL dumpFrameHeaders = [[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileMP3Frames"];
    
    encodedFrameLocationsCount = 0;
    
    if (encodedFrameLocations)
	free(encodedFrameLocations);
    
    if((encodedFrameLocations = (long *) malloc(sizeof(long) * maxEncodedFrameLocationsCount)) == NULL) {
	NSLog(@"Unable to allocate memory %ld for frame locations\n", maxEncodedFrameLocationsCount);
	return -1;
    }
    
    // ok, we are going looking for frame headers:
    while (position < mp3LengthInBytes) {
        // Scan until we find a 0xFF, followed by the top three bits (0xE0) of the following byte set.
	while (bitstream[position] != (unsigned char) 0xFF && (position < mp3LengthInBytes)) {
	    position++;
	}
	if (position < mp3LengthInBytes - 1 && (bitstream[position + 1] & 0xE0) == 0xE0) {
	    unsigned long frameHeader = getFrameHeaderAt(bitstream + position);
	    
	    if(dumpFrameHeaders) {
		[self dumpFrameHeader: frameHeader];
	    }
	    
	    if (((frameHeader >> 24) & 0xE0) == 0xE0) {
		switch ((frameHeader >> 19) & 0x03) {
		    case 0:
			NSLog(@"MPEG 2.5\n");
			break;
		    case 1:
			NSLog(@"reserved\n");
			break;
		    case 2:
			version = 2;
			samplesPerFrame = SND_MPEGV2_SAMPLES_PER_FRAME;
			break;
		    case 3:
			version = 1;
			samplesPerFrame = SND_MPEGV1_SAMPLES_PER_FRAME;
			break;
		}
		layer = 4 - ((frameHeader >> 17) & 0x03);
		// NSLog(@"MPEG v%d Layer %d\n", version, layer);
		if (layer == 4) { // something is wrong!
		    NSLog(@"Encountered error in MP3 bitstream at position %d, layer == 4\n", position);
		    position++;
		}
		else {
		    bitrateIndex = (frameHeader >> 12) & 0x0F;
		    if (bitrateIndex == MP3_BITRATEINDEX_BAD) {
			NSLog(@"Encountered error in MP3 bitstream at position %d, bitrateIndex == MP3_BITRATEINDEX_BAD\n", position);
			position++; // something is wrong!
			continue;
		    }
		    if (bitrateIndex != MP3_BITRATEINDEX_FREE) { // free
			int formatIndex = (version - 1) * 3 + layer - 1;
			bitrate = bitrateLookupTable[bitrateIndex][formatIndex];
		    }
                    //samplingRate = samplingRateLookupTable[((frameHeader >> 19) & 0x3)][((frameHeader >> 10) & 0x3)];
		    framesPerSecond = (float) samplingRate / (float) samplesPerFrame;
		    frameSize = bitrate * 125 / framesPerSecond; // 125 = 100 / 8
#if DEBUG_FRAME_COUNTING
                    {
                        float time = (float) encodedFrameLocationsCount * samplesPerFrame / (float) samplingRate;
                        NSLog(@"[Frame: %li] Header found at: %li  (t:%.2f sample:%li), frameSize %d\n",
			      encodedFrameLocationsCount, position, time, (encodedFrameLocationsCount - 1) * samplesPerFrame, frameSize);
                    }
#endif
		    // Each time we exceed the maximum frame locations count, we double that number and reallocate.
		    if (encodedFrameLocationsCount == maxEncodedFrameLocationsCount) {
			maxEncodedFrameLocationsCount <<= 1;
			encodedFrameLocations = (long *) realloc(encodedFrameLocations, sizeof(long) * maxEncodedFrameLocationsCount);
			if(encodedFrameLocations == NULL) {
			    NSLog(@"Unable to reallocate frame location memory to %ld longs\n", maxEncodedFrameLocationsCount);
			    return -1;
			}
		    }
		    encodedFrameLocations[encodedFrameLocationsCount] = position;
		    encodedFrameLocationsCount++;
		    position += frameSize;
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
    
#if DEBUG_FRAME_COUNTING
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
	soundFormat.dataFormat = SND_FORMAT_MP3;
	soundFormat.sampleRate = 44100.0;
	soundFormat.channelCount = 2;
	soundFormat.frameCount = 0;
	// Holds a collection of currently decoded frames. We keep more than one frame decoded to optimize simultaneous
	// access of an SndMP3, particularly to avoid thrashing between two continuously accessed non-contiguous frames.
	// TODO should be SndAgedDictionary
	decodedBufferCache = [[NSMutableDictionary dictionaryWithCapacity: CACHED_DECODED_BUFFERS] retain];

	// TODO
	decodedBufferAccessCount  = [[NSMutableDictionary dictionaryWithCapacity: CACHED_DECODED_BUFFERS] retain];
	accessTime = 0;
	
        pcmDataLock = [NSLock new];
    }
    return self;
}

- (long) lengthInSampleFrames
{
    return soundFormat.frameCount;
}

- (double) duration
{
    return duration;
    //  return [self lengthInSampleFrames] / [self samplingRate];
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@ (%@)",
        [super description], SndFormatDescription(soundFormat)];
}

- (double) samplingRate
{
    // If we are not predecoding, and we have read the MP3 data, we can return it's sample rate.
    // TODO We return a valid sample rate even if the instance is uninitialized since findFrameHeadersInBitstream uses it.
    // return (!preDecode && mp3DataDescription.mp != NULL) ? (double) mp3DataDescription.samplerate : 44100.0;
    return soundFormat.sampleRate;
}

- (SndSampleFormat) dataFormat
{
    return soundFormat.dataFormat;
}

- (int) channelCount
{
#if 0
    if(preDecode) {
	return soundFormat.channelCount;
    }
    else if(mp3DataDescription.mp != NULL) {
	return mp3DataDescription.stereo;
    }
    else
	return soundFormat.channelCount; // It's uninitialized.
#else
    return soundFormat.channelCount; // It's uninitialized.
#endif
}

// We completely spoof this for now. This will cause us problems if the new format is anything other
// than 44100 and 2 channels. However, the data format can differ and we will convert correctly in
// insertIntoAudioBuffer:
- (int) convertToSampleFormat: (SndSampleFormat) toFormat
	   samplingRate: (double) toRate
	   channelCount: (int) toChannelCount
{
    // we decode into either of these formats.
    if((toFormat != SND_FORMAT_LINEAR_16 && toFormat != SND_FORMAT_FLOAT) || 
       toRate != [self samplingRate] || toChannelCount != [self channelCount])
       return SND_ERR_UNKNOWN;
    else
       return SND_ERR_NONE;
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

- copyWithZone: (NSZone *) zone
{
    SndMP3 *copySound = [[[self class] allocWithZone: zone] init];
    
    copySound->encodedFrameLocationsCount = encodedFrameLocationsCount;
    copySound->currentMP3FrameID = currentMP3FrameID;
    copySound->duration = duration;
    copySound->soundFormat.frameCount = soundFormat.frameCount;
    copySound->decodedSampleCount = decodedSampleCount;
    copySound->bDecoding = bDecoding;
    
    copySound->mp3Data = [mp3Data copy];
    copySound->mp3DataDescription = mp3DataDescription;
    
    // The array of encoded frame locations.
    if(encodedFrameLocationsCount != 0 && encodedFrameLocations != NULL) {
	long bytesToCopy = encodedFrameLocationsCount * sizeof(long);
	
	if((copySound->encodedFrameLocations = malloc(bytesToCopy)) != NULL)
	    memcpy(copySound->encodedFrameLocations, encodedFrameLocations, bytesToCopy);	
    }
    
    // The cached last frame decoded.
    copySound->decodedBufferCache = [decodedBufferCache copy];

    copySound->pcmData = [pcmData copy];
    // copySound->pcmDataLock = [pcmDataLock copy];
    
    return copySound;
}

- (void) dealloc
{
    [mp3Data release];
    mp3Data = nil;
    [pcmData release];
    pcmData = nil;
    [pcmDataLock release];
    pcmDataLock = nil;
    [decodedBufferCache release];
    decodedBufferCache = nil;
    if (encodedFrameLocations)
	free(encodedFrameLocations);
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
    short pcm[MAX_MPEG_SAMPLES_PER_FRAME * 2]; // conversion buffer, stereo 16 bit integers.
    long mp3DataPos    = 0;
    long mp3DataLength = [mp3Data length];
    //    long length = 0;
    long samplesCreated = 0;
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
    hip_decode_init(&mp3DataDescription);
    
    pcmData = [[NSMutableData alloc] initWithLength: pcmSize * sizeof(short) * 2];
    [pcmDataLock unlock];
    
    while (mp3DataPos < mp3DataLength || samplesCreated > 0) {
	int mp3FeedAmount = 417; // a frame
	int bytes_created;
	
	if (mp3DataPos + mp3FeedAmount > mp3DataLength)
	    mp3FeedAmount = mp3DataLength - mp3DataPos;
	
	bytes_created = hip_decode_headers(&mp3DataDescription, mp3DataBytes + mp3DataPos, mp3FeedAmount, (char *) pcm, 4608);
	samplesCreated = bytes_created / sizeof(short) / (mp3DataDescription.stereo ? mp3DataDescription.stereo : 2);
	// NSLog(@"samplesCreated = %d\n", samplesCreated);
	mp3DataPos += mp3FeedAmount;
	
	if (samplesCreated > 0) {
	    long i, offset = 0, pos = samplesRecovered * 2;
	    long sams_to_unpack = samplesCreated;
	    
	    if (sams_created_total + samplesCreated > requestedStartSample) {
		short *pData = NULL;
		offset = requestedStartSample - sams_created_total;
		
		if (offset < 0)
		    offset = 0;
		
		if (sams_to_unpack + samplesRecovered > requestedSampleCount)
		    sams_to_unpack = requestedSampleCount - samplesRecovered;
		
		[pcmDataLock lock];
		while (samplesRecovered + sams_to_unpack > pcmSize) {
		    pcmSize += growSize;
		    [pcmData setLength: pcmSize * sizeof(short) * mp3DataDescription.stereo];
		}
		pData = [pcmData mutableBytes]; // get fresh pointer in case resize moved our data
		for (i = offset; i < sams_to_unpack * mp3DataDescription.stereo; i++) {
		    pData[pos++] = pcm[i];
		}
		samplesRecovered += sams_to_unpack;
		[pcmDataLock unlock];
	    }
	}
	sams_created_total  += samplesCreated;
	decodedSampleCount += samplesCreated;
	iterations++;
#if DEBUG_READING
	NSLog(@"[%04li] Decoded: %li/%li\n", iterations, decodedSampleCount, soundFormat.frameCount);
#endif
	if (samplesRecovered >= requestedSampleCount)
	    break;
    }
    soundFormat.frameCount = samplesRecovered;
    duration = soundFormat.frameCount / [self samplingRate];
    [pcmDataLock lock];
    [pcmData setLength: soundFormat.frameCount * sizeof(short) * 2];
    duration = soundFormat.frameCount / [self samplingRate];
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
    mp3Data = [[NSData alloc] initWithContentsOfURL: soundURL];
    if(mp3Data != nil) {
        [self checkID3Tag: mp3Data];
        [self findFrameHeadersInBitstream: mp3Data];
      
        // TODO could be erroneous to assume SND_MPEGV1_SAMPLES_PER_FRAME
        soundFormat.frameCount = encodedFrameLocationsCount * SND_MPEGV1_SAMPLES_PER_FRAME; 
        duration = soundFormat.frameCount / [self samplingRate];
    }
    [localPool release];
    return mp3Data != nil;
}

////////////////////////////////////////////////////////////////////////////////
// readSoundURL:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundURL: (NSURL *) soundURL
{
    return [self readSoundURL: soundURL startTimePosition: 0.0 duration: -1];
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
#if DEBUG_READING
    NSLog(@"%@ Found %li frames\n", soundURL, encodedFrameLocationsCount);
#endif
    if (segmentDuration == -1.0)
        segmentDuration = duration;
    
    if (segmentStartTime > duration) 
        return SND_ERR_BAD_STARTTIME;
    else if (segmentStartTime + segmentDuration > duration)
        return SND_ERR_BAD_DURATION;

    duration = segmentDuration;

    if(preDecode) {
        [pcmDataLock lock];
        if (pcmData) {
            [pcmData release];
            pcmData = nil;
        }
        [pcmDataLock unlock];
        
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
    else { // initialise HIP now since it is otherwise initialised in the decodeThread in the pre-decode case.
        //int bytesRetrieved;
        //int bytesToRetrieve = MAX_MPEG_SAMPLES_PER_FRAME * sizeof(short) * [self channelCount];
        
        hip_decode_init(&mp3DataDescription);
        // Attempt to decode the first header in order to prime the HIP decoding process. We expect no data to be returned.
        //bytesRetrieved = hip_decode_headers(&mp3DataDescription, (unsigned char *) [mp3Data bytes], encodedFrameLocations[1] - encodedFrameLocations[0], (char *) decodedPCM, bytesToRetrieve);
        //if(bytesRetrieved != 0)  // Actually we'd have a problem if we did get data back.
            //NSLog(@"Retrieved non-zero number of bytes (%d) on first call to hip_decode_headers()!\n", bytesRetrieved);
    }
    // This is probably a bit kludgy but it will do for now.
    loopEndIndex = [self lengthInSampleFrames] - 1;
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

// Given a range of decoded samples, return which range of MP3 bitstream frames will retrieve those.
// TODO handle VBR (Variable Bit Rate).
- (NSRange) findInBitstreamSamplesInRange: (NSRange) sndReadingRange
{
    NSRange bitstreamFrames;
    int samplesPerMP3Frame = SND_MPEGV1_SAMPLES_PER_FRAME;
	
    bitstreamFrames.location = floor(sndReadingRange.location / samplesPerMP3Frame);
    bitstreamFrames.length   = floor(((sndReadingRange.location % samplesPerMP3Frame) + sndReadingRange.length) / samplesPerMP3Frame);
    return bitstreamFrames;
}

// Returns the location in the MP3 data (mp3Data) and the length of that data to feed to the HIP decoder.
- (NSRange) decodeRangeOfBitstreamFrame: (int) MP3FrameIDToDecode
{
    NSRange decodeRange;
    
    if(MP3FrameIDToDecode < 0) { 
	decodeRange.length = encodedFrameLocations[1] - encodedFrameLocations[0];
	decodeRange.location = encodedFrameLocations[0];	
    }
    if(MP3FrameIDToDecode >= encodedFrameLocationsCount - 1) {
	decodeRange.length = [mp3Data length] - encodedFrameLocations[encodedFrameLocationsCount - 1];
	decodeRange.location = encodedFrameLocations[encodedFrameLocationsCount - 1];	    
    }
    else {
	decodeRange.length = encodedFrameLocations[MP3FrameIDToDecode + 1] - encodedFrameLocations[MP3FrameIDToDecode];
	decodeRange.location = encodedFrameLocations[MP3FrameIDToDecode];	    
    }
    return decodeRange;
}

- (void) resetMP3StreamForNoncontiguousFrame: (int) MP3FrameIDToDecode
{
    int framesToBacktrack;
    int frameToRead;
    unsigned char *mp3DataBytes = (unsigned char *) [mp3Data bytes];    
    SndAudioBuffer *discardedDecodeBuffer = [SndAudioBuffer audioBufferWithDataFormat: SND_FORMAT_LINEAR_16
									 channelCount: [self channelCount]
									 samplingRate: [self samplingRate]
									   frameCount: MAX_MPEG_SAMPLES_PER_FRAME];
    int bytesRetrieved;
    int bytesToRetrieve = [discardedDecodeBuffer lengthInBytes];
    NSRange decodeRange;

#if DEBUG_BACKTRACK
    NSLog(@"resetMP3StreamForNoncontiguousFrame: resetting decoding for currentMP3FrameID %d MP3FrameIDToDecode %d\n",
    	      currentMP3FrameID, MP3FrameIDToDecode);
#endif
    
    decodeRange = [self decodeRangeOfBitstreamFrame: MP3FrameIDToDecode];

    // decode the header in order to determine the main_data_begin value in the Layer 3 sideinfo.
    bytesRetrieved = hip_decode_headers(&mp3DataDescription, mp3DataBytes + decodeRange.location, decodeRange.length, (char *) [discardedDecodeBuffer bytes], bytesToRetrieve);
    // NSLog(@"resetMP3StreamForNoncontiguousFrame: reading frame %d to determine main_data_begin bytesToRetrieve = %d bytesRetrieved = %d\n",
    //  MP3FrameIDToDecode, bytesToRetrieve, bytesRetrieved);
    
    // TODO For some as yet unexplained reason, we need to track back two extra frames before we decode a frame 
    // accurately. My hypothesis is that the lookahead nature of HIP (you receive the decoding of a frame on the
    // second call to hip_decode_headers) accounts for 1 extra frame, but hip_audiodata_precedesframes should account
    // for the other, unless the calculation of the number of bitstream frames corresponding to main_data_begin
    // is incorrect.
    framesToBacktrack = hip_audiodata_precedesframes(&mp3DataDescription) + 2; // TODO 2
#if DEBUG_BACKTRACK
    NSLog(@"resetMP3StreamForNoncontiguousFrame: Need to back track %d MP3 frames from frame %d (just decoded)\n", framesToBacktrack, MP3FrameIDToDecode);
#endif
    hip_decode_reset(&mp3DataDescription);
    
    for(frameToRead = MP3FrameIDToDecode - framesToBacktrack; frameToRead >= 0 && frameToRead < MP3FrameIDToDecode; frameToRead++) {
	decodeRange = [self decodeRangeOfBitstreamFrame: frameToRead];

	bytesRetrieved = hip_decode_headers(&mp3DataDescription, mp3DataBytes + decodeRange.location, decodeRange.length, (char *) [discardedDecodeBuffer bytes], bytesToRetrieve);
#if DEBUG_BACKTRACK
	if(bytesRetrieved == 0) {
	    NSLog(@"resetMP3StreamForNoncontiguousFrame: Need more data in backtrack bytesRetrieved == 0, frameToRead = %d MP3FrameIDToDecode %d\n",
		  frameToRead, MP3FrameIDToDecode);
	    // NSLog(@"%@\n", decodedBufferAccessCount);
	}
#endif
#if DEBUG_BACKTRACK
	NSLog(@"resetMP3StreamForNoncontiguousFrame: backtrack reading frame %d decodeRange.location %ld bytesToRetrieve = %d bytesRetrieved = %d\n",
	      frameToRead, decodeRange.location, bytesToRetrieve, bytesRetrieved);
#endif
    }
}

// Decode the given MP3 frame ID from mp3Data, returning a decoded PCM SndAudioBuffer.
- (SndAudioBuffer *) decodeMP3FrameID: (int) MP3FrameIDToDecode
{
    long framesCreated = 0;
    int bytesRetrieved;
    int bytesToRetrieve;
    NSRange decodeRange;
    unsigned char *mp3DataBytes = (unsigned char *) [mp3Data bytes];
    // Define our buffer to match the format we expect HIP to provide decoded output in.
    // Set length to the largest number of samples per MPEG frame, regardless of MPEG Layer.
    SndAudioBuffer *decodedPCMBuffer = [SndAudioBuffer audioBufferWithDataFormat: SND_FORMAT_LINEAR_16
								    channelCount: [self channelCount]
								    samplingRate: [self samplingRate]
								      frameCount: MAX_MPEG_SAMPLES_PER_FRAME];
    
    // TODO debugging
    int prevMP3FrameID;
    
    // This serves to prevent disrupting the backtracking when the sound is accessed by multiple threads.
    [pcmDataLock lock]; 

#if DEBUG_DECODE
    NSLog(@"decodeMP3FrameID: decoding frame %d\n", MP3FrameIDToDecode);
#endif
    
    if(currentMP3FrameID + 1 != MP3FrameIDToDecode) { // If not serially contiguous, we need to reset the decoding.
#if DEBUG_CACHE
	NSLog(@"decodeMP3FrameID: non-contiguous frame request, need to reset decoding, cached buffers %@\n", decodedBufferCache);
#endif
	[self resetMP3StreamForNoncontiguousFrame: MP3FrameIDToDecode];
    }

    prevMP3FrameID = currentMP3FrameID;  // TODO debugging
    currentMP3FrameID = MP3FrameIDToDecode;  // retain the current bitstream frame ID.
    
    decodeRange = [self decodeRangeOfBitstreamFrame: MP3FrameIDToDecode];
    
#if DEBUG_DECODE
    NSLog(@"decodeMP3FrameID: currentMP3FrameID = %d, decodeRange.location = %d, decodeRange.length = %d\n",
	  currentMP3FrameID, decodeRange.location, decodeRange.length);
#endif
    
    // Decode a frame. The decoded data is cached.
    bytesToRetrieve = [decodedPCMBuffer lengthInBytes];
    bytesRetrieved = hip_decode_headers(&mp3DataDescription, mp3DataBytes + decodeRange.location, decodeRange.length, (char *) [decodedPCMBuffer bytes], bytesToRetrieve);
    // NSLog(@"decodeMP3FrameID: after hip_decode_headers() bytesToRetrieve = %d bytesRetrieved = %d\n", bytesToRetrieve, bytesRetrieved);

    /* bytesRetrieved = 0:  need more data to decode */
    /* bytesRetrieved = -1:  error.  Assume 0 pcm output */
    /* bytesRetrieved = otherwise: number of bytes output */
    if(bytesRetrieved < 0) {
	NSLog(@"Error: hip_decode_headers error bytesToRetrieve = %d, bytesRetrieved = %d, decodeRange.location = %d, decodeRange.length = %d, decodedPCMBuffer %@\n",
	      bytesToRetrieve, bytesRetrieved, decodeRange.location, decodeRange.length, decodedPCMBuffer);
	return 0;
    }
    if(bytesRetrieved == 0) {
	long moreDataFrom;
	
#if DEBUG_DECODE
	NSLog(@"decodeMP3FrameID:Need more data, bytesToRetrieve = %d, bytesRetrieved == 0, currentMP3FrameID = %d, decodeRange.location = %d, decodeRange.length = %d\n",
	      bytesToRetrieve, currentMP3FrameID, decodeRange.location, decodeRange.length);
	NSLog(@"prevMP3FrameID = %d\n", prevMP3FrameID);
	NSLog(@"mp3DataDescription.bitrate = %d, mp3DataDescription.samplerate = %d, mp3DataDescription.framesize = %d\n",
	      mp3DataDescription.bitrate, mp3DataDescription.samplerate, mp3DataDescription.framesize);
#endif
	if(MP3FrameIDToDecode == 0) // If the first frame, this is expected, we resupply the bitstream
	    moreDataFrom = decodeRange.location;
	else
	    moreDataFrom = decodeRange.location + decodeRange.length;
	bytesRetrieved = hip_decode_headers(&mp3DataDescription, mp3DataBytes + moreDataFrom, decodeRange.length, (char *) [decodedPCMBuffer bytes], bytesToRetrieve);

	// NSLog(@"Decoding from %d, Retried hip_decode_headers, bytesRetrieved = %d\n", moreDataFrom, bytesRetrieved);
    }
    framesCreated =  bytesRetrieved / sizeof(short) / (mp3DataDescription.stereo ? mp3DataDescription.stereo : 2);
#if DEBUG_DECODE
    NSLog(@"decodeMP3FrameID: framesCreated = %d\n", framesCreated);
#endif
    // TODO set the frame count of the decodedPCMBuffer.
    // [decodedPCMBuffer setLengthInSampleFrames: framesCreated];
    
    
    /////////////////////////////////////////////////////////////////
    
    
    // TODO [decodedBufferCache deleteOldestKey]; when we write SndAgedDictionary which records the time of each key's access.
    // For now, only remove when the dictionary has more than our maximum number (CACHED_DECODED_BUFFERS) of cached buffers and remove 
    if([decodedBufferCache count] > CACHED_DECODED_BUFFERS - 1) {
	// TODO this isn't guaranteed to remove the oldest buffer, but we punt for now it will be ok to prove the concept...
	// NSNumber *bufferKeyToRemove = [[[decodedBufferCache allKeys] sortedArrayUsingSelector: @selector(compare:)] objectAtIndex: 0];
	NSArray *accessCount = [decodedBufferAccessCount keysSortedByValueUsingSelector: @selector(compare:)];
	NSNumber *bufferKeyToRemove = [accessCount objectAtIndex: 0];

	/////////////////////////////////////////////////////////////////

#if DEBUG_CACHE
	NSLog(@"decodeMP3FrameID: Removing old key %@ from cache\n", bufferKeyToRemove);
#endif
	[decodedBufferCache removeObjectForKey: bufferKeyToRemove];

	// TODO
	[decodedBufferAccessCount removeObjectForKey: bufferKeyToRemove];
    }
    [decodedBufferCache setObject: decodedPCMBuffer forKey: [NSNumber numberWithInt: MP3FrameIDToDecode]];
    
    // TODO
    [decodedBufferAccessCount setObject: [NSNumber numberWithInt: accessTime++] forKey: [NSNumber numberWithInt: MP3FrameIDToDecode]];

    [pcmDataLock unlock];
    
    return decodedPCMBuffer; // set to autorelease when created.
}

// Decode on the fly.
- (long) decodeIntoAudioBuffer: (SndAudioBuffer *) anAudioBuffer
		intoFrameRange: (NSRange) bufferRange
                samplesInRange: (NSRange) sndReadingRange;
{
    // Since we do no resampling, we can use bufferRange.length here
    unsigned int numOfFramesToCopy = MIN(bufferRange.length, sndReadingRange.length);
    // Note we distinguish encoded (MP3 bitstream data) frames from our typical use of the term "frame".
    int samplesPerMP3Frame = SND_MPEGV1_SAMPLES_PER_FRAME;
    NSRange bitstreamFrames;
    int decodeFromMP3FrameID;
    long totalFramesCreated = 0;
    SndAudioBuffer *decodedPCMBuffer;
        
    // Find which range of MP3 frames to decode.
    sndReadingRange.length = numOfFramesToCopy;
    bitstreamFrames = [self findInBitstreamSamplesInRange: sndReadingRange];
    decodeFromMP3FrameID = bitstreamFrames.location;

#if SNDMP3_DEBUG
    NSLog(@"decodeIntoAudioBuffer:intoFrameRange: [%d,%d] samplesInRange: [%d,%d], bitstreamFrames: [%li,%i]\n", 
	  bufferRange.location, bufferRange.length,
	  sndReadingRange.location, sndReadingRange.length, bitstreamFrames.location, bitstreamFrames.length);
#endif
    
    // Use a combination of cached and newly decoded MP3 frames to fill the buffer.
    // Typically however, the buffer to fill will be less than one MP3 decoded frame.
    while (totalFramesCreated < numOfFramesToCopy) {
        NSRange decodedFrameRange; // The range of sample frames to read within the cached decoded MP3 frame.
	long framesInserted;
	
        // Check if we can use the cached PCM data.
	decodedPCMBuffer = [decodedBufferCache objectForKey: [NSNumber numberWithInt: decodeFromMP3FrameID]];
	
	// TODO this should be inside decodedBufferCache when it is a SndAgedDictionary
	if(decodedPCMBuffer != nil) {
	    NSNumber *key = [NSNumber numberWithInt: decodeFromMP3FrameID];
#if DEBUG_CACHE
	    NSLog(@"decodeIntoAudioBuffer: retrieved frame %d from cache\n", decodeFromMP3FrameID);
#endif
	    [decodedBufferAccessCount setObject: [NSNumber numberWithInt: accessTime++] forKey: key];
	}
	
	
        if (decodedPCMBuffer == nil) {  // No, we need to decode the data
	    decodedPCMBuffer = [self decodeMP3FrameID: decodeFromMP3FrameID];
	    
	    if ([decodedPCMBuffer lengthInSampleFrames] <= 0)
		NSLog(@"decodeIntoAudioBuffer: Assertion failed, decoded <= 0 frames (%ld) from MP3 bitstream FrameID %d\n", [decodedPCMBuffer lengthInSampleFrames], decodeFromMP3FrameID);
        }

	// TODO using sndReadingRange.location not correct?
        decodedFrameRange.location = (sndReadingRange.location + totalFramesCreated) % samplesPerMP3Frame;
        // We copy the number of frames remaining in the decoded MP3 frame or the number of frames remaining to copy, whichever is less.
        decodedFrameRange.length = MIN((samplesPerMP3Frame - decodedFrameRange.location), (numOfFramesToCopy - totalFramesCreated));
        
#if SNDMP3_DEBUG
        NSLog(@"decodeIntoAudioBuffer: inserting intoFrameRange: [%d,%d] from decoded MP3 frame %d in the range [%d,%d]\n", 
	      bufferRange.location, bufferRange.length, decodeFromMP3FrameID, decodedFrameRange.location, decodedFrameRange.length);
	{
	    float min, max;
	    [decodedPCMBuffer findMin: &min max: &max];
	    NSLog(@"decodedPCMBuffer min %f max %f\n", min, max);
	}

#endif
        framesInserted = [anAudioBuffer copyFromBuffer: decodedPCMBuffer
					intoFrameRange: bufferRange
					fromFrameRange: decodedFrameRange];

        // update the buffer range to copy into for the next iteration, based on any frames copied in a previous iteration.
        bufferRange.location += framesInserted;
        bufferRange.length -= framesInserted;
	
	totalFramesCreated += framesInserted;
        decodeFromMP3FrameID++;
    }
#if SNDMP3_DEBUG
    {
        float min, max;
        [anAudioBuffer findMin: &min max: &max];
	if(min <= -1.000 || max >= 1.000) {
	    long i;
	    int c;
	    
	    NSLog(@"hit minimum or maximum value anAudioBuffer %@\n", anAudioBuffer);
	    for(i = 0; i < [anAudioBuffer lengthInSampleFrames]; i++)
		for(c = 0; c < [anAudioBuffer channelCount]; c++) {
		    float sample = [anAudioBuffer sampleAtFrameIndex: i channel: c];
		    if(sample <= -1.000 || sample >= 1.000)
			NSLog(@"found at %ld, channel %d: %f\n", i, c, sample);
		}
	}
        NSLog(@"completed decodeIntoAudioBuffer: currentMP3FrameID %d: min: %5.3f max: %5.3f bufferRange: [%li,%i] sndReadingRange: [%li,%i]\n",
	      currentMP3FrameID, min, max, bufferRange.location, bufferRange.length, sndReadingRange.location, sndReadingRange.length);
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
		    NSLog(@"f SndMP3: min: %5.3f max: %5.3f [dataLen:%i buffLen:%i loc:%li len:%i]\n",
			  MAX(-1, min), MIN(1,max), sndDataLength, bufferRange.length, sndReadingRange.location, bufferRange.length);
		}
#endif
	    }
	    else
		NSLog(@"SndMP3 -insertPreDecodedIntoAudioBuffer: - Unhandled number of channels %d", buffChans);
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
		    NSLog(@"SndMP3: min: %5.3f max: %5.3f [dataLen:%li buffLen:%i loc:%li len:%i]\n",
			  MAX(-1, min), MIN(1,max), sndDataLength, bufferRange.length, sndReadingRange.location, bufferRange.length);
		}
#endif
	    }
	    else
		NSLog(@"SndMP3 -insertPreDecodedIntoAudioBuffer: %@ - Unhandled number of channels %d of SND_FORMAT_LINEAR_16 data", anAudioBuffer, buffChans);
	    break;
	}
	default:
	    NSLog(@"SndMP3 -insertPreDecodedIntoAudioBuffer: - unhandled data format %d", [anAudioBuffer dataFormat]);
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
    if(sndReadingRange.length <= 0) {
	NSLog(@"insertIntoAudioBuffer:intoFrameRange:samplesInRange: with %d samples into buffer?\n", sndReadingRange.length);
	return 0;
    }
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

#if DEBUG_READING
    NSLog(@"requested: [%li, %li]\n", r.location, r.length + r.location);
#endif
    if(preDecode) {
        long endIndex = r.length + r.location;

        while (bDecoding && decodedSampleCount < endIndex)
            [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.25]];
#if DEBUG_READING
	NSLog(@"decoded: %li  %s\n",
	      decodedSampleCount, decodedSampleCount > endIndex ? "" : "***");
#endif
    }

    // TODO Should initialize this with the native data format?
    [ab initWithDataFormat: SND_FORMAT_FLOAT
	      channelCount: 2
              samplingRate: [self samplingRate]
                frameCount: r.length];

    [self fillAudioBuffer: ab toLength: r.length samplesInRange: r];

    return [ab autorelease];
}

////////////////////////////////////////////////////////////////////////////////

// Decode a buffers worth of data and return a pointer to the decoded PCM data. 
// This is no different than just retrieving a SndAudioBuffer, but it allows a faster format for clients using Snd's, in particular SndView.
- (void *) fragmentOfFrame: (int) frame 
	   indexInFragment: (unsigned int *) currentFrame 
	    fragmentLength: (unsigned int *) fragmentLength
		dataFormat: (SndSampleFormat *) dataFormat
{
    NSRange fragmentFrameRange = { frame, 2048 }; // Hard to determine what the length should be
    
    [pcmBufferToAccess release];
    pcmBufferToAccess = [[self audioBufferForSamplesInRange: fragmentFrameRange] retain];
    if(pcmBufferToAccess != nil) {
	*currentFrame = 0;
	*fragmentLength = [pcmBufferToAccess lengthInSampleFrames];
	*dataFormat = [pcmBufferToAccess dataFormat];
	// NSLog(@"fragmentOfFrame %d currentFrame = %d, fragmentLength = %d, dataFormat = %d\n", 
	//      frame, *currentFrame, *fragmentLength, *dataFormat);
	return [pcmBufferToAccess bytes];	
    }
    else
	return NULL;
}

- (Snd *) soundFromSamplesInRange: (NSRange) frameRange
{
    // Copy the decoded data from self (the MP3 compressed Snd) to the new sound.
    SndAudioBuffer *bufferOfFragment = [self audioBufferForSamplesInRange: frameRange];
    Snd *newSound = [[Snd alloc] initWithAudioBuffer: bufferOfFragment];
    
    // Duplicate all other ivars
    [newSound setInfo: [self info]];
    
    [newSound setDelegate: [self delegate]];		 
    [newSound setName: [self name]];
    [newSound setConversionQuality: conversionQuality];

    [newSound setLoopWhenPlaying: loopWhenPlaying];
    [newSound setLoopStartIndex: loopStartIndex];
    [newSound setLoopEndIndex: loopEndIndex];
    [newSound setAudioProcessorChain: [self audioProcessorChain]];

    return [newSound autorelease];
}

@end

#else
#warning Did not compile SndMP3 class since HIP library was not installed.
#endif
