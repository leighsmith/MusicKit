/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* dsptest.c - Run simple tests on the DSP

   Link against libdsp.a

   Modification history:

   03/18/93/daj - Flushed AP MON support.  Added -l switch to set the monitor.
   11/04/94/jos - Fixed bug in mem sensing that overrode -l switch.
*/

#include "dsp/dsp.h"
#include "dsp/dsp_memory_map.h"
#import <sound/sound.h>

extern char *_DSPToLowerStr(char *s);
extern char *_DSPCVS(int i);
extern int DSPEnableMappedOnly(void);

DSP_BOOL do_cont = FALSE;	/* if TRUE, continue after errors */
int memory_expansion = 0;        /* nonzero for expanded DSP memory */
DSP_BOOL do_pio = FALSE;	/* if TRUE, disable DMA */
DSP_BOOL do_dma = FALSE;	/* if TRUE, enable DMA */
int dsp_number = -1;
volatile int hangit=0;

void test_fail(char *msg)
{
    fprintf(stderr,"*** %s\n",msg);
    if (!do_cont)
      exit(1);
}

#define DSP_EXT_RAM_SIZE_MAX 65536

DSPFix24 arr1[DSP_EXT_RAM_SIZE_MAX];
DSPFix24 arr2[DSP_EXT_RAM_SIZE_MAX];

float farr1[DSP_EXT_RAM_SIZE_MAX];
float farr2[DSP_EXT_RAM_SIZE_MAX];

double darr1[DSP_EXT_RAM_SIZE_MAX];
double darr2[DSP_EXT_RAM_SIZE_MAX];

DSPLoadSpec *dspSystem;

int check_readback(int size)
{
    int i,j;
    for (i=0;i<size;i++) {
	if (arr1[i] != arr2[i]) {
	    fprintf(stderr,"*** at i=%d: sent 0x%X but read back 0x%X\n",
		    i,(unsigned int)arr1[i],(unsigned int)arr2[i]);
	    if (!do_cont)
	      break;
	}
    }
    if (i != size) {
	if (do_cont) 
	  return(-1);
	else {
	    fprintf(stderr," failed at i=%d.\n",i);
	    DSPClose();
	    exit(1);
	}
    } else 
      fprintf(stderr," ... wins.\n");
    
    for (j=0;j<size;j++) 
      arr2[j] = 0;

    return (i != size);
}

int fcheck_readback(int size)
{
    int i,j;
    for (i=0;i<size;i++) {
	if (farr1[i] != farr2[i]) {
	    fprintf(stderr,"*** at i=%d: sent 0x%X but read back 0x%X\n",
		    i,(unsigned int)farr1[i],(unsigned int)farr2[i]);
	    if (!do_cont)
	      break;
	}
    }
    if (i != size) {
	if (do_cont) 
	  return(-1);
	else {
	    fprintf(stderr," failed at i=%d.\n",i);
	    DSPClose();
	    exit(1);
	}
    } else 
      fprintf(stderr," ... wins.\n");
    
    for (j=0;j<size;j++) 
      farr2[j] = 0;

    return (i != size);
}

int dcheck_readback(int size)
{
    int i,j;
    for (i=0;i<size;i++) {
	if (darr1[i] != darr2[i]) {
	    fprintf(stderr,"*** at i=%d: sent 0x%X but read back 0x%X\n",
		    i,(unsigned int)darr1[i],(unsigned int)darr2[i]);
	    if (!do_cont)
	      break;
	}
    }
    if (i != size) {
	if (do_cont) 
	  return(-1);
	else {
	    fprintf(stderr," failed at i=%d.\n",i);
	    DSPClose();
	    exit(1);
	}
    } else 
      fprintf(stderr," ... wins.\n");
    
    for (j=0;j<size;j++) 
      darr2[j] = 0;

    return (i != size);
}


static char monitorPath[2048] = ""; /* was DSP_MUSIC_SYSTEM_BINARY_0; */

