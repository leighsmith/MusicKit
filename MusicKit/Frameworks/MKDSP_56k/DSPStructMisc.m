/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*** UTILITY FUNCTIONS FOR DSP DATA STRUCTURES (MUNG/INIT/PRINT) ***/

/*
 * History
 * 09/26/88/jos - added check on write for disk full
 * 02/10/89/jos - incorporated DSPLoadSpecReadFile.c and DSPLoadSpecWriteFile.c
 * 02/13/89/jos - removed call to _DSPContiguousFree(sym) in DSPSymbolFree
 * 02/14/89/jos - removed excess calls to DSPDataRecordFree in DSPSectionFree
 * 02/17/89/jos - DSPDataRecordMerge: fixed bug preventing l: dr merge
 * 05/24/89/mtm - added fclose
 * 04/23/90/jos - flushed unsupported entry points.
 * 04/30/90/jos - Removed "r" prefix from rData, rWordCount, rRepeatCount
 * 06/29/94/daj - Added swap support
 * 07/05/94/daj - Changed to make all versions write the same data.
 */

#ifdef SHLIB
#include "shlib.h"
#endif

// LMS: SB reports OpenStep 4.2 has problems compiling with Foundation.h
#if NeXT
#import <objc/objc.h> /*sb*/
#import <Foundation/NSByteOrder.h> /*sb*/
#else
#import <Foundation/Foundation.h>
#endif

#if WIN32
#import <winnt-pdo.h>
#endif

#include "_dsp.h"
//#include <sys/file.h>   /* DSPLoadSpecReadFile(), DSPLoadSpecWriteFile() */  // LMS do we really need this?

#define ZERO_STRUCT1 0 
#define ZERO_STRUCT2 0 
#define ZERO_STRUCT3 0 
/* In order to make the Pentium write identical files as the 68k, you
 * need to zero the structs' pointers.  However, I was never able to get
 * the zero'ed structs to make correct .dsp files.  Part of the problem
 * is the way that pointers are used as booleans to determine whether or
 * not another struct is in the file.  I tried replacing the NULLs with
 * (void *)4 but that didn't work either.  So all 3 of these ZERO_STRUCT*
 * macros should be 0 if you want valid .dsp files.
 */

// extern int unlink(); // LMS is this neccessary?

static int magicNumber = 0x11111111;  /* Increase this when format changes */

/************************* INITIALIZATION FUNCTIONS **************************/

int _DSPCheckingFWrite(
    int *ptr,
    int size,
    int nitems,
    FILE *stream)
{
    int nw;
    nw = fwrite(ptr, size, nitems, stream);
    if (nw == nitems)
      return(0);
    else
      return(_DSPError(DSP_EUNIX,"!!! File system is FULL !!!"));
}

/* These are swap-safe functions for writing files */

static int writeInt(
    int *ints,
    int nitems,
    FILE *stream)
{
#ifdef __LITTLE_ENDIAN__    

    int *arr = alloca(nitems * sizeof(int));
    int *arrPtr = arr;
    int *arrEnd = arr+nitems;
    while (arrPtr < arrEnd) 
      *arrPtr++ = NSSwapInt(*ints++);
    return _DSPCheckingFWrite(arr,sizeof(int),nitems,stream);
#else
    return _DSPCheckingFWrite(ints,sizeof(int),nitems,stream);
#endif
}

static int writeFloat(
    float *floats,
    int nitems,
    FILE *stream)
{
#ifdef __LITTLE_ENDIAN__    

    NSSwappedFloat *arr = alloca(nitems * sizeof(NSSwappedFloat));
    NSSwappedFloat *arrPtr = arr;
    NSSwappedFloat *arrEnd = arr+nitems;
    while (arrPtr < arrEnd) 
      *arrPtr++ = NSSwapHostFloatToBig(*floats++);
    if (fwrite(arr, sizeof(float), nitems, stream) != nitems)
      return(_DSPError(DSP_EUNIX,"!!! File system is FULL !!!"));
#else
    if (fwrite(floats, sizeof(float), nitems, stream) != nitems)
      return(_DSPError(DSP_EUNIX,"!!! File system is FULL !!!"));
#endif
    return 0;
}

static int readInt(
    int *ints,
    int nitems,
    FILE *stream)
{
#ifdef __LITTLE_ENDIAN__    

    int *arrEnd = ints + nitems;
#endif
    fread(ints,sizeof(int),nitems,stream);
#ifdef __LITTLE_ENDIAN__
    while (ints < arrEnd) {
      *ints = NSSwapInt(*ints);
      ints++;
    }
#endif
    return 0;
}


void DSPDataRecordInit(DSPDataRecord *dr)
{
    dr->section = NULL;
    dr->locationCounter = DSP_LC_N;
    dr->loadAddress = 0;
    dr->repeatCount = 0;
    dr->wordCount = 0;
    dr->data = NULL;
    dr->next = NULL;
    dr->prev = NULL;
}


void DSPSectionInit(DSPSection *sec) 

{
    int i;
    sec->name = NULL;
    sec->type = NULL;
    sec->number = DSP_UNKNOWN;
    for (i=0;i<DSP_LC_NUM;i++) {
        sec->loadAddress[i] = 0;
        sec->data[i] = NULL;
        sec->dataEnd[i] = NULL;
        sec->symCount[i] = 0;
        sec->symAlloc[i] = 2048;
        DSP_MALLOC(sec->symbols[i],DSPSymbol,sec->symAlloc[i]);
    }
    for (i=0;i<DSP_LC_NUM_P;i++) {
        sec->fixupCount[i] = 0;
        sec->fixupAlloc[i] = 128;
        DSP_MALLOC(sec->fixups[i],DSPFixup,sec->fixupAlloc[i]);
    }
    sec->xrefCount = 0;
    sec->xrefAlloc = 20;
    DSP_MALLOC(sec->xrefs,char*,sec->xrefAlloc);
}


