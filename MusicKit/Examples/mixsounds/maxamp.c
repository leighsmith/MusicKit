#import <sound/sound.h>
#import <stdio.h>
#import <string.h>
#import <math.h>
#import <architecture/byte_order.h>

const char * const help =
  "usage: maxamp inputfile ...\n";

static char *makeStr(char *str)
{
    char *newStr;
    if (!str)
      return NULL;
    newStr = malloc(strlen(str)+1);
    strcpy(newStr,str);
    return newStr;
}

void main(ac, av)
    int ac;
    char * av[];
{
    static SNDSoundStruct *aStruct;
    char *inFile;
    short *data,*dataEnd,*dataStart,wd;
    short maxAmp,minAmp;
    int sampNum, i;
    double time,amp;
    if (ac < 2) {
	fprintf(stderr,help);
	exit(1);
    }
    for (i=1; i<ac; i++) {
	inFile = makeStr(av[i]);
	if (SNDReadSoundfile(inFile,  &aStruct) != SND_ERR_NONE) {
		fprintf(stderr,"Can't find file.\n");
		exit(1);
	}
	if (aStruct->dataFormat != SND_FORMAT_LINEAR_16) {
		fprintf (stderr,
		"Input file must be in 16-bit linear format.\n");
		exit(1);
	}
	data = (short *)(((char *)aStruct) + aStruct->dataLocation);
	dataEnd = (short *)(((char *)data) + aStruct->dataSize);
	dataStart = data;
	maxAmp = 0;
	minAmp = 0;
	sampNum = dataStart;
	while (data < dataEnd) {
	        wd = NXSwapBigShortToHost(*data);
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
	time = (double)sampNum/(double)(aStruct->samplingRate);
	if (-minAmp > maxAmp) maxAmp = -minAmp;
	amp = ((double)maxAmp)/MAXSHORT;
	fprintf(stderr,
		"Maxamp is %f at time %f (%s).\n",amp,time,inFile);
    }
    exit(0);
}   


