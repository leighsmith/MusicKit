
#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

const char * const help =
  "usage: extractchannel [-c <chan>] inputfile outputfile.\n";

static char *makeStr(char *str)
{
    char *newStr;
    if (!str)
      return NULL;
    newStr = malloc(strlen(str)+1);
    strcpy(newStr,str);
    return newStr;
}

int main (int argc, const char *argv[])
{
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    static SndSoundStruct *aStruct;
    char *inFile,*outFile;
    short *data,*dataEnd,*newDataPtr;
    unsigned whichChan = 1;
    int i;
    if (argc < 3) {
        fprintf(stderr,help);
        exit(1);
    }
    for (i=1; i<(argc-1); i++) {
        if ((strcmp(argv[i],"-c") == 0)) {
            i++;
            if (i < argc)
              whichChan = atoi(argv[i]);
            if (whichChan > 2 || whichChan == 0) {
                NSLog(@"Channel must be 1 or 2.\n");
                exit(1);
            }
        }
    }
    outFile = makeStr(argv[argc-1]);
    inFile = makeStr(argv[argc-2]);
    if (SndReadSoundfile(inFile,  &aStruct) != SND_ERR_NONE) {
        NSLog(@"Can't find file.\n");
        exit(1);
    }
    if (aStruct->channelCount != 2) {
        NSLog(@"Input file must be stereo.\n");
        exit(1);
    }
    if (aStruct->dataFormat != SND_FORMAT_LINEAR_16) {
        NSLog(@"Input file must be in 16-bit linear format.\n");
        exit(1);
    }
    data = (short *)(((char *)aStruct) + aStruct->dataLocation);
    dataEnd = (short *)(((char *)data) + aStruct->dataSize);
    newDataPtr = data;
    if (whichChan == 2)
      data++;
    NSLog(@"Extracting channel %d...\n",(int)whichChan);
    while (data < dataEnd) {
        *newDataPtr++ = *data;
        data += 2;
    }
    aStruct->dataSize /=2;
    aStruct->channelCount = 1;
    if (SndWriteSoundfile(outFile, aStruct) != SND_ERR_NONE) {
        NSLog(@"Can't write file.\n");
        exit(1);
    }
    NSLog(@"done\n");
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}    