void DSPLoadSpecInit(DSPLoadSpec *dsp)
{
    int i;
    dsp->module = NULL;
    dsp->type = NULL;
    dsp->version = 0;
    dsp->revision = 0;
    dsp->errorCount = 0;
    dsp->startAddress = 64;
    dsp->comments = NULL;
    dsp->description = NULL;
    dsp->globalSection = NULL;
    dsp->systemSection = NULL;
    dsp->userSection = NULL;
    for (i=0;i<(int)DSP_NSectionTypes;i++) 
      dsp->indexToSection[i] = NULL;
}

void DSPMemMapInit(_DSPMemMap *mm)
/* initialize record fields to NULL */
{
    int i;
    for (i=0;i<DSP_LC_NUM;i++) {
        mm->defaultOffsets[i] = 0;
        mm->userOffsets[i] = 0;
        mm->nOtherOffsets[i] = 0;
        mm->otherOffsets[i] = NULL;
    }
}

/**************************** PRINTING FUNCTIONS *****************************/

void DSPSymbolPrint(DSPSymbol sym)
{
    char *spc;
    char symval[100];

    if (sym.type[2]=='F')
      sprintf(symval,"%f",sym.value.f);
    else
      sprintf(symval,"$%X",(unsigned int)sym.value.i);
    spc = (char *)DSPLCNames[(int)sym.locationCounter];
    printf("\t\t%s:%-22s\t(%s)\t= %s\n",
           spc,sym.name, sym.type, symval);
}


void DSPDataRecordPrint(DSPDataRecord *dr)
{
    int k,wcm4;
    printf(
 "\n\t%s DATA RECORD: %d*%d = $%X * $%X words at %s:%d:%d = $%X..$%X\n",
           DSPLCNames[(int)dr->locationCounter], 
           dr->wordCount,
           dr->repeatCount, 
           (unsigned int)dr->wordCount,
           (unsigned int)dr->repeatCount, 
           DSPLCNames[(int)dr->locationCounter], 
           dr->loadAddress,
           dr->loadAddress + dr->wordCount * dr->repeatCount - 1,
           (unsigned int)dr->loadAddress,
           (unsigned int)dr->loadAddress + dr->wordCount * dr->repeatCount-1);
    wcm4 = dr->wordCount % 4;
    for (k=0;k<dr->wordCount-wcm4;k+=4)
      printf("\t\t$%-9X \t $%-9X \t $%-9X \t $%-9X\n",
             (unsigned int)dr->data[k],
             (unsigned int)dr->data[k+1],
             (unsigned int)dr->data[k+2],
             (unsigned int)dr->data[k+3]);
    printf("\t\t");
    for (k=dr->wordCount-wcm4;k<dr->wordCount;k++)
      printf("$%-9X \t ",(unsigned int)dr->data[k]);
    printf("\n");
}


void DSPSectionPrint(DSPSection *section)
{
    int i,j,k,symcount;
    printf("\nSection %s\n",section->name);
    printf("    Type   = %s\n",*section->type=='R'?"Relative":"Absolute");
    printf("    Number = %d\n",section->number);
    printf("\n");
    for (j=0;j<DSP_LC_NUM;j++) {
        DSPDataRecord *dr;
        symcount = section->symCount[j];
        printf("    %-2s symbol count = %d",
               DSPLCNames[j],symcount);
        if (j!=0)
          printf(" ... load address = $%X\n",
                 (unsigned int)section->loadAddress[j]);
        else
          printf("\n");
        for (k=0;k<symcount;k++) 
          DSPSymbolPrint(section->symbols[j][k]);
        for (dr=section->data[j];dr!=NULL;dr=dr->next) 
          DSPDataRecordPrint(dr);
    }
    for (i=0;i<DSP_LC_NUM_P;i++) {
        if (section->fixupCount[i]>0)
          printf("\nRelocatable symbols encountered for space %s:\n",
                 DSPLCNames[i+(int)DSP_LC_P]);
        for (j=0;j<section->fixupCount[i];j++)
          printf("\t%s[%d] = loadAddress(%s)+%d  (%s/%s:%s)\n",
                 DSPLCNames[i+(int)DSP_LC_P],
                 section->fixups[i][j].refOffset,
                 DSPLCNames[(int)section->fixups[i][j].locationCounter],
                 section->fixups[i][j].relAddress,
                 section->name,
                 DSPLCNames[(int)section->fixups[i][j].locationCounter],
                 section->fixups[i][j].name);
        if (0)
          printf("\tAt offset %d, place &%s = %d\n",
                 section->fixups[i][j].refOffset,
                 section->fixups[i][j].name,
                 section->fixups[i][j].relAddress);
    }
    if (section->xrefCount>0)
      printf("\nExternal symbol references encountered in section %s:\n",
             section->name);
    for (j=0;j<section->xrefCount;j++)
      printf("\t%s\n",section->xrefs[j]);
}


void DSPLoadSpecPrint(DSPLoadSpec *dsp)
{
    int i;
    DSPSection *section;
    printf(
"\n======================= DSPLoadSpec struct printout ====================\n\n");
    printf("Module %s:\n",dsp->module);
    printf("Type %s:\n",(*dsp->type=='A'?"A[bsolute]":"R[elative]"));
    printf("\tVersion,Rev   = %d,%d\n",dsp->version,dsp->revision);
    printf("\tError count   = %d\n",dsp->errorCount);
    printf("\tStart Address = $%X\n",(unsigned int)dsp->startAddress);
    printf("\n");
    if (dsp->description)
      printf("Description:\n%s\n",dsp->description);
    if (dsp->comments)
      printf("Comments:\n%s\n",dsp->comments);
    for (i=0;i<DSP_N_SECTIONS;i++) {
        section = dsp->indexToSection[i];
        if (section==NULL)
          printf("Section %s not present.\n",DSPSectionNames[i]);
        else
          DSPSectionPrint(section);
    }
}


