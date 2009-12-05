#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    Snd *snd;
    short *data, *dataEnd, *dataStart, wd;
    short maxAmp, minAmp;
    int sampNum, argumentIndex;
    double time;
    
    if (argc < 2) {
        fprintf(stderr, "Usage: maxamp inputfile ...\n");
        exit(1);
    }
    for (argumentIndex = 1; argumentIndex < argc; argumentIndex++) {
	NSString *inFile = [NSString stringWithUTF8String: argv[argumentIndex]];
	snd = [[Snd alloc] init];
	
        if ([snd readSoundfile: inFile] != SND_ERR_NONE) {
	    NSLog(@"Can't find file %@\n", inFile);
	    exit(1);
        }
        if ([snd dataFormat] != SND_FORMAT_LINEAR_16) {
	    NSLog(@"Input file must be in 16-bit linear format.\n");
	    exit(1);
        }
        data = (short *) [snd bytes];
        dataEnd = (short *)(((char *) data) + [snd dataSize]);
        dataStart = data;
        maxAmp = 0;
        minAmp = 0;
        sampNum = (int) dataStart;
        while (data < dataEnd) {
	    wd = NSSwapBigShortToHost(*data);
	    if (wd > maxAmp) {
		maxAmp = wd;
		sampNum = data - dataStart;
	    }
	    else if (wd < minAmp) {
		minAmp = wd;
		sampNum = data - dataStart;
	    }
	    data++;
        }
        sampNum /= [snd channelCount];
        time = (double) sampNum / (double) ([snd samplingRate]);
        if (-minAmp > maxAmp)
	    maxAmp = -minAmp;
        NSLog(@"Maxamp is %f at time %f (%s).\n", maxAmp, time, inFile);
	[snd release];
    }
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}   
