/* $Id$ */
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* updated for OpenStep by Leigh Smith 1999/8/31 */
#import <Foundation/Foundation.h>
#import <MusicKit/MusicKit.h>

#import <string.h>
#import <stdlib.h>
#import <pwd.h>
#import <sys/types.h>
#import <sys/file.h>

static char *getHomeDirectory()
{
    static char *homeDirectory;
    struct passwd  *pw;
    if (!homeDirectory) {
	pw = getpwuid(getuid());
	if (pw && (pw->pw_dir) && (*pw->pw_dir)) {
	    homeDirectory = (char *)malloc(strlen(pw->pw_dir)+1);
	    strcpy(homeDirectory,pw->pw_dir);
	}
    }
    return homeDirectory;
}

#define PERMS 0660 /* RW for owner and group. */ 
#define HOME_SCORE_DIR "/Library/Music/Scores/"
#define LOCAL_SCORE_DIR "/Local/Library/Music/Scores/"
#define SYSTEM_SCORE_DIR "/System/Library/Music/Scores/"

#import <stdio.h>


static int tryIt(char *filename,char *extension,char *name,int addExt,
                 char *dir1,char *dir2)
{
    int fd;
    if (dir1) {
        strcpy(filename,dir1);
        if (dir2)
          strcat(filename,dir2);
        strcat(filename,name);
    }
    else strcpy(filename,name);
    if (addExt)
      strcat(filename,extension);
    fd = open(filename,O_RDONLY,PERMS);
    if (fd == -1) {
        if (addExt) {
            /* Try it without extension */
            filename[strlen(filename)-strlen(extension)] = '\0';
            fd = open(filename,O_RDONLY,PERMS);
        }
    }
    return fd;
}

static BOOL extensionPresent(char *filename,char *extension)
{
    char *ext = strrchr(filename,'.');
    if (!ext)
      return NO;
    return (strcmp(ext,extension) == 0);
}

static int findFile(char *name)
{
    int fd;
    char filename[1024], *p;
    int addScoreExt,addMidiExt, addPlayscoreExt;
    if (!name) {
	fprintf(stderr,"No file name specified.\n");
	exit(1);
    }
    addScoreExt = (!extensionPresent(name,".score"));
    addPlayscoreExt = (!extensionPresent(name,".playscore"));
    addMidiExt = (!extensionPresent(name,".midi"));
    fd = tryIt(filename,".score",name,addScoreExt,NULL,NULL);
    if (fd != -1) 
      return fd;
    fd = tryIt(filename,".playscore",name,addPlayscoreExt,NULL,NULL);
    if (fd != -1) 
      return fd;
    fd = tryIt(filename,".midi",name,addMidiExt,NULL,NULL);
    if (fd != -1) 
      return fd;
    if (name[0] != '/') { /* There's hope */
	if (p = getHomeDirectory()) {
	    fd = tryIt(filename,".score",name,addScoreExt,p,HOME_SCORE_DIR);
	    if (fd != -1) 
	      return fd;
	    fd = tryIt(filename,".playscore",name,addPlayscoreExt,p,HOME_SCORE_DIR);
	    if (fd != -1) 
	      return fd;
	    fd = tryIt(filename,".midi",name,addMidiExt,p,HOME_SCORE_DIR);
	    if (fd != -1) 
	      return fd;
	}
	
	fd = tryIt(filename,".score",name,addScoreExt,LOCAL_SCORE_DIR,NULL);
	if (fd != -1) 
	  return fd;
	fd = tryIt(filename,".playscore",name,addPlayscoreExt,LOCAL_SCORE_DIR,NULL);
	if (fd != -1) 
	  return fd;
	fd = tryIt(filename,".midi",name,addMidiExt,LOCAL_SCORE_DIR,NULL);
	if (fd != -1) 
	  return fd;
	
	fd = tryIt(filename,".score",name,addScoreExt,SYSTEM_SCORE_DIR,NULL);
	if (fd != -1) 
	  return fd;
	fd = tryIt(filename,".playscore",name,addPlayscoreExt,SYSTEM_SCORE_DIR,NULL);
	if (fd != -1) 
	  return fd;
	fd = tryIt(filename,".midi",name,addMidiExt,SYSTEM_SCORE_DIR,NULL);
	if (fd != -1) 
	  return fd;
    }
    if (fd == -1) {
	fprintf(stderr,"Can't find %s.\n",name);
	exit(1);
    }
    return fd;
}