void DSPMemMapPrint(_DSPMemMap *mm)
{
    int i;
    printf(
"\n======================= _DSPMemMap struct printout ====================\n\n");
    for (i=0;i<DSP_LC_NUM;i++) {
        printf("\tdefaultOffsets[%-2s] = 0x%-6X",
               DSPLCNames[i],(unsigned int)mm->defaultOffsets[i]);
        printf("\tuserOffsets[%-2s] = 0x%-6X\n",
               DSPLCNames[i],(unsigned int)mm->userOffsets[i]);
        if (mm->nOtherOffsets[i]>0) {
            printf("\tnOtherOffsets[%d] = %d\n",i,mm->nOtherOffsets[i]);
            printf("\t\tCannot print (unsupported) otherOffsets\n");
        }
    }
}

/****************************** ARCHIVING FUNCTIONS **************************/

/*** writeDSPx ***/

/* TODO: Add proper error return codes (for disk being full, etc.) */

int _DSPWriteString(char *str, FILE *fp)
{
    int len;
    if (!str) str = "(none)";   /* have to write out something (for reader) */
    len = strlen(str)+1;                /* include terminating NULL */
    DSP_UNTIL_ERROR(writeInt(&len,1,fp));
    DSP_UNTIL_ERROR(_DSPCheckingFWrite((int *)str,len,1,fp));
    return(0);
}

int DSPDataRecordWrite(DSPDataRecord *dr, FILE *fp)
{
    /* Remember all this stuff, then zero it out for write, then restore it */
#if ZERO_STRUCT1
    struct _DSPSection *section = dr->section;
    int *data = dr->data;
    struct _DSPDataRecord *next = dr->next;
    struct _DSPDataRecord *prev = dr->prev; 

    dr->section = NULL;
    dr->data = NULL;
    dr->next = NULL; 
    dr->prev = NULL;
#endif
    DSP_UNTIL_ERROR(writeInt((void *)dr,
                             sizeof(DSPDataRecord)/sizeof(int),fp));
    /* This assumes it's ok to write all fields of _DSPDataRecord as int */
#if ZERO_STRUCT1
    dr->section = section;
    dr->data = data;
    dr->next = next;
    dr->prev = prev;
#endif
    if (dr->wordCount)
      DSP_UNTIL_ERROR(writeInt(dr->data,dr->wordCount,fp));
    if (dr->next)
      return(DSPDataRecordWrite(dr->next,fp));
    return(0);
}

static int isInt(char *type)
     /* Checks DSP symbol type field and looks for I or F character,
        which determines if symbol value is a float or an int. */
{
  return (strchr(type,'I') != 0);
}

int DSPSymbolWrite(DSPSymbol sym, FILE *fp)
{
    /* Remember all this stuff, then zero it out for write, then restore it */
    char *name = sym.name;
    char *type = sym.type;
    sym.name = NULL;
    sym.type = NULL;
    DSP_UNTIL_ERROR(writeInt((int *)&(sym.locationCounter),3,fp));
    /* This strange way of doing things is for backward-compatibility.
       We write the name and type pointers "for nothing" */
    sym.name = name;
    sym.type = type;
    if (isInt(sym.type)) {
      DSP_UNTIL_ERROR(writeInt((int *)&(sym.value.i),1,fp));
    }
    else {
      DSP_UNTIL_ERROR(writeFloat((float *)&(sym.value.f),1,fp));
    }
    DSP_UNTIL_ERROR(_DSPWriteString(sym.name,fp));
    return _DSPWriteString(sym.type,fp);
}


int DSPFixupWrite(DSPFixup fxp, FILE *fp)
{
    /* Remember this,  then zero it out for write, then restore it */
    char *name = fxp.name;
    fxp.name = NULL;
    DSP_UNTIL_ERROR(writeInt((int *)&fxp,sizeof(DSPFixup)/sizeof(int),fp));
    fxp.name = name;
    return(_DSPWriteString(fxp.name,fp));
}


int DSPSectionWrite(DSPSection *sec, FILE *fp)
{
    int i,j,symcount;
    int symalloc[DSP_LC_NUM],fixupalloc[DSP_LC_NUM_P],xrefalloc;

    for (i=0;i<DSP_LC_NUM;i++)
      symalloc[i] = sec->symAlloc[i];
    for (i=0;i<DSP_LC_NUM_P;i++)
      fixupalloc[i] = sec->fixupAlloc[i];
    xrefalloc = sec->xrefAlloc;

    /* squeeze out any extra space allocation */
    for (i=0;i<DSP_LC_NUM;i++)
      sec->symAlloc[i] = sec->symCount[i];
    for (i=0;i<DSP_LC_NUM_P;i++)
      sec->fixupAlloc[i] = sec->fixupCount[i];
    sec->xrefAlloc = sec->xrefCount;

    /* write out DSPSection struct */
    if(!sec) _DSPError(EINVAL,"DSPSectionWrite: can't pass null pointer");
    {
#if ZERO_STRUCT2
        char *name = sec->name;
        char *type = sec->type;
        char **xrefs = sec->xrefs;
        DSPDataRecord *data[DSP_LC_NUM]; 
        DSPDataRecord *dataEnd[DSP_LC_NUM]; 
        struct _DSPSymbol *(symbols[DSP_LC_NUM]); 

        DSPFixup *fixups[DSP_LC_NUM_P]; 

        int i;
        for (i=0; i<DSP_LC_NUM; i++) {
            data[i] = sec->data[i];
            dataEnd[i] = sec->dataEnd[i];
            symbols[i] = sec->symbols[i];
            sec->data[i] = NULL;
            sec->dataEnd[i] = NULL;
            sec->symbols[i] = NULL;
        }
        for (i=0; i<DSP_LC_NUM_P; i++) {
	    fixups[i] = sec->fixups[i];
            sec->fixups[i] = NULL;
	}
        sec->name = NULL;
        sec->type = NULL;
        sec->xrefs = NULL;
#endif
        DSP_UNTIL_ERROR(writeInt((int *)sec,
                                 sizeof(DSPSection)/sizeof(int),fp));
#if ZERO_STRUCT2
        sec->name = name;
        sec->type = type;
        sec->xrefs = xrefs;
        for (i=0; i<DSP_LC_NUM; i++) {
            sec->data[i] = data[i];
            sec->dataEnd[i] = dataEnd[i];
            sec->symbols[i] = symbols[i];
        }
        for (i=0; i<DSP_LC_NUM_P; i++) 
	  sec->fixups[i] = fixups[i];
#endif
    }
    /* restore extra space allocation */
    for (i=0;i<DSP_LC_NUM;i++)
      sec->symAlloc[i] = symalloc[i];
    for (i=0;i<DSP_LC_NUM_P;i++)
      sec->fixupAlloc[i] = fixupalloc[i];
    sec->xrefAlloc = xrefalloc;

    /* write out pointed-to items */
    DSP_UNTIL_ERROR(_DSPWriteString(sec->name,fp));
    DSP_UNTIL_ERROR(_DSPWriteString(sec->type,fp));

    for (i=0;i<DSP_LC_NUM;i++) {
        symcount = sec->symCount[i];
        for (j=0;j<symcount;j++)
          DSP_UNTIL_ERROR(DSPSymbolWrite(sec->symbols[i][j],fp));
        if (sec->data[i])
          DSP_UNTIL_ERROR(DSPDataRecordWrite(sec->data[i],fp));
    }

    for (i=0;i<DSP_LC_NUM_P;i++) {
        for (j=0;j<sec->fixupCount[i];j++)
          DSP_UNTIL_ERROR(DSPFixupWrite(sec->fixups[i][j],fp));
    }

    if (sec->xrefCount>0)
      _DSPError1(DSP_EBADSECTION,
        "External symbol references encountered in section %s",sec->name);

    for (i=0;i<sec->xrefCount;i++)
      DSP_UNTIL_ERROR(_DSPWriteString(sec->xrefs[i],fp));

    return(0);
}


