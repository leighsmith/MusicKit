/*
 * scorefile2stella reads a MusicKit scorefile and writes a Stella archive file,
 * which is actually just a lisp program. scorefile2stella is an OpenStep version of
 * mk2stella, co-opted from the CommonMusic project and is adapted from the
 * scorefile-to-lisp program written by David Jaffe at CCRMA.
 *
 * Converted to OpenStep and the OpenStep MusicKit
 * by Leigh Smith <leigh@tomandandy.com> 1999-07-21
 */

#import <Foundation/Foundation.h>
#import <MusicKit/MusicKit.h>

/* flags for writeParameters hackery */

#define writeParC		0
#define writeParLisp		1
#define writeParFreqName	2
#define writeParPreserveCase	4
#define writeParInString        8

static void writeScore(MKScore *aScore, const char *fil);
static void writeHeader(MKScore *aScore, const char *fil);
static void EnvelopesAndWaveTables(MKScore *aScore, NSMutableArray *aList);
static void writeParts(MKScore *aScore);
static void writeNotes(MKPart *aPart, unsigned modes);
static void writeParameters(MKNote *aNote, unsigned modes);
static NSString *genName(id obj, NSString *rootName);

static FILE *fp;

int main (int ac, const char *av[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    MKScore *aScore = [[MKScore alloc] init];

    if (ac != 3) {
        fprintf(stderr, "Usage:%s infile outfile\n", av[0]);
	fprintf(stderr, "Converts MusicKit scorefiles to Common Music stella Lisp files\n");
	exit(1);
    }
    if ([aScore readScorefile: [NSString stringWithCString: av[1]]] == nil) {
	fprintf(stderr,"%s: Problem reading file %s.\n", av[0], av[1]);
	exit(1);
    }
    fp = fopen(av[2],"w");
    if (fp == NULL) {
	fprintf(stderr,"%s: Problem opening output file.\n", av[0]);
	exit(1);
    }
    MKWritePitchNames(YES);
    fprintf(fp,";;; written by %s from %s\n",av[0], av[1]);
    writeScore(aScore, av[1]);
    fclose(fp);
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}

static void indent(int n)
{
	int i;
	fprintf(fp,"\n");
	for (i=0;i<n;i++) fprintf(fp," ");	  
}

static void writeScore(MKScore *aScore, const char *fil)
{
	fprintf(fp,"(in-package :stella)");
	indent(0);
	fprintf(fp,"(in-syntax :music-kit t)");
	indent(0);
        /* collect envelopes etc into a header string for score */
	writeHeader(aScore, fil);
	indent(0);
	fprintf(fp,"((lambda (score)" );

	/* print MKPart definitions */
	writeParts(aScore);
	indent(3);
	fprintf(fp,"score)");  /* end lambda */
	indent(1);
	fprintf(fp,"(make-object 'merge :id '%s", [genName(aScore, @"score-%d") cString]);
	fprintf(fp,"))\n"); /* end make-object, lambda form */
}

static void writeHeader(MKScore *aScore, const char *fil)
{
	NSMutableArray *aHeader = [[NSMutableArray alloc] init];
	MKNote  *info = [aScore infoNote];
	int i, envCount;
	NSString *name;
	id obj;
        NSMutableData *envelopeData = [[NSMutableData alloc] init];
	NSFileHandle *fh;

        fprintf(fp, "(open-event-stream \"%s\" :default ", fil);
	EnvelopesAndWaveTables(aScore,aHeader);
	envCount = [aHeader count];
	/* don't do anything if there are no header statements. */
	if ((envCount == 0) && !info)
	{
		fprintf(fp,"\"\")\n");
		return;
	}
	fprintf(fp," :header \"\n");
        if (info)
	{
		fprintf(fp,"info ");
		writeParameters(info,writeParC | writeParInString);
		fprintf(fp,";\n");
	}	
	for (i=0; i<envCount; i++)
	{
		obj = [aHeader objectAtIndex:i];
                name = MKGetObjectName(obj);
		if (name == nil)
		  name = genName(obj, @"");
		if ([obj class] == [MKEnvelope class])
		      fprintf(fp,"envelope %s = [", [name cString]);
		else 
		      fprintf(fp,"waveTable %s = [", [name cString]);
                [obj writeScorefileStream: envelopeData];
                fflush(fp); // put something in the file so the file handle can append to it.
		// fileno() may not be as portable as we'd like
		fh = [[NSFileHandle alloc] initWithFileDescriptor: fileno(fp)];
                [fh writeData: envelopeData];
		fprintf(fp,"];\n");
	}
	fprintf(fp,"\")\n"); /* close open-stream string */
}

static void writeParts(MKScore *aScore)
    /* Write MKPart declarations and "part info" */
{
	NSArray *parts = [aScore parts];
	int i, partCount;
	if (!parts) return;
	indent(3);
	fprintf(fp,"(add-objects");
	indent(5);
	fprintf(fp,"(list");
	partCount = [parts count];
	for (i=0; i<partCount; i++)
	{
		MKPart *aPart;
		MKNote *info;
		const char *name;
		NSString *class;
		BOOL freqNames = NO;
		int par, mode;
		
		aPart = (MKPart *)[parts objectAtIndex:i];
		name = [MKGetObjectName(aPart) cString];
		info = [aPart infoNote];
		/* if user specified freqNames:YES, print freqnames */
		par=[MKNote parName: @"freqNames"];
		if ([info isParPresent:par] == YES)
			mode=writeParLisp | writeParFreqName;
		else
			mode=writeParLisp;

		class = [info parAsString:MK_synthPatch];
		indent(7);
		fprintf(fp,"((lambda (thread &aux part)");
		indent(10);
	        fprintf(fp,"(setq part (partInfo \"%s\"", name);
		writeParameters(info, (writeParLisp | writeParPreserveCase));
		fprintf(fp,"))"); /* close partInfo, setq */

		writeNotes(aPart, mode); 
		indent(10);
		fprintf(fp,"thread)"); /* close lambda */
		indent(8);
                fprintf(fp,"(make-object '(thread %s) :id '%s))", name, name);
	}
	fprintf(fp,")");	/* end list */
	indent(5);
	fprintf(fp,"score)");	/* end add-objects */
}

static void writeNotes(MKPart *aPart, unsigned modes)
{
	MKNote *info = [aPart infoNote];
	NSArray *notes = [aPart notes];
	NSString *name;
	NSString *class;
	NSString *newclass;
	int i, noteCount;
	static char *noteTypeNames[] = {":noteDur",":noteOn",":noteOff",":noteUpdate",":mute"};
	MKNote *aNote, *nNote;
	MKNoteType nt;
	double r;

	// test we actually got valid notes 
	if (notes == nil) return;
	if ((noteCount=[notes count])==0) return;
        name = MKGetObjectName(aPart);

	class = @"mkmidi";	// Sequence defaults synthPatches to MIDI
	// test we actually got valid info
	if(info != nil) {
	    if([info isParPresent:MK_synthPatch]) {
		NSRange midiCompare = {0, 4};
		newclass = [info parAsString: MK_synthPatch];
		/* change MIDI class to a MusicKit MIDI class */		
                if([newclass compare: @"midi" options: NSLiteralSearch range: midiCompare] == NSOrderedSame) {
		    class = newclass;
		}
	    }
	}
	indent(10);
        fprintf(fp,"(add-objects");
	indent(12);
	fprintf(fp,"(list");
	for (i=0;i<noteCount;i++)
	{
		aNote=(MKNote *)[notes objectAtIndex:i]; 
		if (i<(noteCount-1))
		{
			nNote=(MKNote *)[notes objectAtIndex:i+1];
			r=[nNote timeTag] - [aNote timeTag];
		}
		else
			r=0.0;
		nt = [aNote noteType];
		indent(14);
		fprintf(fp,"(make-object '%s :part part", [class cString]);
		fprintf(fp," :rhythm %f", r);
		if ([aNote noteTag] != MAXINT)
		  fprintf(fp," :tag %4d", [aNote noteTag]);
		if (nt == MK_noteDur)
			fprintf(fp," :duration %f", [aNote dur]);
		else
			fprintf(fp," :type '%s", noteTypeNames[nt-MK_noteDur]);
		writeParameters(aNote, modes);
		fprintf(fp,")");	/* close make-object */
	}
        fprintf(fp,")");		/* close list */
	indent(12);
	fprintf(fp,"thread)");		/* close add-objects */
}

static void writeParameters(MKNote *aNote, unsigned modes)
{
	void *aState;
	int par;
	NSString *name;
	char *format;

	if ((modes & writeParLisp)==writeParLisp) 
		if ((modes & writeParPreserveCase)==writeParPreserveCase)
			format=" :|%s|";
		else
			format=" :%s";
	else 
		format=" %s:";
	aState = MKInitParameterIteration(aNote);
	while ((par = MKNextParameter(aNote,aState)) != MK_noPar) 
	{
		name = [MKNote nameOfPar:par];
		if ([name length] == 0)
			continue;	/* skip private pars */
		fprintf(fp,format, [name cString]);

		if (((modes & writeParFreqName) == writeParFreqName) &&
		    (([[MKNote nameOfPar:par] compare: @"freq"] == NSOrderedSame) ||
		     ([[MKNote nameOfPar:par] compare: @"freq0"] == NSOrderedSame)))
		{
			int keyNum = MKFreqToKeyNum([aNote parAsDouble:par], NULL,1.0);
			char *pitchNames[128] = {
 "c00","cs00","d00","ds00","e00","f00","fs00","g00","gs00","a00","as00","b00",
 "c0","cs0","d0","ds0","e0","f0","fs0","g0","gs0","a0","as0","b0",
 "c1","cs1","d1","ds1","e1","f1","fs1","g1","gs1","a1","as1","b1",
 "c2","cs2","d2","ds2","e2","f2","fs2","g2","gs2","a2","as2","b2",
 "c3","cs3","d3","ds3","e3","f3","fs3","g3","gs3","a3","as3","b3",
 "c4","cs4","d4","ds4","e4","f4","fs4","g4","gs4","a4","as4","b4",
 "c5","cs5","d5","ds5","e5","f5","fs5","g5","gs5","a5","as5","b5",
 "c6","cs6","d6","ds6","e6","f6","fs6","g6","gs6","a6","as6","b6",
 "c7","cs7","d7","ds7","e7","f7","fs7","g7","gs7","a7","as7","b7",
 "c8","cs8","d8","ds8","e8","f8","fs8","g8","gs8","a8","as8","b8",
 "c9","cs9","d9","ds9","e9","f9","fs9","g9"};
			fprintf(fp," '%s",pitchNames[keyNum]);
		} 
		else
		    switch ([aNote parType:par]) {
	  		case MK_envelope:
	  		case MK_waveTable:
	    			fprintf(fp," \"%s\"", [MKGetObjectName([aNote parAsObject:par]) cString]);
	    			break;
	  		case MK_double:
	    			fprintf(fp," %f", [aNote parAsDouble:par]);
	    			break;
	  		case MK_int:
	    			fprintf(fp," %d", [aNote parAsInt:par]);
	    			break;
	  		case MK_string:
				fprintf(fp, (modes & writeParInString) == writeParInString ? " %s" : " \"%s\"",
					 [[aNote parAsStringNoCopy:par] cString]);
				break;
			default:
				break;
		}
	}
}

static NSString *genName(id obj, NSString *rootName)
{
	NSString *name;
//	int i;

	if ([rootName length] == 0)
	     rootName = @"obj%d";
	name = [NSString stringWithFormat: rootName, (int) obj]; // takes the address of the object
/*
// For some reason MKGetNamedObject has been removed from the MusicKit. The obj+i implies an C array of objects
	i = 0;
	while (MKGetNamedObject(name)) 
	{
		i++;
		// [name release];
		name = [NSString stringWithFormat: rootName, obj+i];
	}
*/
	MKNameObject(name,obj); /* Copies string */
	return name;
}

static void EnvelopesAndWaveTables(MKScore *aScore, NSMutableArray *allEnvsAndWaves)
    /* Dig through notes and find all envelopes and wave tables.
       Give them names, if necessary, and put them in the header. */
{
    NSArray *parts = [aScore parts];
    MKPart *aPart;
    NSArray *notes;
    MKNote *aNote;
    id obj;
    int i,partCount,j,noteCount;
    int par;
    void *aState;

    if (!parts)
      return;
    partCount = [parts count];
    for (i=0; i<partCount; i++) {
	aPart = (MKPart *)[parts objectAtIndex:i];
	notes = [aPart notes];
	if (notes) {
	    noteCount = [notes count];
	    for (j=0; j<noteCount; j++) {
		aNote = [notes objectAtIndex:j];
		aState = MKInitParameterIteration(aNote);
		while ((par = MKNextParameter(aNote,aState)) != MK_noPar) {
		    obj = [aNote parAsObject:par];
		    if (obj != nil) {
			if ([allEnvsAndWaves indexOfObject: obj] == NSNotFound) {
			    [allEnvsAndWaves addObject:obj];
			}
		    }
		}
	    }
	}
    }
}



