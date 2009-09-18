
#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

const char * const help =
  "usage: extractchannel [-c <chan>] inputfile outputfile.\n";

int main (int argc, const char *argv[])
{
   NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    Snd *sound;
    Snd *newSound;
    NSString *inFile,*outFile;
    short *data, *dataEnd, *newDataPtr;
    unsigned whichChan = 1;
    int argumentIndex;
    int channelCount;
    
    if (argc < 3) {
        fprintf(stderr,help);
        exit(1);
    }
    for (argumentIndex = 1; argumentIndex < (argc - 1); argumentIndex++) {
        if ((strcmp(argv[argumentIndex], "-c") == 0)) {
            argumentIndex++;
            if (argumentIndex < argc)
              whichChan = atoi(argv[argumentIndex]);
            if (whichChan > 2 || whichChan == 0) {
                NSLog(@"Channel must be 1 or 2.\n");
                exit(1);
            }
        }
    }
    outFile = [NSString stringWithUTF8String: argv[argc - 1]];
    inFile = [NSString stringWithUTF8String: argv[argc - 2]];
    sound = [[Snd alloc] initFromSoundfile: inFile];
    if (sound == nil) {
        NSLog(@"Can't find file %@\n", inFile);
        exit(1);
    }
    channelCount = [sound channelCount];
    if (channelCount >= 2) {
        NSLog(@"Input file must be stereo.\n");
        exit(1);
    }
    if ([sound dataFormat] != SND_FORMAT_LINEAR_16) {
        NSLog(@"Input file must be in 16-bit linear format.\n");
        exit(1);
    }
    data = (short *)[sound data];
    dataEnd = (short *)(((char *)data) + [sound dataSize]);

    newSound = [[Snd alloc] initWithFormat: [sound dataFormat]
			      channelCount: 1
				    frames: [sound lengthInSampleFrames]
			      samplingRate: [sound samplingRate]];
    
    newDataPtr = (short *)[newSound data];
    NSLog(@"Extracting channel %d...\n", (int) whichChan);
    data += whichChan - 1;
    while (data < dataEnd) {
        *newDataPtr++ = *data;
        data += channelCount;
    }
    if ([newSound writeSoundfile: outFile] != SND_ERR_NONE) {
        NSLog(@"Can't write file %@\n", outFile);
        exit(1);
    }
    NSLog(@"done\n");
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}    