void main(argc,argv) 
    int argc; char *argv[]; 
{
    int i,i_dsp;
    DSP_BOOL do_sim = FALSE;	/* if TRUE, write out host-interface file */
    DSP_BOOL do_host_msg = FALSE;
    DSP_BOOL do_mapped = FALSE;
    int kase = 0;		/* for sequencing through test cases */
#define MK_CASE 0
#define MK_INIT_CASE 1		/* CANNOT WORK FOR NEGATIVE NUMBERS */
#if 0
#define CASE_COUNT 2		/* MK_INIT_CASE disabled */
#else
#define CASE_COUNT 1
#endif
    int ver=0,rev=0;
    int dtr,dtw;
    int r_oh,w_oh;
    extern int _DSPVerbose;
    extern int _DSPTrace;
    fprintf(stderr,"Type 'dsptest -u' for usage info.\n");
    while (--argc && **(++argv) == '-') {
	_DSPToLowerStr(++(*argv));
	switch (**argv) {
	case 'k':
	    do_cont=TRUE;	/* -k */
	    break;
	case 'v':
	    /* Now defaults database overrides this */
	    _DSPVerbose=!_DSPVerbose;
	    fprintf(stderr,"*** Must now say 'dwrite MusicKit DSPVerbose 1'\n");
	    break;
	case 'h':		/* -hostMessageMode */
#if 0   /* Host message mode crashes my computer! daj */
	    do_host_msg = TRUE;
	    fprintf(stderr,"Host-Message mode enabled in DSP protocol.\n");
#else
	    fprintf(stderr,"Sorry, host-message mode is disabled.\n");
	    exit(1);
#endif
	    break;
	case 's':
	    do_sim=TRUE;	/* -simulate */
	    break;
	case 'm':
	    do_mapped = TRUE;
	    fprintf(stderr,"Executing DSP tests in MAPPED-ONLY mode.\n");
	    break;
	case 't':		/* -trace n */
	    _DSPTrace = (--argc)? strtol((char *)(*(++argv)),(int)NULL,0) : -1;
	    fprintf(stderr,"*** Must now say 'dwrite MusicKit DSPTrace 1'\n");
	    break;
	case 'l':		/* load special monitor <name> */
	    --argc;
	    if (argc) 
	      strcpy(monitorPath,(char *)*(++argv));
	    else fprintf(stderr,"Monitor file name missing.\n");
	    break;
	case 'c':		/* -case n */
	    kase = (--argc)? strtol((char *)(*(++argv)),(int)NULL,0) : -1;
	    if (kase<0)
	      kase = 0;
	    if (kase >= CASE_COUNT)
	      kase = CASE_COUNT-1;
	    fprintf(stderr,"Initial case set to 0x%X.\n",(unsigned int)kase);
	    break;
	case 'x':		/* -xpandedMemory memorySizeInWords */
	    memory_expansion = 
		(--argc)? strtol((char *)(*(++argv)),(int)NULL,0) : -1;
	    if (memory_expansion<0)
		memory_expansion = 32;
	    switch(memory_expansion) {
	    case 0:
	    case 32:
		fprintf(stderr,"Assuming 32K external memory from NeXT.\n");
		break;
	    case 8:
		fprintf(stderr,"Assuming 8K memory.\n");
		break;
	    case 192:
		fprintf(stderr,"Assuming 192K external memory from UCSF.\n");
		break;
	    default:
		fprintf(stderr,"*** Unsupported DSP memory expansion size: "
			"%d K words\n", memory_expansion);
		break;
	    }
	    break;
	case 'd':		/* -dma */
	    do_dma = TRUE;
	    fprintf(stderr,"Using DMA for 16-bit and 8-bit transfers.\n");
	    break;
	case 'p':		/* -programmedIO */
	    do_pio = TRUE;
	    fprintf(stderr,"Using programmed i/o instead of DMA.\n");
	    break;
	case 'n':		/* -numberDSP <n> */
	    dsp_number = (--argc)? strtol((char *)(*(++argv)),(int)NULL,0) : -1;
	    fprintf(stderr,"Trying only DSP #%d.\n",dsp_number);
	    break;
	case 'w':		/* -wait */
	    hangit = 1;
	    fprintf(stderr,"Hanging DSP before boot and tests\n");
	    break;
	case 'u':		/* usage */
	    fprintf(stderr,"Usage: dsptest [-wkvsmtlcxdpnw]\n"
		    "  k = Run test continuously.\n"
		    "  v = Verbose mode.\n"
		    "  h = Enable host messsage mode in DSP protocol (disabled).\n"
		    "  s = Simulate\n"
		    "  m = Mapped-only mode.\n"
		    "  t <val> = Set trace to specified value.\n"
		    "  l <fileName> = Load special monitor.\n"
		    "  c <num> = Initial case (disabled).\n"
		    "  x = Expanded memory assumed (NeXT 32K word SIMM).\n"
		    "  x <size> = Assume expanded memory, <size> k words.\n"
		    "  d = Use DMA for 16 and 8-bit transfers.\n"
		    "  p = Use programmed i/o instead of DMA.\n"
		    "  n <dspNum> = Try only specified DSP (0-based).\n"
		    "  w = Wait before booting (for debugging NeXTbus devices).\n");
	    exit(0);
	    break;
	default:
	    fprintf(stderr,"Unknown switch -%s\n",*argv);
	    exit(1);
	}
    }

#if i386
    {
	int i,cnt = DSPGetDSPCount();
	int validDSPs = 0;
	int *units = DSPGetInUseDriverUnits();
	char **driverNames = DSPGetInUseDriverNames();
	fprintf(stderr,"\nRequested DSPs:\n");
	for (i=0; i<cnt; i++) 
	  if (driverNames[i]) {
	      fprintf(stderr,"   DSP %d == %s%d\n",i,driverNames[i],units[i]);
	      validDSPs++;
	  }
	printf("Number of DSPs found = %d:\n",validDSPs);
    }


#else

    printf("Number of DSPs found = %d:\n",DSPGetDSPCount());

#endif

    if (_DSPTrace)
	fprintf(stderr,"_DSPTrace set to 0x%X.\n",(unsigned int)_DSPTrace);

    if (_DSPVerbose)
	fprintf(stderr,"_DSPVerbose set to 0x%X.\n",(unsigned int)_DSPVerbose);

    /* *** NEED THIS TO GET ERROR MESSAGES ***	DSPEnableHostMsg(); */
    
    if (hangit)
      printf("Hanging . . .\n");
    while (hangit) {
	;
    }

    i_dsp =  (dsp_number<0 ? 0 : dsp_number);
 loop:
    printf("\nDSP %d:\n",i_dsp);

	for(kase = 0; kase < CASE_COUNT; kase++) {

	    if (DSPSetCurrentDSP(i_dsp))
	      test_fail("Could not set current DSP");

	    if (strlen(monitorPath) == 0) { /* Added 11/4/94/jos */
#if m68k
	    if (memory_expansion == 0) {
	        int ec = DSPSenseMem(&memory_expansion);
		if (ec == SND_ERR_CANNOT_ACCESS)
		    test_fail("Could not access DSP - "
			"perhaps another program has it.");
		else if (ec)
		    test_fail("Could not determine DSP memory configuration");
	    }
	    switch(memory_expansion) {
	    case DSP_8K:
		fprintf(stderr,"Found no external DSP memory expansion.\n");
		strcpy(monitorPath, DSP_MUSIC_SYSTEM_BINARY_0);
		break;
	    case DSP_32K:
		fprintf(stderr,"Found 32K external DSP memory expansion.\n");
		strcpy(monitorPath, DSP_32K_MUSIC_SYSTEM_BINARY_0);
		break;
	    case DSP_64K:
		strcpy(monitorPath, DSP_192K_MUSIC_SYSTEM_BINARY_0);
		fprintf(stderr,"Found 192K external memory from UCSF.\n");
		break;
	    default:
		fprintf(stderr,"*** Unsupported DSP memory expansion size: "
			"Highest address = 0x%x\n", memory_expansion);
		break;
	    }
#endif
#if i386
	    {
		char *driverName = (DSPGetInUseDriverNames())[i_dsp];
		int unit = (DSPGetInUseDriverUnits())[i_dsp];
		char *mon;
		if (!driverName) {
		    if (dsp_number >= 0)
		      exit(0);
		    if (i_dsp < DSPGetDSPCount())  {
			fprintf(stderr,"No DSP at %d\n",i_dsp);
			i_dsp++;
			goto loop;
		    }
		    else exit(0);
		}
		DSPSetCurrentDSP(i_dsp);
		mon = DSPGetDriverParameter(DSPDRIVER_PAR_MONITOR);
		fprintf(stderr,"Driver=%s, unit=%d\n",driverName,unit);
		if (mon) {
		    fprintf(stderr,"Using monitor %s.\n",mon);
		    strcpy(monitorPath, mon);
		} else {
		    fprintf(stderr,"No driver parameter found. Using default monitor.\n");
		    strcpy(monitorPath, DSP_MUSIC_SYSTEM_BINARY_0);
		}
		memory_expansion = DSP_8K;
	    }
#endif
	    }
	    if (do_sim)
	      if(DSPErrorNo=DSPOpenSimulatorFile(DSPCat("dsptest_dsp",
							DSPCat(_DSPCVS(i_dsp),
							       ".io"))))
		test_fail("Could not open simulator output file:dsptest.io");
	
	    if (_DSPVerbose)
	      DSPEnableErrorFile("/dev/tty"); 
	    
	    if (do_host_msg)
	      DSPEnableHostMsg();
	    
	    if (do_mapped)
	      DSPEnableMappedOnly();
	    
	    if (do_pio)
	      DSPEnableDmaReadWrite(0,0);
	    
	    if (do_dma)
	      DSPEnableDmaReadWrite(1,1);
	    
	    if (kase==MK_CASE) {
		fprintf(stderr,"Booting DSP with MK monitor\n");
		if (DSPReadFile(&dspSystem,monitorPath))
		  test_fail("DSPReadFile() failed for music system.");
	    } else if (kase==MK_INIT_CASE) {
		fprintf(stderr,
			"Booting DSP with MK monitor in Host Message mode\n");
		if (DSPReadFile(&dspSystem,monitorPath))
		  test_fail("DSPReadFile() failed for music system.");
		DSPEnableHostMsg();
	    } else exit(0);
	    
	    if (DSPBoot(dspSystem))
	      test_fail("Can't get the DSP or boot failed.");
	    
	    if(DSPCheckVersion(&ver,&rev))
	      test_fail("DSPCheckVersion() test failed.");
	    else
	      fprintf(stderr,"DSP %d is running system %d.0(%d).\n",
		      DSPGetCurrentDSP(),ver,rev);
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++) 
		arr1[i] = (i+100);
	    
#if 1
	    
	    /* --- Internal X memory test --- */
	    
	    fprintf(stderr,"Unit internal X memory test [x:%d#1]\n",DSP_XLI_USR);
	    
	    if (DSPWriteIntArray(arr1,DSP_MS_X,DSP_XLI_USR,1,1))
	      test_fail("Could not write internal X memory");
	    
	    DSPGetHostTime();
	    if (DSPWriteIntArray(arr1,DSP_MS_X,DSP_XLI_USR,1,1))
	      test_fail("Could not write internal X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    w_oh = DSPGetHostTime();
	    
	    if (DSPReadIntArray(arr2,DSP_MS_X,DSP_XLI_USR,1,1))
	      test_fail("Could not read internal X memory");
	    
	    DSPGetHostTime();
	    if (DSPReadIntArray(arr2,DSP_MS_X,DSP_XLI_USR,1,1))
	      test_fail("Could not read internal X memory");
	    r_oh = DSPGetHostTime();
	    
	    check_readback(1);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      " \t DSPWriteIntArray overhead time is %d microseconds\n",
		      w_oh);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t  DSPReadIntArray overhead time is %d microseconds\n",r_oh);
	    
	    fprintf(stderr,"Internal X memory test [x:%d#%d]\n",
		    DSP_XLI_USR,DSP_NXI_USR);
	    
	    if (DSPWriteIntArray(arr1,DSP_MS_X,DSP_XLI_USR,1,DSP_NXI_USR))
	      test_fail("Could not write internal X memory");
	    
	    if (DSPReadIntArray(arr2,DSP_MS_X,DSP_XLI_USR,1,DSP_NXI_USR))
	      test_fail("Could not read internal X memory");
	    
	    check_readback(DSP_NXI_USR);
	    
	    /* --- External X memory test --- */
	    
	    fprintf(stderr,"External X memory test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    DSPGetHostTime();
	    if (DSPWriteIntArray(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    DSPGetHostTime();
	    if (DSPReadIntArray(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    dtr = DSPGetHostTime();
	    
	    check_readback(DSP_NXE_USR);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWriteIntArray rate is %d kBytes per second\n",
		      DSP_NXE_USR,3*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadIntArray rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtr);
	    
	    /* --- External X memory float test --- */
	    
	    fprintf(stderr,"External X memory float test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    DSPGetHostTime();
	    if (DSPWriteFloatArray(farr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    DSPGetHostTime();
	    if (DSPReadFloatArray(farr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    dtr = DSPGetHostTime();
	    
	    fcheck_readback(DSP_NXE_USR);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWriteFloatArray rate is "
		      "%d kBytes per second\n",
		      DSP_NXE_USR,3*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadFloatArray rate is "
		      "%d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtr);
	    
	    /* --- External X memory double test --- */
	    
	    fprintf(stderr,"External X memory double test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    DSPGetHostTime();
	    if (DSPWriteDoubleArray(darr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    DSPGetHostTime();
	    if (DSPReadDoubleArray(darr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    dtr = DSPGetHostTime();
	    
	    dcheck_readback(DSP_NXE_USR);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWriteDoubleArray rate is "
		      "%d kBytes per second\n",
		      DSP_NXE_USR,3*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadDoubleArray rate is "
		      "%d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtr);
	    
	    if (memory_expansion != DSP_8K) {
		
		/* --- Expanded External X memory test --- */
		
#define XRAM_LXE_USR 16384
#define XRAM_HXE_USR 32767
#define XRAM_NXE_USR (XRAM_HXE_USR - XRAM_LXE_USR + 1)
		
		fprintf(stderr,"Expanded external X memory test [x:%d#%d]\n",
			XRAM_LXE_USR,XRAM_HXE_USR);
		
		DSPGetHostTime();
		if (DSPWriteIntArray(arr1,DSP_MS_X,XRAM_LXE_USR,1,XRAM_NXE_USR))
		  test_fail("Could not write external X memory");
		if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
		  fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
		dtw = DSPGetHostTime();
		
		DSPGetHostTime();
		if (DSPReadIntArray(arr2,DSP_MS_X,XRAM_LXE_USR,1,XRAM_NXE_USR))
		  test_fail("Could not read external X memory");
		dtr = DSPGetHostTime();
		
		check_readback(XRAM_NXE_USR);
		
		if (_DSPVerbose)
		  fprintf(stderr,
			  "\t Length %d DSPWriteIntArray rate is %d kBytes per second\n",
			  XRAM_NXE_USR,
			  3*1000*XRAM_NXE_USR/dtw);
		
		if (_DSPVerbose)
		  fprintf(stderr,
			  "\t Length %d DSPReadIntArray rate is %d kBytes per second\n",
			  XRAM_NXE_USR,
			  3*1000*XRAM_NXE_USR/dtr);
		
#define XRAM_LXE_HOLE 512
#define XRAM_HXE_HOLE 8191
#define XRAM_NXE_HOLE (XRAM_HXE_HOLE - XRAM_LXE_HOLE + 1)
		
		fprintf(stderr,"Expanded external X memory test 2 [x:%d#%d]\n",
			XRAM_LXE_HOLE,XRAM_HXE_HOLE);
		
		DSPGetHostTime();
		if (DSPWriteIntArray(arr1,DSP_MS_X,XRAM_LXE_HOLE,1,XRAM_NXE_HOLE))
		  test_fail("Could not write external X memory");
		if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
		  fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
		dtw = DSPGetHostTime();
		
		DSPGetHostTime();
		if (DSPReadIntArray(arr2,DSP_MS_X,XRAM_LXE_HOLE,1,XRAM_NXE_HOLE))
		  test_fail("Could not read external X memory");
		dtr = DSPGetHostTime();
		
		check_readback(XRAM_NXE_HOLE);
		
		if (_DSPVerbose)
		  fprintf(stderr,
			  "\t Length %d DSPWriteIntArray rate is %d kBytes per second\n",
			  XRAM_NXE_HOLE,
			  3*1000*XRAM_NXE_HOLE/dtw);
		
		if (_DSPVerbose)
		  fprintf(stderr,
			  "\t Length %d DSPReadIntArray rate is %d kBytes per second\n",
			  XRAM_NXE_HOLE,
			  3*1000*XRAM_NXE_HOLE/dtr);
		
		if (i_dsp==0)  {
		    /* --- Expanded External XY partition test (spot check) --- */
		    
#define XRAM_LXE_USG 32768
#define XRAM_HXE_USG XRAM_LXE_USG+8192
#define XRAM_NXE_USG (XRAM_HXE_USG - XRAM_LXE_USG + 1)
		    
#define XRAM_LYE_USG 32768
#define XRAM_HYE_USG XRAM_LYE_USG+8192
#define XRAM_NYE_USG (XRAM_HYE_USG - XRAM_LYE_USG + 1)
		    
		    fprintf(stderr,
			    "Expanded external X/Y partitioned memory test "
			    "[x:%d#%d] [y:%d#%d]\n",
			    XRAM_LXE_USG,XRAM_NXE_USG, XRAM_LYE_USG,XRAM_NYE_USG);
		    
		    if (DSPWriteIntArray(arr1,DSP_MS_X,XRAM_LXE_USG,1,XRAM_NXE_USG))
		      test_fail("Could not write external X memory partitioned segment");
		    
		    if (DSPWriteIntArray(arr1+XRAM_NXE_USG,DSP_MS_Y,XRAM_LYE_USG,1,
					 XRAM_NYE_USG))
		      test_fail("Could not write external Y memory partitioned segment");
		    
		    if (DSPReadIntArray(arr2,DSP_MS_X,XRAM_LXE_USG,1,XRAM_NXE_USG))
		      test_fail("Could not read external X memory partitioned segment");;
		    
		    if (DSPReadIntArray(arr2+XRAM_NXE_USG,DSP_MS_Y,XRAM_LYE_USG,1,
					XRAM_NYE_USG))
		      test_fail("Could not read external Y memory partitioned segment");;
		    
		    check_readback(XRAM_NXE_USG+XRAM_NYE_USG);
		    
		}
	    }
	    
	    
	    /* --- Internal Y memory test --- */
	    
	    fprintf(stderr,"Internal Y memory test [y:%d#%d]\n",
		    DSP_YLI_USR,DSP_NYI_USR);
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++) arr1[i] &= 0xFFFFFF; /* no sign ext */
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_Y,DSP_YLI_USR,1,DSP_NYI_USR))
	      test_fail("Could not write internal Y memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_Y,DSP_YLI_USR,1,DSP_NYI_USR))
	      test_fail("Could not read internal Y memory");
	    
	    check_readback(DSP_NYI_USR);
	    
	    /* --- External Y memory test --- */
	    
	    fprintf(stderr,"External Y memory test [y:%d#%d]\n",
		    DSP_YLE_USR,DSP_NYE_USR);
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_Y,DSP_YLE_USR,1,DSP_NYE_USR))
	      test_fail("Could not write external Y memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_Y,DSP_YLE_USR,1,DSP_NYE_USR))
	      test_fail("Could not read external Y memory");
	    
	    check_readback(DSP_NYE_USR);
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++) arr1[i] = (i-2048) & 0xFFFFFF;
	    
	    /* --- External Y memory test, left-justified 1 --- */
	    
	    fprintf(stderr,"External left-justified 1 X memory test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory left-justified 1");
	    
	    if (DSPReadFix24ArrayLJ(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory left-justified 1");
	    
	    if (1) { 
		int cnt = DSP_NXE_USR;
		for (i=0;i<cnt;i++) arr1[i] <<= 8;
	    }
	    
	    check_readback(DSP_NXE_USR);
	    
	    
	    /* --- External X memory test, left-justified 2 --- */
	    
	    /* Array 1 is left-justified... send it that way */
	    
	    fprintf(stderr,"External left-justified 2 X memory test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWriteFix24ArrayLJ(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory left-justified 2");
	    
	    if (DSPReadFix24ArrayLJ(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory left-justified 2");
	    
	    check_readback(DSP_NXE_USR);
	    
	    /* restore to RJ, no sign */
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++) arr1[i] = (i-2048) & 0xFFFFFF;
	    
	    /* --- Internal P memory test --- */
	    
	    fprintf(stderr,"Internal P memory test [p:%d#%d]\n",
		    DSP_PLI_USR,DSP_NPI_USR);
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_P,DSP_PLI_USR,1,DSP_NPI_USR))
	      test_fail("could not write internal P memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_P,DSP_PLI_USR,1,DSP_NPI_USR))
	      test_fail("could not read internal P memory");
	    
	    check_readback(DSP_NPI_USR);
	    
	    
	    /* --- External P memory test --- */
	    
	    fprintf(stderr,"External P memory test [p:%d#%d]\n",
		    DSP_PLE_USR,DSP_NPE_USR);
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_P,DSP_PLE_USR,1,DSP_NPE_USR))
	      test_fail("could not write external P memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_P,DSP_PLE_USR,1,DSP_NPE_USR))
	      test_fail("could not read external P memory");
	    
	    check_readback(DSP_NPE_USR);
	    
#if 0
	    External partitioned memory no longer supported as of release 5.0

	    /* --- External partitioned X memory test --- */
	    
	    if (i_dsp==0)  {

		fprintf(stderr,
			"External X/Y partitioned memory test [x:%d#%d] [y:%d#%d]\n",
			DSP_XLE_USG,DSP_NXE_USG, DSP_YLE_USG,DSP_NYE_USG);
		
		if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USG,1,DSP_NXE_USG))
		  test_fail("Could not write external X memory partitioned segment");
		
		if (DSPWriteFix24Array(arr1+DSP_NXE_USG,DSP_MS_Y,DSP_YLE_USG,1,
				       DSP_NYE_USG))
		  test_fail("Could not write external Y memory partitioned segment");
		
		if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USG,1,DSP_NXE_USG))
		  test_fail("Could not read external X memory partitioned segment");;
		
		if (DSPReadFix24Array(arr2+DSP_NXE_USG,DSP_MS_Y,DSP_YLE_USG,1,
				      DSP_NYE_USG))
		  test_fail("Could not read external Y memory partitioned segment");;
		
		check_readback(DSP_NXE_USG+DSP_NYE_USG);
		
		if (DSP_NXE_USG==0)
		  fprintf(stderr,"*** NOTE *** X/Y partition test is meaningless because\n"
			  "\tthe loaded DSP system completely fills the user X partition\n");
		
	    }
#endif

#endif
	    
#ifdef DO_FENCE_POSTS

#define DSP_DEF_BUFSIZE	512 // default #words in each buf (from snd_msgs.h)
	    
	    /* --- magic sizes test --- */
	    
	    if(DSP_XLE_USR < DSP_DEF_BUFSIZE) {
		fprintf(stderr,"Default DSP buffer size = %d while external DSP AP "
			"memory room = %d.\n Aborting.\n",
			DSP_DEF_BUFSIZE,DSP_XLE_USR);
		exit(1);
	    }
	    
	    /* 513 */
	    
	    fprintf(stderr,"Fence-post buffer-size test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_DEF_BUFSIZE+1); /* already did singleton */
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_DEF_BUFSIZE+1))
	      test_fail("Could not write external X memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_DEF_BUFSIZE+1))
	      test_fail("Could not read external X memory");
	    
	    check_readback(DSP_DEF_BUFSIZE+1);
	    
	    
	    /* 512 */
	    
	    fprintf(stderr,"Fence-post buffer-size test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_DEF_BUFSIZE); /* already did singleton */
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_DEF_BUFSIZE))
	      test_fail("Could not write external X memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_DEF_BUFSIZE))
	      test_fail("Could not read external X memory");
	    
	    check_readback(DSP_DEF_BUFSIZE);
	    
	    
	    /* 1025 */
	    
	    fprintf(stderr,"Fence-post buffer-size test [x:%d#%d]\n",
		    DSP_XLE_USR,2*DSP_DEF_BUFSIZE+1); /* already did singleton */
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,2*DSP_DEF_BUFSIZE+1))
	      test_fail("Could not write external X memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,2*DSP_DEF_BUFSIZE+1))
	      test_fail("Could not read external X memory");
	    
	    check_readback(2*DSP_DEF_BUFSIZE+1);
	    
	    
	    /* 1024 */
	    
	    fprintf(stderr,"Fence-post buffer-size test [x:%d#%d]\n",
		    DSP_XLE_USR,2*DSP_DEF_BUFSIZE); /* already did singleton */
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,2*DSP_DEF_BUFSIZE))
	      test_fail("Could not write external X memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,2*DSP_DEF_BUFSIZE))
	      test_fail("Could not read external X memory");
	    
	    check_readback(2*DSP_DEF_BUFSIZE);
	    
	    
	    fprintf(stderr,"Fence-post buffer-size test [x:%d#%d]\n",
		    DSP_XLE_USR,3*DSP_DEF_BUFSIZE); /* already did singleton */
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,3*DSP_DEF_BUFSIZE))
	      test_fail("Could not write external X memory");
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,3*DSP_DEF_BUFSIZE))
	      test_fail("Could not read external X memory");
	    
	    check_readback(3*DSP_DEF_BUFSIZE);
	    
#endif
	    
	    /* --- External X memory UNPACKED 24-BIT TRANSFER test --- */
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++)
	      arr1[i] = i & 0xFFFFFF;
	    
	    fprintf(stderr,"External X memory unpacked 24-bit transfer test "
		    "[x:%d#%d]\n", DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    
	    DSPGetHostTime();
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    
	    DSPGetHostTime();
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    dtr = DSPGetHostTime();
	    
	    check_readback(DSP_NXE_USR);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWriteFix24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadFix24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtr);
	    
	    
	    /* --- External X memory PACKED 24-BIT TRANSFER test --- */
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++)
	      arr1[i] = rand();
	    
	    fprintf(stderr,"External X memory packed 24-bit transfer test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWritePackedArray((unsigned char *)arr1,
				    DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    
	    DSPGetHostTime();
	    if (DSPWritePackedArray((unsigned char *)arr1,
				    DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    if (DSPReadPackedArray((unsigned char *)arr2,
				   DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    
	    DSPGetHostTime();
	    if (DSPReadPackedArray((unsigned char *)arr2,
				   DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    dtr = DSPGetHostTime();
	    
	    check_readback(DSP_NXE_USR*3/4);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWritePacked24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadPacked24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtr);
	    
	    
	    /*** Non-32-bit-mode tests ***/
	    
	    /* +++ Fill test array with random bits +++ */
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++)
	      arr1[i] = ((i<<1) << 16) | ((i<<1)+1);
	    /*      arr1[i] = rand(); */
	    
	    
	    /* --- External X memory PACKED 16-BIT TRANSFER test --- */
	    
	    fprintf(stderr,"External X memory packed 16-bit mode test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWriteShortArray((short *)arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write 16-bit data to external X memory");
	    
	    DSPGetHostTime();
	    if (DSPWriteShortArray((short *)arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write 16-bit data to external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    if (DSPReadShortArray((short *)arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read 16-bit data from external X memory");
	    
	    DSPGetHostTime();
	    if (DSPReadShortArray((short *)arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read 16-bit data from external X memory");
	    dtr = DSPGetHostTime();
	    
	    check_readback(DSP_NXE_USR/2); /* shorts */
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWriteShortArray rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      2*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadShortArray rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      2*1000*DSP_NXE_USR/dtr);
	    
	    /* --- External X memory PACKED 8-BIT TRANSFER test --- */
	    
	    
	    fprintf(stderr,"External X memory packed 8-bit mode test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWriteByteArray((unsigned char *)arr1,
				  DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write 8-bit data to external X memory");
	    
	    DSPGetHostTime();
	    if (DSPWriteByteArray((unsigned char *)arr1,
				  DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write 8-bit data to external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    if (DSPReadByteArray((unsigned char *)arr2,
				 DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read 8-bit data from external X memory");
	    
	    DSPGetHostTime();
	    if (DSPReadByteArray((unsigned char *)arr2,
				 DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read 8-bit data from external X memory");
	    dtr = DSPGetHostTime();
	    
	    check_readback(DSP_NXE_USR/4); /* bytes */
	    
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWriteByteArray rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      1*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadByteArray rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      1*1000*DSP_NXE_USR/dtr);
	    
#ifndef TEMPORARY_DRIVER_TEST
	    
	    /* --- External X memory UNPACKED 24-BIT TRANSFER test --- */
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++)
	      arr1[i] = i & 0xFFFFFF;
	    
	    fprintf(stderr,"External X memory unpacked 24-bit transfer test "
		    "[x:%d#%d]\n", DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    
	    DSPGetHostTime();
	    if (DSPWriteFix24Array(arr1,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    
	    DSPGetHostTime();
	    if (DSPReadFix24Array(arr2,DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    dtr = DSPGetHostTime();
	    
	    check_readback(DSP_NXE_USR);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWriteFix24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadFix24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtr);
	    
	    
	    /* --- External X memory PACKED 24-BIT TRANSFER test --- */
	    
	    for (i=0;i<DSP_EXT_RAM_SIZE_MAX;i++)
	      arr1[i] = rand();
	    
	    fprintf(stderr,"External X memory packed 24-bit transfer test [x:%d#%d]\n",
		    DSP_XLE_USR,DSP_NXE_USR);
	    
	    if (DSPWritePackedArray((unsigned char *)arr1,
				    DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    
	    DSPGetHostTime();
	    if (DSPWritePackedArray((unsigned char *)arr1,
				    DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not write external X memory");
	    if(DSPAwaitTRDY(10000)) /* instantly true... returns after write */
	      fprintf(stderr,"*** DSPAwaitTRDY() failed!\n");
	    dtw = DSPGetHostTime();
	    
	    if (DSPReadPackedArray((unsigned char *)arr2,
				   DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    
	    DSPGetHostTime();
	    if (DSPReadPackedArray((unsigned char *)arr2,
				   DSP_MS_X,DSP_XLE_USR,1,DSP_NXE_USR))
	      test_fail("Could not read external X memory");
	    dtr = DSPGetHostTime();
	    
	    check_readback(DSP_NXE_USR*3/4);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPWritePacked24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtw);
	    
	    if (_DSPVerbose)
	      fprintf(stderr,
		      "\t Length %d DSPReadPacked24Array rate is %d kBytes per second\n",
		      DSP_NXE_USR,
		      3*1000*DSP_NXE_USR/dtr);
	    
#endif
	    
	    DSPClose();
	    
	    fprintf(stderr,"-------------------\n");
	}
    if (dsp_number < 0) {
	i_dsp++;
	if (i_dsp < DSPGetDSPCount())
	  goto loop;
    }
}