int DSPLoadSpecWrite(DSPLoadSpec *dsp, FILE *fp)
{
    int mag;
    if(!dsp) return(0);
    if(!fp) return(1);
    mag = magicNumber;
    writeInt(&mag,1,fp);
    {
#if ZERO_STRUCT3
        /* Save, null, write, restore */
        char *module = dsp->module;
        char *type = dsp->type;
        char *comments = dsp->comments;
        char *description = dsp->description;
        DSPSection *globalSection = dsp->globalSection;
        DSPSection *systemSection = dsp->systemSection;
        DSPSection *userSection = dsp->userSection;
        DSPSection *indexToSection[DSP_N_SECTIONS];
        int i;
        for (i=0; i<DSP_N_SECTIONS; i++) {
            indexToSection[i] = dsp->indexToSection[i];
            dsp->indexToSection[i] = NULL;
        }
        dsp->module = NULL;
        dsp->type = NULL;
        dsp->comments = NULL;
        dsp->description = NULL;
        dsp->globalSection = NULL;
        dsp->systemSection = NULL;
        dsp->userSection = NULL;
#endif
        writeInt((void *)dsp,sizeof(DSPLoadSpec)/sizeof(int),fp);
#if ZERO_STRUCT3
        for (i=0; i<DSP_N_SECTIONS; i++) 
          dsp->indexToSection[i] = indexToSection[i];
        dsp->module = module;
        dsp->type = type;
        dsp->comments = comments;
        dsp->description = description;
        dsp->globalSection = globalSection;
        dsp->systemSection = systemSection;
        dsp->userSection = userSection;
#endif
    }

    _DSPWriteString(dsp->module,fp);
    _DSPWriteString(dsp->type,fp);
    _DSPWriteString(dsp->comments,fp);
    _DSPWriteString(dsp->description,fp);
    if (dsp->globalSection)
      DSPSectionWrite(dsp->globalSection,fp);
    if (dsp->systemSection)
      DSPSectionWrite(dsp->systemSection,fp);
    if (dsp->userSection)
      DSPSectionWrite(dsp->userSection,fp);
    return(0);
}

static void checkDataRecordSizes(void)
{
  if (sizeof(DSPDataRecord)!=32 || sizeof(DSPLoadSpec)!=56 || 

      sizeof(DSPFixup)!=20 || sizeof(DSPSymbol)!=16 || 

      sizeof(DSPSection)!=372) {
    fprintf(stderr,"Error in struct size assumptions. FATAL ERROR\n");
    exit(1);
  }
}

int DSPLoadSpecWriteFile(
    DSPLoadSpec *dspptr,                /* struct containing  DSP load image */
    char *dspfn)                        /* file name */
{
    FILE *fp;                   /* relocatable link file pointer */
    int ec;

    if (_DSPTrace & DSP_TRACE_DSPLOADSPECWRITE) 
      printf("\nDSPLoadSpecWriteFile\n");

    unlink(dspfn);
    fp = _DSPMyFopen(dspfn,"w");
    if (fp==NULL) 
      return(_DSPError1(DSP_EUNIX,"DSPLoadSpecWriteFile: could not open %s ",dspfn));

    checkDataRecordSizes();
    if (_DSPVerbose)
      printf("\tWriting DSP fast-load file:\t%s\n",dspfn);

    ec = DSPLoadSpecWrite(dspptr,fp);

    fclose(fp);

    if (_DSPVerbose)
      printf("\tFile %s closed.\n",dspfn);

    if (ec) 
      return(_DSPError1(ec,"DSPLoadSpecWriteFile: write failed on %s ",dspfn));

    return(0);
}


/*** readDSPx ***/

char *_DSPContiguousMalloc(unsigned size)
{
    /* FIXME: Cannot implement this until a new bit is placed in each
       struct telling whether it was allocated using malloc (as in 
       _DSPLnkRead() [and anywhere else??] or this routine.
       Each corresponding free routine must test this bit.

       An alternative is to use DSP_CONTIGUOUS_MALLOC in _DSPLnkRead.
       That way the struct is contiguous whether read in from a .lnk/.lod
       file or from a .dsp file.  All frees go away except for DSPLoadSpecFree.
       It frees the single big block allocated for the struct.
    */

    char *ptr;

    ptr = malloc(size);

    if (_DSPTrace & DSP_TRACE_MALLOC)
      fprintf(stderr,
           "_DSPContiguousMalloc:\t Allocating %d bytes at 0x%X\n",
              (int)size, (unsigned int)ptr);

    return (ptr);
}

