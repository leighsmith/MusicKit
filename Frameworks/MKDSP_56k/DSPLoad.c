/*	DSPLoad.c - Load user program into running DSP.
	Copyright 1988-1992, NeXT Inc.  All rights reserved.
	
	Modification history:
	03/06/88/jos - File created
	04/23/90/jos - Flushed DSPMKLoad()
	04/30/90/jos - Removed "r" prefix from rData, rWordCount, rRepeatCount
	05/04/90/jos - Replaced
			DSPCall(dsp_hm_set_start,1,&(dspimg->startAddress));
		       with
		        return DSPWriteValue(dspimg->startAddress,DSP_MS_X,
		       	       DSPGetSystemSymbolValue("X_START"));
	*/

#ifdef SHLIB
#include "shlib.h"
#endif

#include "_dsp.h"

int DSPLoadFile(char *fn)
{
    int ec;
    DSPLoadSpec *ls;
    ec = DSPReadFile(&ls,fn);
    if (ec)
      return(ec);
    return DSPLoad(ls);
}

int DSPLoad(DSPLoadSpec *dspimg)	/* load code or NULL to read default */
{
    register int curLC;
    register DSPSection *usr;
    register DSPDataRecord *dr;
    int nwords,la;
    
    if (!dspimg)
      return _DSPError(EDOM,"DSPLoad: null DSP pointer passed");
    
#if 0
    if (DSPIsSimulated()) 
      fprintf(DSPGetSimulatorFP(),";; *** DSPLoad simulation ***\n\n");
    
    if (_DSPTrace & DSP_TRACE_LOAD) 
      fprintf(stderr,"\tLoading user DSP code, version %d.0(%d).\n",	
	      dspimg->version,dspimg->revision);

    if(ec=DSPCheckVersion(&sysver,&sysrev))
      return _DSPError1(ec,"DSPLoad: DSPCheckVersion() has problems with "
			"DSP system %s",dspimg->module);
    
    if (sysver != dspimg->version || sysrev != dspimg->revision)
      _DSPError1(DSP_EBADVERSION,
		DSPCat(DSPCat("DSPLoad: *** WARNING *** Passed DSP "
				"load spec '%s' has version(revision) = ",
				DSPCat(_DSPCVS(dspimg->version),
				DSPCat(".0(",_DSPCVS(dspimg->revision)))),
			DSPCat(") while DSP is running ",
				DSPCat(_DSPCVS(sysver),
					DSPCat(".0(",
						DSPCat(_DSPCVS(sysrev),
							")"))))),
		 dspimg->module);
		
#endif
/******************************** LOAD DSP CODE *****************************/
    
    usr = DSPGetUserSection(dspimg);
    if (!usr) return(_DSPError(DSP_EBADLODFILE,
			       "libdsp/DSPLoad: No user code found "
			       "in DSP struct"));
    
    for (curLC=(int)DSP_LC_X; curLC<DSP_LC_NUM; curLC++) {
	
	if ( dr = usr->data[curLC] ) {
	    
	    la = dr->loadAddress + usr->loadAddress[curLC];
	    nwords = dr->repeatCount * dr->wordCount;
#if TRACE_POSSIBLE
	    if (_DSPTrace & DSP_TRACE_LOAD) 
	      fprintf(stderr,"Loading %d words of user %s memory "
		      "at 0x%X:\n", nwords,DSPLCNames[curLC],(unsigned int)la);
#endif	    
	    if (curLC != (int)dr->locationCounter)
	      _DSPError1(DSP_EBADDR,
			 "libdsp/DSPLoad: data record thinks its "
			 "memory segment is %s!",
			 (char *) DSPLCNames[(int)dr->locationCounter]);
	    
	    DSP_UNTIL_ERROR(DSPDataRecordLoad(dr));
	}
    }
    
    /* USER IS LOADED */
    
#if 0
    if (DSPIsSimulated()) 
      fprintf(DSPGetSimulatorFP(),";; *** User is loaded ***\n");
    
    if (DSPCheckVersion(&ver,&rev))
      DSP_MAYBE_RETURN(_DSPError(DSP_ESYSHUNG,
				 "DSPLoad: DSP is not responding "
				 "after download"));
    
    if (_DSPTrace & DSP_TRACE_LOAD) 
      fprintf(stderr,"\tStart address = 0x%X.\n", dspimg->startAddress);

    if (DSPIsSimulated()) 
      fprintf(DSPGetSimulatorFP(),";; *** Set start address ***\n\n");

#endif

    if (dspimg->startAddress > 0) /* 0 is the reset vector, so its illegal */
      return DSPWriteValue(dspimg->startAddress,DSP_MS_X, 
			   DSPGetSystemSymbolValue("X_START"));

    return 0;
}

