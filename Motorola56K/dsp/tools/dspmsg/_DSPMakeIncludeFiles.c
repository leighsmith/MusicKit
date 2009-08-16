/*	_DSPMakeIncludeFiles.c - Regenerate $LIBDSP/dsp_messages.h,
	$LIBDSP/dsp_memory_map.h, $DSPSMSRC/sys_messages.asm, and
	$DSPSMSRC/sys_memory_map_<kit>.asm.

	Copyright 1989 NeXT, Inc.
	
	Modification history:
	03/31/88/jos - File created with extract from DSPBoot.c
	04/04/88/jos - Added generation of $DSP/smsrc/sys_messages.asm
	05/09/88/jos - Moved NB_ from Y mem section to N section
	08/21/88/jos - Removed "HD_" (general host data)
	08/21/88/jos - Added "MAX_" and "MIN_"
	05/15/89/jos - Added "I_" to get DSP_I_NTICK defined.
	06/07/89/jos - Inserted "_" in filenames, added sfx and support,
		       and split dsp_messages.h into itself + dsp_memory_map...
	06/23/89/jos - Added support for absolute assembly. (sys = glob)
		       Note: for absolute assembly, it is not necessary to
		       pass separately through the global and system sections
		       (since they are the same in this case => two passes).
		       However, the runtime is very short already.
	06/27/89/jos - Moved to dsp/tools/dspmsg directory. Now using dsp.h.
	05/04/90/jos - Introduced def_of(name,val) indirection for DSP syms.
	05/04/90/jos - Generified dsp_memory_map_{ap,mk}.h to dsp_memory_map.h.
	05/04/90/jos - Changed suffix from "mk" or "ap" to full module name.
		       Suffix now applies only to sys_memory_map_<sfx>.asm.
	05/04/90/jos - Flushed support of "HD_" P sym prefix (misc. host data).
	05/04/90/jos - Flushed support of "MAIN_DONE" P symbol.
	05/05/90/jos - Added lc arg to def_of() (for speed).
	
*/

#include <dsp/_dsp.h>
#define DSP_TRACE_SYMBOLS 512 /* Also defined in libdsp/_dsp.h */

extern int _DSPTrace,_DSPVerbose;

static char *def_of(char *name, int val, DSPLocationCounter lc)
/*
 * Construct a string which defines the symbol with the given name
 * to the given value.  Example: given name = "HM_IDLE" and value 0x3fe0,
 * we could emit the string "0x3fe0" to be appended to "#define DSP_HM_IDLE"
 * by the caller.  Instead we dig the symbol out of the DSPLoadSpec symbol 
 * table at run time.  This makes it slower, so the user should cache the
 * value.
 */
{
    return DSPCat(DSPCat(DSPCat(DSPCat("DSPGetSystemSymbolValueInLC(\"",name),
			        "\", DSP_LC_"),
 			 (char *)DSPLCNames[lc]),
		  ")");
}

