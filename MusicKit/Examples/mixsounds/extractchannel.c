#import <sound/sound.h>
#import <stdio.h>
#import <ansi/string.h>

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

int main(ac, av)
    int ac;
    char * av[];
{
    static SNDSoundStruct *aStruct;
    char *inFile,*outFile;
    short *data,*dataEnd,*newDataPtr;
    unsigned whichChan = 1;
    int i;
    if (ac < 3) {
	fprintf(stderr,help);
	exit(1);
    }
    for (i=1; i<(ac-1); i++) {
	if ((strcmp(av[i],"-c") == 0)) {
	    i++;
	    if (i < ac)
	      whichChan = atoi(av[i]);
	    if (whichChan > 2 || whichChan == 0) {
		fprintf(stderr,"Channel must be 1 or 2.\n"); 
		exit(1);
	    }
	}
    }
    outFile = makeStr(av[ac-1]);
    inFile = makeStr(av[ac-2]);
    if (SNDReadSoundfile(inFile,  &aStruct) != SND_ERR_NONE) {
	fprintf(stderr,"Can't find file.\n");
	exit(1);
    }
    if (aStruct->channelCount != 2) {
	fprintf(stderr,"Input file must be stereo.\n");
	exit(1);
    }
    if (aStruct->dataFormat != SND_FORMAT_LINEAR_16) {
	fprintf(stderr,"Input file must be in 16-bit linear format.\n");
	exit(1);
    }
    data = (short *)(((char *)aStruct) + aStruct->dataLocation);
    dataEnd = (short *)(((char *)data) + aStruct->dataSize);
    newDataPtr = data;
    if (whichChan == 2)
      data++;
    fprintf(stderr,"Extracting channel %d...\n",(int)whichChan);
    while (data < dataEnd) {
	*newDataPtr++ = *data;
	data += 2;
    }
    aStruct->dataSize /=2;
    aStruct->channelCount = 1;
    if (SNDWriteSoundfile(outFile, aStruct) != SND_ERR_NONE) {
	fprintf(stderr,"Can't write file.\n");
	exit(1);
    }
    fprintf(stderr,"done\n");
    exit(0);
}    
