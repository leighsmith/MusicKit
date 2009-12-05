/* dspmsg.c - regenerate $(LIBDSP) header files from DSP system assembly. */

#include <dsp/dsp.h>
extern int _DSPTrace,_DSPVerbose;
extern int _DSPMakeIncludeFiles();

#define USAGE "dspmsg [] "

void main(argc,argv) 
    int argc; char *argv[]; 
{
    int ec;
    DSPLoadSpec *dsp;
    char *slfn;

    while (--argc && **(++argv)=='-') {
	switch (*(++(argv[0]))) {
	case 'V':
	case 'v':
	    _DSPVerbose = !_DSPVerbose;
	    break;
	case 'H':
	case 'h':
	case '?':
	    printf("\n\tUsage: %s\n\n",USAGE);
	    break;
	default:
	    printf("Unknown switch -%s\n",*argv);
	    exit(1);
	}
    }

    if (argc>1)
      fprintf(stderr,"\n\tUsage: %s\n\n",USAGE);

    if (argc>0)
      slfn = argv[0];
    else
      slfn = DSPGetSystemBinaryFile();

    if (_DSPVerbose)
      fprintf(stderr,
	      " dspmsg: regenerating DSP include files from %s\n",
	      slfn);

    if (ec=DSPReadFile(&dsp,slfn))
      fprintf(stderr,"dspimg: *** Could not find file %s.\n",slfn);
    else
      ec=_DSPMakeIncludeFiles(dsp);

    exit(ec?1:0);
}