int _DSPMakeIncludeFiles(system) /* Write out AP and MK include files */
    DSPLoadSpec *system;
{
    DSPSection *sys, *glob;
    char *dmfn,*odmfn;		/* new and old "dsp messages" .h file name */
    char *dmmfn,*odmmfn;	/* new and old "dsp memory map" .h file name */
    char *smfn,*osmfn;		/* "system declarations" .asm file name */
    char *smmfn,*osmmfn;	/* "system memory map" .asm file name */
    char *dmdefn,*odmdefn;	/* new and old "dsp message names" .h name */
    char *sfx;			/* "mk" for music kit, "ap" for array proc */
    char *sfxKit;		/* "Music Kit" or "Array Processing" */
    char *SFX;			/* "MK" for music kit, "AP" for array proc */
    FILE *dmfp;			/* dsp_messages.h (c include file) */
    FILE *dmmfp;		/* dsp_memory_map_<sfx>.asm .c include file */
    FILE *smfp;			/* sys_messages.asm (asm include file) */
    FILE *smmfp;		/* sys_memory_map_<sfx>.asm include file */
    FILE *dmdefp;		/* DSP message mnemonics versus int code */
    int i,mem,symval;
    char *symname,*symnameuc,*symtype;
    char *libdspdir,*dspdir,*dspsmdir;
    char *getenv();
    char *DMnames[256],*DEnames[256]; /* DSP message mnemonics vs int code */
    int maxDM=0,maxDE=0;
    int absasm=0;

    sfx = _DSPToLowerStr(_DSPCopyStr(system->module));
    SFX = _DSPToUpperStr(_DSPCopyStr(sfx));
    if (strncmp(sfx,"mk",2)==0)
	sfxKit = "Music Kit";
    else if (strncmp(sfx,"ap",2)==0)
      sfxKit = "Array Processing";
    else
      sfxKit = DSPCat("DSP",SFX); /* ? */

    if (_DSPTrace)
      printf("Package suffix = \"%s\"\n",sfx);

    sys = system->systemSection;
    glob = system->globalSection;
    
    if (!sys) {
	sys = glob;		/* Absolute assembly has only global section */
	absasm=1;
	if (!sys)
	  return _DSPError1(DSP_EBADLODFILE,"_DSPMakeIncludeFiles: no "
			    "systemSection or globalSection in DPS struct %s",
			    system->module);
    }
    /******** GENERATE HOST MESSAGE AND DSP MESSAGE TABLES *******/

/* Insist on doing everything in current working directory. */
    dspdir = "";
    libdspdir = "";
    dspsmdir = "";

/****************************** dsp_messages.h *******************************/

    dmfn = DSPCat(libdspdir,"dsp_messages.h");
    odmfn = DSPCat(libdspdir,"dsp_messages.h.bak");
    if (_DSPVerbose||_DSPTrace)
      printf("Saving previous dsp-message include file as %s\n",odmfn);
    rename(dmfn,odmfn);
    if ((dmfp=_DSPMyFopen(dmfn,"w"))==NULL) 
      _DSPError1(EIO,"_DSPMakeIncludeFiles: "
		 "Can't open %s for writing", dmfn);
    else 
      if (_DSPVerbose||_DSPTrace)
	printf("Writing dsp-message include file %s\n",dmfn);
    
    fprintf(dmfp,
"/* dsp_messages.h - "
	    "written by dspmsg from Music Kit DSP monitor system symbols.\n\
\n\
This include file contains definitions for \"host-message\" and \n\
\"DSP message\" opcodes used by the Music Kit (MK) and Array Processing (AP)\n\
libraries.\n\
\n\
\"Host messages\" are mnemonics for DSP system subroutine entry points. \n\
They are called by the host for communication purposes via the\n\
DSPCall() or DSPHostMessage() functions in libdsp.  Each host message \n\
opcode has the prefix \"DSP_HM\".\n\
\n\
\"DSP messages\" are one-word (24 bit) messages which flow from the \n\
DSP to the host.  DSP messages use the prefix \"DSP_DM\".\n\
\n\
A DSP message consists of one byte of opcode and two bytes of data.\n\
Opcodes from 128 to 255 are, by MK/AP convention, error messages, and\n\
their prefix is \"DSP_DE\" rather than \"DSP_DM\".\n\
\n\
*/ \n");
	
/************************* dsp_memory_map.h **********************************/

    dmmfn = DSPCat(libdspdir,"dsp_memory_map.h");
    odmmfn = DSPCat(dmmfn,".bak");
    rename(dmmfn,odmmfn);
    if (_DSPVerbose||_DSPTrace)
      printf("Saving previous dsp-message include file as %s\n",odmmfn);
    if ((dmmfp=_DSPMyFopen(dmmfn,"w"))==NULL) 
      _DSPError1(EIO,"_DSPMakeIncludeFiles: "
		 "Can't open %s for writing", dmmfn);
    else 
      if (_DSPVerbose||_DSPTrace)
	printf("Writing dsp-message include file %s\n",dmmfn);
    
    fprintf(dmmfp,
"/* dsp_memory_map.h - written by dspmsg from system symbols.\n"
"\n"
"This include file contains definitions for DSP memory addresses.\n"
"The values depend heavily on /usr/lib/dsp/smsrc/config.asm, and they\n"
"tend to change every time the DSP system code is modified.\n"
"Address names are of the form \n"
"\n"
"		DSP_{X,Y,P,L}{L,H}{I,E}_{USR,SYS}\n"
"\n"
"where {X,Y,P,L} are the possible memory spaces in the DSP, {L,H} specifies \n"
"lower or higher memory segment boundary, {I,E} specifies internal or \n"
"external memory, and {USR,SYS} specifies user or system memory segments. \n"
"For example, PHE_USR specifies the maximum address available to the user \n"
"in external program memory.  In general, the system occupies the lowest and \n"
"highest address range in each space, with the user having all addresses in \n"
"between.\n"
"\n"
"Names of the form 'DSP_I_<name>' denote integer constants.\n"
"Names of the form 'DSP_NB_<name>' denote buffer sizes.\n"
"Names of the form 'DSP_N{X,Y,L,P}{I,E}_{USR,SYS}' "
	    "denote memory segment sizes.\n"
"*/ \n");
	

/**************************** sys_messages.asm *******************************/

    smfn = DSPCat(dspsmdir,"sys_messages.asm");
    osmfn = DSPCat(smfn,".bak");
    rename(smfn,osmfn);
    if (_DSPVerbose||_DSPTrace)
      printf("Saving old dsp assembly memory map include file as %s\n",osmfn);
    if ((smfp=_DSPMyFopen(smfn,"w"))==NULL) 
      _DSPError1(EIO,"_DSPMakeIncludeFiles: "
		 "Can't open %s for writing",smfn);
    else 
      if (_DSPVerbose||_DSPTrace)
	printf("Writing DSP assembly memory map include file %s\n",smfn);
    
    fprintf(smfp,
"; sys_memory_map.asm - written by dspmsg from system symbols.\n\
;\n\
; This DSP system include file contains definitions for host-message \n\
; opcodes as well as other system entry points needed by DSP programs which \n\
; are to be assembled without the DSP system code. For example, stand-alone \n\
; orchestra and array processing test programs need this file.  Constants \n\
; defined here should be independent of DSP memory size or configuration. \n\
;\n");

/**************************** _dsp_message_names *****************************/

    dmdefn = DSPCat(libdspdir,"_dsp_message_names.h");
    odmdefn = DSPCat(libdspdir,"_dsp_message_names.h.bak");
    rename(dmdefn,odmdefn);

    if ((dmdefp=_DSPMyFopen(dmdefn,"w"))==NULL) 
      _DSPError1(EIO,"_DSPMakeIncludeFiles: Can't open %s for writing",
		     dmdefn);
    else 
      if (_DSPVerbose||_DSPTrace)
	printf("Writing dsp-message include file %s\n",dmdefn);
    
    fprintf(dmdefp,"/* _dsp_message_names.h - "
	    "written by dspmsg from system symbols.\n\
\n\
This private include file provides two string arrays useful for decoding \n\
DSP-message and DSP-error-message opcodes.\n\
\n\
*/\n");
	
/**************************** sys_memory_map_<sfx>.asm ***********************/

    smmfn = DSPCat(dspsmdir,DSPCat("sys_memory_map_",DSPCat(sfx,".asm")));
    osmmfn = DSPCat(smmfn,".bak");
    rename(smmfn,osmmfn);
    if (_DSPVerbose||_DSPTrace)
      printf("Saving previous dsp assembly include file as %s\n",osmmfn);
    if ((smmfp=_DSPMyFopen(smmfn,"w"))==NULL) 
      _DSPError1(EIO,"_DSPMakeIncludeFiles: "
		 "Can't open %s for writing",smmfn);
    else 
      if (_DSPVerbose||_DSPTrace)
	printf("Writing DSP assembly include file %s\n",smmfn);
    
    fprintf(smmfp,
"; sys_memory_map_%s.asm - "
	    "written by dspmsg from system symbols.\n\
;\n\
; This DSP system include file contains memory-map pointers for the %s case.\n\
; The constants defined here change as a function of DSP memory size and \n\
; assembly configuration. \n\
;\n",sfx,SFX);
	
/************************* Emit global symbols (space N) *********************/

    mem = (int) DSP_LC_N; /* global symbols, no associated memory */
    fprintf(dmfp,"\n/***** GLOBAL SYMBOLS *****/\n");
    fprintf(smfp,"\n;***** GLOBAL SYMBOLS *****\n");
    fprintf(dmmfp,"\n/***** GLOBAL SYMBOLS *****/\n");
    fprintf(smmfp,"\n;***** GLOBAL SYMBOLS *****\n");

    /**** GENERATE DSP MESSAGE CONSTANTS ****/
    if (_DSPTrace & DSP_TRACE_SYMBOLS) 
      printf("\nGlobal symbols, N memory:\n");
    
    for (i=0;i<glob->symCount[mem];i++) {
	symname = glob->symbols[mem][i].name;
	_DSPToUpperStr (symnameuc = _DSPCopyStr(symname));
	symtype = glob->symbols[mem][i].type;
	symval = glob->symbols[mem][i].value.i;

	/*
	 * Global constants which are memory and configuration independent.
	 */
	if ((strncmp(symnameuc,"DM_",3)==0)    /* DSP message */
	    || (strncmp(symnameuc,"DE_",3)==0) /* DSP error message */
	    || (strncmp(symnameuc,"SYS_",4)==0) /* system version,rev */
	    ) {
	    if (strcmp(symtype,absasm?"I":"GAI")!=0) 
	      _DSPError1(DSP_EBADSYMBOL,
	       "_DSPMakeIncludeFiles: global symbol %s not type 'GAI'",
		  symnameuc);
	    if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("------>");
	    fprintf(dmfp,"#define DSP_%s %s\n",symnameuc,
		    def_of(symnameuc,symval,mem));
	    fprintf(smfp,"%s\t\t EQU $%06x\n",symnameuc,symval);
	    if (strncmp(symnameuc,"DM_",3)==0) {   /* DSP message */
		if (symval>=128)
		  _DSPError(DSP_EBADLNKFILE,
			 "_DSPMakeIncludeFiles: DSP Message opcode "
			 "occupies more than eight bits");
		else {
		    DMnames[symval] = symname+3;
		    if (symval>maxDM) maxDM=symval;
		}
	    }	
	    if (strncmp(symnameuc,"DE_",3)==0) {   /* DSP error message */
		if (symval>=256 || symval<128)
		  _DSPError(DSP_EBADLNKFILE, "_DSPMakeIncludeFiles: "
			    "DSP error message opcode"
			    "is not between 0x80 and 0xFF");
		else {
		    symval = DSP_ERROR_OPCODE_INDEX(symval); /* dsp.h */
		    DEnames[symval] = symname+3;
		    if (symval>maxDE) maxDE=symval;
		}
	    }
	}
	/*
	 * Global constants which change with memory size and configuration.
	 */
	if (
	       (strncmp(symnameuc+3,"_SYS",4)==0) /* system mem boundaries */
	    || (strncmp(symnameuc+3,"_USR",4)==0) /* user memory boundaries */
	    || (strncmp(symnameuc+2,"_USR",4)==0) /* user memory boundaries */
	    || (strncmp(symnameuc+3,"_SEG",4)==0) /* x/y segment boundaries */
	    || (strncmp(symnameuc+3,"_USG",4)==0) /* user x/y segment bounds */
	    || (strncmp(symnameuc+3,"_RAM",4)==0) /* physical mem boundaries */
	    || (strncmp(symnameuc+3,"_ROM",4)==0) /* physical mem boundaries */
	    || (strncmp(symnameuc,"NB_",3)==0)	/* system buffer sizes */
	    || (strncmp(symnameuc,"I_",2)==0) /* Integer constants */
	    || (strncmp(symnameuc,"DEGMON_",7)==0)
	    ) {
	    if (strcmp(symtype,absasm?"I":"GAI")!=0) 
	      _DSPError1(DSP_EBADSYMBOL,
	       "_DSPMakeIncludeFiles: global symbol %s not type 'GAI'",
		  symnameuc);
	    if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("------>");
	    fprintf(dmmfp,"#define DSP_%s %s\n",symnameuc, 
		    def_of(symnameuc,symval,mem));
	    /* The assembly language version gets no prefix because it is
	       intended to stand for the case of assembly including the system.
	       Thus, the symbols must look the same in either case. */
	    fprintf(smmfp,"%s\t\t EQU $%06x\n",symnameuc,symval);
	}
	if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("\t%s\n",symnameuc);
    }	

/************************* Emit _dsp_message_names.h ************************/

    fprintf(dmdefp,"\tstatic int   DSPNErrorNames = %d;\n",maxDE+1);
    fprintf(dmdefp,"\n\tstatic char *DSPErrorNames[] = {\n");
    for(i=0;i<maxDE;i++)
	fprintf(dmdefp,"\t\t\"%s\",\n",DEnames[i]);
    if (maxDE>=0)
      fprintf(dmdefp,"\t\t\"%s\"};\n",DEnames[maxDE]);

    fprintf(dmdefp,"\n\n\tstatic int DSPNMessageNames = %d;\n",maxDM+1);
    fprintf(dmdefp,"\n\tstatic char *DSPMessageNames[] = {\n");
    for(i=0;i<maxDM;i++)
	fprintf(dmdefp,"\t\t\"%s\",\n",DMnames[i]);
    if (maxDM>=0)
      fprintf(dmdefp,"\t\t\"%s\"};\n",DMnames[maxDM]);

    fclose(dmdefp);
    if (_DSPVerbose||_DSPTrace)
      printf("Closed file\n\t%s\n",dmdefn);

/************************** Emit P symbols (HM, LOC) *************************/

    /* mem = (int) DSP_LC_PH; /* system symbols, upper segment */
    mem = (int) DSP_LC_P;  /* system symbols */
    if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("\nSystem p symbols:\n");
    fprintf(dmfp,"\n/***** PH SYMBOLS (DISPATCH ADDRESSES) *****/\n");
    fprintf(smfp,"\n;***** PH SYMBOLS (DISPATCH ADDRESSES) *****\n");

    for (i=0;i<sys->symCount[mem];i++) {
	
	symname = sys->symbols[mem][i].name;
	_DSPToUpperStr (symnameuc = _DSPCopyStr(symname));
	symtype = sys->symbols[mem][i].type;
	symval = sys->symbols[mem][i].value.i;
	
	if (   (strncmp(symnameuc,"HM_",3)==0) /* host message */
	    || (strncmp(symnameuc,"LOC_",4)==0)	 /* System variable dispatch */
	    ) {
	    if (strncmp(symtype,absasm?"I":"GAI",3)!=0) 
	      _DSPError1(DSP_EBADSYMBOL,
		"_DSPMakeIncludeFiles: symbol %s not type 'GAI'",
		   symname);
	    if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("------>");
	    fprintf(dmfp,"#define DSP_%s %s\n",
		    symnameuc,def_of(symnameuc,symval,mem)); /* c */
	    fprintf(smfp,"\t\txdef %s\n%s\t equ $%06x\n\n",
		    symname,symname,symval); /* dsp assembler */
	}
	if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("\t%s\n",symname);
    }

/*************************** Emit X symbols (X_*) ****************************/

    mem = (int) DSP_LC_X;
    fprintf(dmmfp,"\n/***** X SYMBOLS *****/\n");
    fprintf(smmfp,"\n;***** X SYMBOLS *****\n");

    for (i=0;i<sys->symCount[mem];i++) {
	
	symname = sys->symbols[mem][i].name;
	_DSPToUpperStr (symnameuc = _DSPCopyStr(symname));
	symtype = sys->symbols[mem][i].type;
	symval = sys->symbols[mem][i].value.i;
	
	if (   (strncmp(symnameuc,"X_",2)==0) /* Global X system variables */
	     && (strncmp(symtype,absasm?"I":"GAI",3)==0) ) {
	    if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("------>");
	    fprintf(dmmfp,"#define DSP_%s %s\n",symnameuc,
		    def_of(symnameuc,symval,mem)); /* c */
	    fprintf(smmfp,"\txdef %s\n%s\t\t equ $%06x\n",
		    symname,symname,symval); /* dsp assembler */
	}
	if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("\t%s\n",symname);
    }
    

/************************ Emit Y symbols (Y_*, YB_*) *************************/

    mem = (int) DSP_LC_Y;
    fprintf(dmmfp,"\n/***** Y SYMBOLS *****/\n");
    fprintf(smmfp,"\n;***** Y SYMBOLS *****\n");

    for (i=0;i<sys->symCount[mem];i++) {
	
	symname = sys->symbols[mem][i].name;
	_DSPToUpperStr (symnameuc = _DSPCopyStr(symname));
	symtype = sys->symbols[mem][i].type;
	symval = sys->symbols[mem][i].value.i;
	
	if (  ( (strncmp(symnameuc,"Y_",2)==0)	 /* Global Y system variables */
	     || (strncmp(symnameuc,"YB_",3)==0))  /* Global Y system buffers */
	     && (strncmp(symtype,absasm?"I":"GAI",3)==0) ) {
	    if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("------>");
	    fprintf(dmmfp,"#define DSP_%s %s\n",symnameuc,
		    def_of(symnameuc,symval,mem)); /* c */
	    fprintf(smmfp,"\txdef %s\n%s\t\t equ $%06x\n",
		    symname,symname,symval); /* dsp assembler */
	}
	if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("\t%s\n",symname);
    }
    
/*************************** Emit L symbols (L_*) ****************************/

    mem = (int) DSP_LC_L;
    fprintf(dmmfp,"\n/***** L SYMBOLS *****/\n");
    fprintf(smmfp,"\n;***** L SYMBOLS *****\n");

    for (i=0;i<sys->symCount[mem];i++) {
	
	symname = sys->symbols[mem][i].name;
	_DSPToUpperStr (symnameuc = _DSPCopyStr(symname));
	symtype = sys->symbols[mem][i].type;
	symval = sys->symbols[mem][i].value.i;
	
	if (   (strncmp(symnameuc,"L_",2)==0) /* Global L system variables */
	     && (strncmp(symtype,absasm?"I":"GAI",3)==0) ) {
	    if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("------>");
	    fprintf(dmmfp,"#define DSP_%s %s\n",symnameuc,
		    def_of(symnameuc,symval,mem)); /* c */
	    fprintf(smmfp,"\txdef %s\n%s\t\t equ $%06x\n",
		    symname,symname,symval); /* dsp assembler */
	}
	if (_DSPTrace & DSP_TRACE_SYMBOLS) printf("\t%s\n",symname);
    }
    
/**************************** Close output files *****************************/

    fclose(dmfp);		/* dsp_messages.h */
    fclose(dmmfp);		/* dsp_memory_map.h */
    fclose(smfp);		/* sys_messages.h */
    fclose(smmfp);		/* sys_memory_map_mkmon8k.h */
    if (_DSPVerbose||_DSPTrace)
      printf("Closed files \n\t%s\n\t%s\n\t%s\n\t%s\n",dmfn,dmmfn,smfn,smmfn);
    return(0);
}