#define DSP_CONTIGUOUS_MALLOC( VAR, TYPE, NUM ) \
  if(((VAR) = (TYPE *) _DSPContiguousMalloc((unsigned)(NUM)*sizeof(TYPE) )) == NULL) \
  _DSPError(DSP_EUNIX,"malloc: insufficient memory");


int _DSPContiguousFree(char *ptr)
{
    /* FIXME: See _DSPContiguousMalloc() and keep in synch. */

    int nb;

    if (_DSPTrace & DSP_TRACE_MALLOC) {
        nb = malloc_size(ptr);
        fprintf(stderr,
                "_DSPContiguousFree:\t    Freeing %d bytes at 0x%X\n",
                nb, (unsigned int)ptr);
    }
    free (ptr);

    return (0);
}

int _DSPReadString(char **spp, FILE *fp)
{
    int len,lenr;
    DSP_UNTIL_ERROR(readInt(&len,1,fp));
    /* DSP_CONTIGUOUS_MALLOC(*spp,char,len); */
    *spp = _DSPContiguousMalloc(len*sizeof(char));
    if(*spp == NULL)
      _DSPError(DSP_EUNIX,"_DSPReadString: insufficient memory");
    lenr=fread(*spp,sizeof(char),len,fp);
    if (lenr!=len) 
      _DSPError1(DSP_EUNIX,"_DSPReadString: fread returned %s",_DSPCVS(lenr));
    return(lenr==len?0:1);
}


int DSPDataRecordRead(
    DSPDataRecord **drpp,
    FILE *fp,
    DSPSection *sp)     /* pointer to section owning this data record */
{
    int nwords;

    if(!*drpp) 
      _DSPError(EINVAL,"DSPDataRecordRead: can't pass null pointer");

    DSP_CONTIGUOUS_MALLOC(*drpp,DSPDataRecord,1);
    DSP_UNTIL_ERROR(readInt((void *)*drpp,sizeof(DSPDataRecord)/sizeof(int),
                            fp));
    /* This assumes it's ok to read all fields of _DSPDataRecord as int */

    (*drpp)->section = sp;      /* owning section */

    if (nwords=(*drpp)->wordCount) {
        DSP_CONTIGUOUS_MALLOC((*drpp)->data,int,nwords);
        DSP_UNTIL_ERROR(readInt((*drpp)->data,nwords,fp));
    }

    if ((*drpp)->next) {
        DSPDataRecordRead(&((*drpp)->next),fp,sp);
        (*drpp)->next->prev = *drpp;
    }
    return(0);
}


int DSPSymbolRead(DSPSymbol *symp, FILE *fp)
{
    /*     DSP_CONTIGUOUS_MALLOC(symp,DSPSymbol,1); */ 
         /* Allocated by caller */
    readInt((int *)(&symp->locationCounter),3,fp);
    /* This strange way of doing things is for backward-compatibility.
       We read the name and type pointers "for nothing" */
    /* At this point, we don't know if it's a float or an int because
       we haven't read the type yet. So we read it as a generic 4-byte 

       quantity, then swap it correctly later.  

       */ 

    fread((int *)&(symp->value.i),sizeof(int),1,fp);
    _DSPReadString(&(symp->name),fp);
    _DSPReadString(&(symp->type),fp);
#if __LITTLE_ENDIAN__
    if (!isInt(symp->type)) { /* Now do correct swap */
      /* This is my attempt to make the compiler just use the bits I
         give it without any conversion.  I'm not sure it's right. */
      NSSwappedFloat *sfl = (NSSwappedFloat *)((void *)&(symp->value.i));
      symp->value.f = NSSwapBigFloatToHost(*sfl);
    } else {
      symp->value.i = NSSwapBigIntToHost(symp->value.i);
    }
#endif
    return 0;
}


int DSPFixupRead(DSPFixup *fxpp, FILE *fp)
{
    /*     DSP_CONTIGUOUS_MALLOC(fxpp,DSPFixup,1); */
    readInt((void *)fxpp,sizeof(DSPFixup)/sizeof(int),fp);
    _DSPReadString(&((fxpp)->name),fp);
    return(0);
}


int DSPSectionRead(DSPSection **secpp, FILE *fp)
{
    int i,j,symcount,symalloc,fixupalloc,fixupcount;

    if(!*secpp) return(0);

    DSP_CONTIGUOUS_MALLOC(*secpp,DSPSection,1);
    readInt((void *)*secpp,sizeof(DSPSection)/sizeof(int),fp);
    

    _DSPReadString(&((*secpp)->name),fp);
    _DSPReadString(&((*secpp)->type),fp);

    for (i=0;i<DSP_LC_NUM;i++) {
        symcount = (*secpp)->symCount[i];
        symalloc = (*secpp)->symAlloc[i];
        if (symalloc)
          DSP_CONTIGUOUS_MALLOC((*secpp)->symbols[i],DSPSymbol,symalloc);
        if (symalloc<symcount)
          return(_DSPError(DSP_EBADDSPFILE,
               "DSPSectionRead: symAlloc<symCount"));
        for (j=0;j<symcount;j++)
          DSPSymbolRead(&((*secpp)->symbols[i][j]),fp);
        if ( (*secpp)->data[i] ) {
            DSPDataRecord *dr;
            DSPDataRecordRead(&((*secpp)->data[i]),fp,*secpp);
            dr = (*secpp)->data[i];
            while (dr->next)    /* search for last data block in chain */
              dr = dr->next;
            (*secpp)->dataEnd[i] = dr; /* install ptr to it */
        }           
    }

    for (i=0;i<DSP_LC_NUM_P;i++) {
        fixupalloc = (*secpp)->fixupAlloc[i];
        fixupcount = (*secpp)->fixupCount[i];
        if (fixupalloc)
          DSP_CONTIGUOUS_MALLOC((*secpp)->fixups[i],DSPFixup,fixupalloc);
        if (fixupalloc<fixupcount)
          return(_DSPError(DSP_EBADDSPFILE,
               "DSPSectionRead: fixupAlloc<fixupCount"));
        for (j=0;j<fixupcount;j++)
          DSPFixupRead(&((*secpp)->fixups[i][j]),fp);
    }

    if ((*secpp)->xrefCount>0)
      _DSPError1(DSP_EBADSECTION,
        "Unsupported external symbol references encountered in section %s",
             (*secpp)->name);

    if ((*secpp)->xrefAlloc)
      DSP_CONTIGUOUS_MALLOC((*secpp)->xrefs,char*,(*secpp)->xrefAlloc);
    for (i=0;i<(*secpp)->xrefCount;i++)
      _DSPReadString(&((*secpp)->xrefs[i]),fp);

    return(0);
}