const char * const help = "\n"
"usage : convertscore [-mpst] [-o file] file\n"
"        [-m] write midifile (.midi) format \n"
"        [-p] write optimized scorefile (.playscore) format \n"
"        [-s] write scorefile (.score) format \n"
"        [-t] convert tempo changes to time tags, defaulting tempo to 60BPM\n"
"        [-o <output file>] \n"
"\n";


enum fileFormat {none,midi,score,playscore};

static char *formatStr(int aFormat)
{
    return (aFormat == score) ? ".score" : (aFormat == playscore) ? ".playscore" : ".midi";
}

enum fileFormat determineInputFormat(NSString *inputFile)
{
    id fh;
    int fd;
    int firstWord;
    NSData *firstWordData;

    fd = findFile([inputFile cString]);
    fh = [[NSFileHandle alloc] initWithFileDescriptor: fd];
    firstWordData = [fh readDataOfLength: 4];
    firstWord = NSSwapBigIntToHost(*((int *)[firstWordData bytes]));
    #   define MIDIMAGIC 1297377380
    if (firstWord == MK_SCOREMAGIC)
        return playscore;
    else if (firstWord == MIDIMAGIC)
        return midi;
    else
        return score;
}

int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *inputFile;
    NSString *outputFile = nil;
    int errorFlag = 0;
    enum fileFormat outFormat = none,inFormat = none;
    int i;
    MKScore *aScore;
    int absoluteTempo = NO;	/* by default, we use the tempo from the */
    				/* midifile & convert the time-tags without */
				/* considering the tempo. */
    if (argc == 1) {
	fprintf(stderr,help);
	exit(1);
    }
    for (i=1; i<(argc-1); i++) {
	if ((strcmp(argv[i],"-m") == 0))  /* midi */
	  outFormat = midi;
	else if ((strcmp(argv[i],"-p") == 0)) /* optimized scorefile */
	  outFormat = playscore;
	else if (strcmp(argv[i],"-s") == 0) 
	  outFormat = score;
	else if (strcmp(argv[i],"-t") == 0)
	  absoluteTempo = YES;
	else if (strcmp(argv[i],"-o") == 0)  {
	    i++;
	    if (i < argc) 
	      outputFile = [NSString stringWithCString: argv[i]];
	}
    }
    inputFile = [NSString stringWithCString: argv[argc-1]];
    if (!outputFile)
        outputFile = [inputFile stringByDeletingPathExtension]; /* Extension added by write routine */

    inFormat = determineInputFormat(inputFile);
    [MKScore setMidifilesEvaluateTempo: absoluteTempo];
    aScore = [MKScore new];

    if (outFormat == none)
        outFormat = (inFormat == playscore) ? score : playscore;
    fprintf(stderr,"Converting from %s to %s format.\n",
	    formatStr(inFormat),
	    formatStr(outFormat));
    switch (inFormat) {
      case score:
      case playscore:
          if (![aScore readScorefile: inputFile])  {
               fprintf(stderr,"Fix scorefile errors and try again.\n");
               exit(1);
          }
          break;
      case midi: {
          MKNote *aNoteInfo = [[MKNote alloc] init];
          NSArray *parts;
          if (![aScore readMidifile: inputFile])  {
              fprintf(stderr,"This doesn't look like a midi file.\n");
              exit(1);
          }
          [aNoteInfo setPar: MK_synthPatch toString: @"midi0"];
          printf("%d parts\n", [aScore partCount]);
          parts = [aScore parts];
          [parts makeObjectsPerformSelector: @selector(setInfoNote:) withObject: aNoteInfo];
        }
        break;
      case none:
        fprintf(stderr, "Internal error, no inputFormat\n");
        exit(1);
    }
    switch (outFormat) {
      case score:
	if (![aScore writeScorefile: outputFile])  
	  errorFlag = 1;
	break;
      case playscore:
	if (![aScore writeOptimizedScorefile: outputFile])  
	  errorFlag = 1;
	break;
      case midi:
	if (![aScore writeMidifile: outputFile])  
	  errorFlag = 1;
	break;
      case none:
        fprintf(stderr, "Internal error, no inputFormat\n");
        exit(1);
    }
    if (errorFlag) {
	fprintf(stderr,"Can't write %s.\n", [outputFile cString]);
	exit(1);
    }

   [pool release];
   exit(0);       // insure the process exit status is 0
   return 0;      // ...and make main fit the ANSI spec.
}
