/* dspimg.c - Read a DSP .lod or .lnk file and write a .img file.

   Link against libdsp.a

Modification history
	03/24/88/jos - file created
	06/27/88/jos - moved from dsp/src/bin to dsp/tools so it can 
		       build without libdsp. Removed -s option.
	08/25/90/jos - dspimg <file> did not work! (2nd filename req'd)

*/

#include <dsp/dsp.h>

extern char *_DSPGetTail();
extern char *_DSPRemoveTail();

#define USAGE "dspimg infile outfile"

void main(argc,argv) 
    int argc; char *argv[]; 
{
    DSPLoadSpec *dsp;
    char *infile,*outfile;
    int ec;

    if(argc < 1){
	printf("\nUsage:\t%s\n\n",USAGE);
	exit(1);
    }

    infile = *(++argv);

    if (strcmp(_DSPGetTail(infile),"")==0)
      infile = DSPCat(infile,".lod");
    
    if(argc < 3)
      outfile = DSPCat(_DSPRemoveTail(infile),".dsp");
    else
      outfile = *(++argv);
    if (!(ec=DSPReadFile(&dsp,infile)))
      ec=DSPLoadSpecWriteFile(dsp,outfile);
    if (!ec) {
	printf("Done.\n");
	exit(0);
    } else {
	printf("*** File %s not translated ***\n",infile);
	exit(1);
    }
    exit(0);
}