int DSPLoadSpecRead(DSPLoadSpec **dpp, FILE *fp)
{
    int mag;
    if(!fp) return(1);
    readInt(&mag,1,fp);
    if (mag<magicNumber)
      return(_DSPError(DSP_EBADDSPFILE,
         "Version mismatch: Binary DSP file is older than this compilation."));
    if (mag>magicNumber)
      return(_DSPError(DSP_EBADDSPFILE,
         "Version mismatch: Binary DSP file is newer than this compilation."));

    DSP_CONTIGUOUS_MALLOC(*dpp,DSPLoadSpec,1);
    readInt((void *)*dpp,sizeof(DSPLoadSpec)/sizeof(int),fp);

    _DSPReadString(&((*dpp)->module),fp);
    _DSPReadString(&((*dpp)->type),fp);
    _DSPReadString(&((*dpp)->comments),fp);
    _DSPReadString(&((*dpp)->description),fp);
    if ((*dpp)->globalSection)
      DSPSectionRead(&((*dpp)->globalSection),fp);
    if ((*dpp)->systemSection)
      DSPSectionRead(&((*dpp)->systemSection),fp);
    if ((*dpp)->userSection)
      DSPSectionRead(&((*dpp)->userSection),fp);
    (*dpp)->indexToSection[0] = (*dpp)->globalSection;
    (*dpp)->indexToSection[1] = (*dpp)->systemSection;
    (*dpp)->indexToSection[2] = (*dpp)->userSection;
    return(0);
}

static char *contiguousCopyStr(char *s)
{
    char *rtn = _DSPContiguousMalloc(strlen(s)+1);
    strcpy(rtn,s);
    return rtn;
}

static int copySymbol(DSPSymbol *toSymp, DSPSymbol *fromSymp)
{
    bcopy(&(fromSymp->locationCounter),&(toSymp->locationCounter),3*sizeof(int));
    bcopy(&(fromSymp->value.i),&(toSymp->value.i),sizeof(int));
    toSymp->name = contiguousCopyStr(fromSymp->name);
    toSymp->type = contiguousCopyStr(fromSymp->type);
    return 0;
}

static int copyDataRecord(
    DSPDataRecord **drpp,
    DSPDataRecord *fromdrp,			  
    DSPSection *sp)     /* pointer to section owning this data record */
{
    int nwords;

    if(!*drpp) 
      _DSPError(EINVAL,"DSPDataRecordRead: can't pass null pointer");

    DSP_CONTIGUOUS_MALLOC(*drpp,DSPDataRecord,1);
    bcopy(fromdrp,*drpp,sizeof(DSPDataRecord));
    (*drpp)->section = sp;      /* owning section */
    if (nwords=(*drpp)->wordCount) {
        DSP_CONTIGUOUS_MALLOC((*drpp)->data,int,nwords);
	bcopy(fromdrp->data,(*drpp)->data,nwords*sizeof(int));
    }
    if ((*drpp)->next) {
        copyDataRecord(&((*drpp)->next),fromdrp->next,sp);
        (*drpp)->next->prev = *drpp;
    }
    return(0);
}

static int copyFixup(DSPFixup *toFxpp, DSPFixup *fromFxpp)
{
    bcopy(fromFxpp,toFxpp,sizeof(DSPFixup));
    toFxpp->name = contiguousCopyStr(fromFxpp->name);
    return(0);
}

static int sectionCopy(DSPSection **toSecP, DSPSection *fromSec)
{
    int i,j,symcount,symalloc,fixupalloc,fixupcount;

    if(!*toSecP) return(0);

    DSP_CONTIGUOUS_MALLOC(*toSecP,DSPSection,1);
    bcopy((void *)fromSec,(void *)*toSecP,sizeof(DSPSection));

    (*toSecP)->name = contiguousCopyStr(fromSec->name);
    (*toSecP)->type = contiguousCopyStr(fromSec->type);

    for (i=0;i<DSP_LC_NUM;i++) {
        symcount = (*toSecP)->symCount[i];
        symalloc = (*toSecP)->symAlloc[i];
        if (symalloc)
          DSP_CONTIGUOUS_MALLOC((*toSecP)->symbols[i],DSPSymbol,symalloc);
        if (symalloc<symcount)
          return(_DSPError(DSP_EBADDSPFILE,
               "DSPSectionRead: symAlloc<symCount"));
        for (j=0;j<symcount;j++)
          copySymbol(&((*toSecP)->symbols[i][j]),&(fromSec->symbols[i][j]));
        if ( (*toSecP)->data[i] ) {
            DSPDataRecord *dr;
            copyDataRecord(&((*toSecP)->data[i]),fromSec->data[i],*toSecP);
            dr = (*toSecP)->data[i];
            while (dr->next)    /* search for last data block in chain */
              dr = dr->next;
            (*toSecP)->dataEnd[i] = dr; /* install ptr to it */
        }           
    }

    for (i=0;i<DSP_LC_NUM_P;i++) {
        fixupalloc = (*toSecP)->fixupAlloc[i];
        fixupcount = (*toSecP)->fixupCount[i];
        if (fixupalloc)
          DSP_CONTIGUOUS_MALLOC((*toSecP)->fixups[i],DSPFixup,fixupalloc);
        if (fixupalloc<fixupcount)
          return(_DSPError(DSP_EBADDSPFILE,
               "DSPSectionRead: fixupAlloc<fixupCount"));
        for (j=0;j<fixupcount;j++)
          copyFixup(&((*toSecP)->fixups[i][j]),&fromSec->fixups[i][j]);
    }

    if ((*toSecP)->xrefCount>0)
      _DSPError1(DSP_EBADSECTION,
        "Unsupported external symbol references encountered in section %s",
             (*toSecP)->name);

    if ((*toSecP)->xrefAlloc)
      DSP_CONTIGUOUS_MALLOC((*toSecP)->xrefs,char*,(*toSecP)->xrefAlloc);
    for (i=0;i<(*toSecP)->xrefCount;i++)
      (*toSecP)->xrefs[i] = contiguousCopyStr(fromSec->xrefs[i]);

    return(0);
}

