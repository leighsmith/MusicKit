#import <musickit/musickit.h>
#import <sys/file.h>
#import "MixInstrument.h"

/* mixsounds is an example of a Music Kit performance that actually makes
   no sound. Rather, it's "output" is a sound file that is the result of
   a mix of the soundfiles specified in its input scorefile. 
   See the README file on this directory for details.
   
   Since no real-time interaction is involved, and since we want the program
   to run as fast as possible, the Conductor is set to unclocked mode. 
   In unclocked mode the Conductor's +startPerformance method initiates a 
   tight loop that sends Notes as fast as possible until all Notes have been 
   sent, then returns. In this program, each "Note" is actually a 
   soundfile mix specification. */

int main(int ac, char *av[])
{
    int i,partCount;
    id aSFPerformer,mixIns;
    double samplingRate = 22050;
    int channelCount = 2;
    int inFd,outFd;
    id scoreInfo,noteSenders;
    NXStream *inStream,*outStream;
    if (ac != 3) {
	fprintf(stderr,
		"Usage: mixsounds <input score file> <output snd file>.\n");
	exit(1);
    }
    inFd = open(av[1],O_RDONLY,0660); 
    if (inFd == -1) {
	fprintf(stderr,"Can't open %s\n.",av[1]);
	exit(1);
    } else fprintf(stderr,"Input file: %s\n",av[1]);
    outFd = creat(av[2],0660);
    if (outFd == -1) {
	fprintf(stderr,"Can't create %s\n.",av[2]);
	exit(1);
    } else fprintf(stderr,"Output file: %s\n",av[2]);
    inStream = NXOpenFile(inFd,NX_READONLY);
    outStream = NXOpenFile(outFd,NX_WRITEONLY);
    aSFPerformer = [[ScorefilePerformer alloc] init];
    [aSFPerformer setStream:inStream];
    [aSFPerformer activate]; 
    scoreInfo = [aSFPerformer info];
    if (scoreInfo) { /* Configure performance as specified in info. */ 
	if ([scoreInfo isParPresent:MK_samplingRate]) 
	    samplingRate = [scoreInfo parAsDouble:MK_samplingRate];
	if ([scoreInfo isParPresent:[Note parName:"channelCount"]])
	    channelCount = [scoreInfo parAsInt:[Note parName:"channelCount"]];
    }
    mixIns = [[MixInstrument alloc] init];
    [mixIns setSamplingRate:samplingRate channelCount:channelCount stream:
     outStream];
    noteSenders = [aSFPerformer noteSenders];
    partCount = [noteSenders count];
    for (i = 0; i < partCount; i++) 
	[[noteSenders objectAt:i] connect:[mixIns noteReceiver]];
    [noteSenders free];
    [Conductor setClocked:NO];     /* User process runs as fast as it can. */
    fprintf(stderr,"mixing...\n");
    [Conductor startPerformance];  /* Start sending Notes, loops till done.*/
    
     /* Conductor's startPerformance method
       does not return until the performance is over.  Note, however, that
       if the Conductor is in a different mode, startPerformance returns 
       immediately (if it is in clocked mode or if you have specified that the 
       performance is to occur in a separate thread).  See the Conductor 
       documentation for details. 
       */

    fprintf(stderr,"...done\n");
    NXClose(outStream);
    exit(0);
}







