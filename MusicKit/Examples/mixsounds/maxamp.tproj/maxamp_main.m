#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    static SndSoundStruct *aStruct;
    short *data, *dataEnd, *dataStart, wd;
    short maxAmp, minAmp;
    int sampNum, argumentIndex;
    double time;
    
    if (argc < 2) {
        fprintf(stderr, "Usage: maxamp inputfile ...\n");
        exit(1);
    }
    for (argumentIndex = 1; argumentIndex < argc; argumentIndex++) {
	NSString *inFile = [NSString stringWithCString: argv[argumentIndex]];
	
        if (SndReadSoundfile(inFile,  &aStruct) != SND_ERR_NONE) {
	    NSLog(@"Can't find file.\n");
	    exit(1);
        }
        if (aStruct->dataFormat != SND_FORMAT_LINEAR_16) {
	    NSLog(@"Input file must be in 16-bit linear format.\n");
	    exit(1);
        }
        data = (short *)(((char *) aStruct) + aStruct->dataLocation);
        dataEnd = (short *)(((char *) data) + aStruct->dataSize);
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
        sampNum /= aStruct->channelCount;
        time = (double) sampNum / (double) (aStruct->samplingRate);
        if (-minAmp > maxAmp)
	    maxAmp = -minAmp;
        NSLog(@"Maxamp is %f at time %f (%s).\n", maxAmp, time, inFile);
    }
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}   