int DSPCopyLoadSpec(DSPLoadSpec **dspPTo,DSPLoadSpec *dspFrom)
{
    DSPLoadSpec *dspTo;		/* struct containing entire DSP load image */
    DSP_CONTIGUOUS_MALLOC(dspTo,DSPLoadSpec,1);
    bcopy(dspFrom,dspTo,sizeof(DSPLoadSpec));
    dspTo->module = contiguousCopyStr(dspFrom->module);
    dspTo->type = contiguousCopyStr(dspFrom->type);
    dspTo->comments = contiguousCopyStr(dspFrom->comments);
    dspTo->description = contiguousCopyStr(dspFrom->description);
    if (dspFrom->globalSection)
      sectionCopy(&(dspTo->globalSection),dspFrom->globalSection);
    if (dspTo->systemSection)
      sectionCopy(&(dspTo->systemSection),dspFrom->systemSection);
    if (dspTo->userSection)
      sectionCopy(&(dspTo->userSection),dspFrom->userSection);
    dspTo->indexToSection[0] = dspTo->globalSection;
    dspTo->indexToSection[1] = dspTo->systemSection;
    dspTo->indexToSection[2] = dspTo->userSection;
    *dspPTo = dspTo;
    return(0);
}


int DSPLoadSpecReadFile(
    DSPLoadSpec **dspptr,               /* struct containing DSP load image */
    char *dspfn)                        /* DSPLoadSpecWriteFile output file */
{
    FILE *fp;                   /* relocatable link file pointer */
    int ec;

    if (_DSPTrace & DSP_TRACE_DSPLOADSPECREAD) 
      printf("\nDSPLoadSpecReadFile\n");

    fp = fopen(dspfn,"r");
    if (fp==NULL) 
      return(_DSPError1(DSP_EUNIX,
                        "DSPLoadSpecReadFile: could not open %s ",dspfn));

    checkDataRecordSizes();

    if (_DSPVerbose)
      printf("\tReading DSP fast-load file:\t%s\n",dspfn);

    ec = DSPLoadSpecRead(dspptr,fp);

    fclose(fp);    /* mtm added fclose 5/24/89 */

    if (_DSPVerbose)
      printf("\tFile %s closed.\n",dspfn);

    if (_DSPTrace & DSP_TRACE_DSPLOADSPECREAD) 
      DSPLoadSpecPrint(*dspptr);

    if (ec) 
      return(_DSPError1(ec,"DSPLoadSpecReadFile: read failed on %s ",dspfn));

    return(0);
}

/****************************** DEALLOCATION *********************************/

int _DSPFreeString(char *str)
{
    if (!str) return(0);
    _DSPContiguousFree(str);
    return(0);
}


int DSPDataRecordFree(DSPDataRecord *dr)
{
    if (!dr) return(0);
    if (dr->wordCount)
      _DSPContiguousFree((char *)(dr->data));
    if (dr->next)
      DSPDataRecordFree(dr->next);
    _DSPContiguousFree((char *)dr);
    return(0);
}


int DSPSymbolFree(DSPSymbol *sym)
{
    if (!sym) return(0);
    _DSPFreeString(sym->name);
    _DSPFreeString(sym->type);
    /* _DSPContiguousFree(sym); (Done by caller since mallocs were fused) */
    return(0);
}


int DSPFixupFree(DSPFixup *fxp)
{
    if (!fxp) return(0);
    _DSPFreeString(fxp->name);
    _DSPContiguousFree((char *)fxp);
    return(0);
}


int DSPSectionFree(DSPSection *sec)
{
    int i,j;

    if(!sec) return(0);

    _DSPFreeString(sec->name);
    _DSPFreeString(sec->type);

    for (i=0;i<DSP_LC_NUM;i++) {

        for (j=0;j<sec->symCount[i];j++) /* free individual symbols */
          DSPSymbolFree(&(sec->symbols[i][j]));

        if (sec->symbols[i])    /* free array of symbol pointers */
          _DSPContiguousFree((char *)(sec->symbols[i]));

        if (sec->data[i])       /* free array of symbol pointers */
          DSPDataRecordFree(sec->data[i]);      /* recursive free */
    }

    for (i=0;i<DSP_LC_NUM_P;i++) {
        for (j=0;j<sec->fixupCount[i];j++)
          DSPFixupFree(&sec->fixups[i][j]);
        if (sec->fixups[i])
          _DSPContiguousFree((char *)(sec->fixups[i]));
    }

    if (sec->xrefCount>0)
      _DSPError1(DSP_EBADSECTION,
         "External symbol references encountered in section %s",sec->name);

    for (i=0;i<sec->xrefCount;i++)
      _DSPFreeString(sec->xrefs[i]);

    if (sec->xrefs)
        _DSPContiguousFree((char *)(sec->xrefs));

    _DSPContiguousFree((char *)sec);

    return(0);
}


