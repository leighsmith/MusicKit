/* 
  mixscorefiles.m

  By David A. Jaffe.
  
  See README for a description of this program.
*/

/* This example program mixes any number of scorefiles. It parses and
   evaluates each input file and merges its output with that of the other 
   input file. This is done by reading a number of files into a single
   Score object. 

   The program allows the option of specifying a particular portion of each
   file to be used as well as a time offset. It also allows for single 
   global tempo.
   */

#import <musickit/musickit.h>

static const char *const helpString = 
"Usage: mixscorefiles -o <outFile> -i <inFile1> -i <inFile2> ...\n"
"Each input file specification can be immediately followed by timing variables:\n\n"
"	-f realNumber  first timeTag included in the mix\n"
"	-l realNumber  last timeTag included in the mix\n"
"	-s realNumber  timeTag shift\n";

main(ac,av) 
    int ac;
    char *av[]; 
{
    int i;
    char *inputFileName = NULL;
    char *outputFileName = NULL;
    double firstTimeTag = 0;
    double lastTimeTag = MK_ENDOFTIME;
    double timeShift = 0;
    id aScore = [[Score alloc] init];
    if (ac==1) {
	fprintf(stderr,helpString);
	exit(1);
    }
    for (i=1; i<ac; i++) {
	if (!strcmp(av[i],"-i"))  /* Input file */
	    if (++i == ac)
		fprintf(stderr,"Missing input file name.\n");
	    else {
		if (inputFileName) /* Do previous file. */
		    [aScore readScorefile:inputFileName 
		     firstTimeTag:firstTimeTag
		     lastTimeTag:lastTimeTag timeShift:timeShift];
		firstTimeTag = 0;  /* Reset variables for next file */
		lastTimeTag = MK_ENDOFTIME;
		timeShift = 0;
		inputFileName = av[i];
	    }
	else if (!strcmp(av[i],"-o")) /* Output file */
	    if (++i == ac)
		fprintf(stderr,"Missing output file name.\n");
	    else {
		outputFileName = av[i];
	    }
	else if (!strcmp(av[i],"-f")) /* Arguments */
	    if (++i == ac)
		fprintf(stderr,"Missing firstTimeTag");
	    else firstTimeTag = atof(av[i]);
	else if (!strcmp(av[i],"-l"))
	    if (++i == ac)
		fprintf(stderr,"Missing lastTimeTag");
	    else lastTimeTag = atof(av[i]);
	else if (!strcmp(av[i],"-s"))
	    if (++i == ac)
		fprintf(stderr,"Missing timeShift");
	    else timeShift = atof(av[i]);
	else fprintf(stderr,"Unknown option :%s\n",av[i]);
    }
    if (inputFileName) /* Pick up trailing input file. */
	[aScore readScorefile:inputFileName firstTimeTag:firstTimeTag
       lastTimeTag:lastTimeTag timeShift:timeShift];
    if (!outputFileName) /* Default output file name. */
	outputFileName = "mix.score";
    [aScore writeScorefile:outputFileName];
    exit(0);
}