int DSPLoadSpecFree(DSPLoadSpec *dsp)
{
    if(!dsp) 
      return(0);

    /*** FIXME ***/
    return(0);

    _DSPFreeString(dsp->module);
    _DSPFreeString(dsp->type);
    _DSPFreeString(dsp->comments);
    _DSPFreeString(dsp->description);
    DSPSectionFree(dsp->globalSection);
    DSPSectionFree(dsp->systemSection);
    DSPSectionFree(dsp->userSection);
    _DSPContiguousFree((char *)dsp);
    return(0);
}

/******************************* MISCELLANEOUS *******************************/

DSPSection *DSPGetUserSection(DSPLoadSpec *dspStruct)
{
    DSPSection *user;

    /* 

      If the user was assembled in absolute mode,
      or if this is a .lnk file with no
      sections, then code lives in GLOBAL section,
      and all other sections are empty.
     */

    if (*dspStruct->type == 'A')
      user = dspStruct->globalSection;
    else
      user = dspStruct->userSection;
    return(user);
}

DSPAddress DSPGetFirstAddress(DSPLoadSpec *dspStruct,
                              DSPLocationCounter locationCounter)
{
    DSPAddress firstAddress;
    DSPSection *user;
    DSPDataRecord *dr;

    user = DSPGetUserSection(dspStruct);
    dr = user->data[(int)locationCounter];
    firstAddress = user->loadAddress[(int)locationCounter] + dr->loadAddress;
    return(firstAddress);
}


DSPAddress DSPGetLastAddress(DSPLoadSpec *dspStruct, 
                             DSPLocationCounter locationCounter)
{
    DSPAddress firstAddress;
    DSPAddress lastAddress;
    DSPSection *user;
    DSPDataRecord *dr;

    user = DSPGetUserSection(dspStruct);

    dr = user->data[(int)locationCounter];
    firstAddress = DSPGetFirstAddress(dspStruct,locationCounter);
    lastAddress = firstAddress + dr->wordCount - 1;
    if (dr->next)
      _DSPError(DSP_EBADLNKFILE,
     "DSPGetLastAddress: Not intended for multi-segment (absolute) assemblies");
    return(lastAddress);
}


int DSPDataRecordInsert(DSPDataRecord *dr,
                        DSPDataRecord **head,
                        DSPDataRecord **tail) 
{
    dr->next = NULL;
    dr->prev = NULL;
    if (!*head) {
        *head = dr; /* first data block */
        *tail = dr; /* last data block */
    } else {
        DSPDataRecord *sb;
        sb = *tail;
        /* Sort by start address of data block */
        do {
            if (sb->loadAddress <= dr->loadAddress) {
                /* insert dr after sb */
                if (sb->next)
                  (sb->next)->prev = dr;
                else /* nil next means we have a new tail */
                  *tail = dr;
                dr->next = sb->next;
                dr->prev = sb;
                sb->next = dr;
                return(0);
            }
        } while (sb=sb->prev);
        /* block failed to place. Therefore it's first */
        (*head)->prev = dr;
        dr->next = *head;
        *head = dr;
    }
    return(0);
}


int DSPDataRecordMerge(DSPDataRecord *dr)
/* 
 * Merge contiguous, sorted dataRecords within a DSP memory space.
 * Argument is a pointer to the first data record in a linked list.
 */
{
    DSPDataRecord *dr1,*dr2;
    int la1,la2;                /* load addresses */
    int nw1,nw2;                /* word counts */
    int rp1,rp2;                /* repeat factors */
    int *dt1,*dt2;              /* data pointers */
    int i,nwr;

    if (!dr) return(0);
    dr1 = dr;                   /* first data block */

    while (dr2=dr1->next) {

        la1 = dr1->loadAddress;
        la2 = dr2->loadAddress;
        nw1 = dr1->wordCount;
        nw2 = dr2->wordCount;
        rp1 = dr1->repeatCount;
        rp2 = dr2->repeatCount;
        dt1 = dr1->data;
        dt2 = dr2->data;

        /* Compute number of words really spanned by data record */
        nwr = (dr1->locationCounter >= DSP_LC_L && 
               dr1->locationCounter <= DSP_LC_LH) ? /* if L memory */
                 nw1 >> 1 :     /* address range = wordcount / 2 */
                   nw1;         /* else it's wordcount */

        /* Skip merge if data not contiguous */
        if(la1 + nwr*rp1 != la2)
            goto skipMerge;

        /* Merge adjacent memory fills if fill-constants are the same */
        if (rp1>1 && rp2>1      /* both are fill constants */
            && ((nw1==1 && nw2==1) /* for 24-bit (x,y, or p) memory */
               || (nw1==2 && nw2==2)) /* or 48-bit (l) memory */
            && dt1[0] == dt2[0] /* same constant */
            && (nw1 == 1 || dt1[1] == dt2[1]) )
          {
              dr1->repeatCount += dr2->repeatCount;
              goto finishMerge;
          }         

        /* The above case is the only one in which we merge data blocks
           involving a repeatCount > 1.  We don't expand constant 
           fills into general data arrays. */

        if (rp1>1 || rp2>1) goto skipMerge;     /* no way to combine */

        /* Here, both repeat factors are 1 (rp1==1, rp2==1) */

        DSP_REALLOC(dt1,int,nw1+nw2);

        dr1->data = dt1;

        for (i=0;i<nw2;i++)
          dt1[nw1+i] = dt2[i]; /* copy data array */

        dr1->wordCount += nw2;

      finishMerge:
        dr1->next = dr2->next;
        if (dr1->next)
          dr1->next->prev = dr1;
        dr2->next = NULL;       /* prevent recursive deallocation beyond dr2 */
        DSPDataRecordFree(dr2);
        goto continueMerge;
      skipMerge:
        dr1 = dr1->next;
      continueMerge:
        ;
    }
    return(0);
}
