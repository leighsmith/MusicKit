/* Modification History:
 *
 * daj Oct 8, 93 - Added thread check
 */

/* included by DSPObject.c */
/* [Part of] QpLoLvls.c [Adapted to NeXT libdsp by Julius Smith 7/5/91] */

#if 0
/* Available procedures */
static DSP_BOOL reset_processor56(int type); /* resets the DSP(s)  */
static DSP_BOOL dspExists(int dspNum); /*returns DSP_TRUE if a DSP exists*/
static DSPRegs *getRegsPointer(int dspNum);
static unsigned masterSetup(void); /* [Hacked by JOS to remove monitor load] */
static DSP_BOOL setCurrDsp(int dspNum); 
static int boardVersion(void);
static DSP_BOOL setupOneDspOnly(int slot, int dsp); /* Resets single DSP */
#endif

/*  Interface library for QuintProcessor boards */

/**********************************************************************
 *                     Ariel Corp                                     *
 *                     433 River Road                                 *	
 *                     Highland Park, NJ 08904                        *
 *                     (C) Copyright 1990                             *
 **********************************************************************
 
 **********************************************************************
 *                     C source code  ver 1.1 10 Dec 90               *
 **********************************************************************
 **********************************************************************
 *                     C source code  ver 1.2 29 Jan 91               *
 **********************************************************************
 
 the changes to ver 1.1 were made necessary due to the '040 upgrade.
 They require a 'Bus' chip with the ID = 0x8000.
 
 1.2 changes added functions to support the reserved/simult bits (writes)
 and the HI/HOST flags register (reads). - DAJ
*/

/*this module handles the lowest-level DSP interface*/

/* 
 * IMPORTANT  -- to run GDB through the masterSetup() and/or setupDSPs() fns
 * you need to run these commands or put them in .gdbinit
 *
 * handle 10 nostop noprint
 * handle 11 nostop noprint
 */

/* #import "QP.h" */
/* --------------------------------- QP.h -----------------------------------*/
/* QP.H [partial]
 */

/*
  #define DEBUG 0
  */

/*standard booleans*/
#ifndef  OBJC_INCL
#define  OBJC_INCL
#endif

#ifndef YES
#define YES 1
#endif 

#ifndef NO
#define NO 0
#endif

#ifndef NULL
#define NULL 0
#endif

#define ON 1
#define OFF 0
#define BOT 0
#define TOP 1
#define LEFT 0
#define RIGHT 1
#define DOWN 0
#define UP 1
#define NORMAL 1
#define UNUSUAL 0


/*Shorthand for certain types <note: 68030 ints = longs>
  unsigned 8, 16, and 32-bit quantities*/
#define UI unsigned int
#define US unsigned short
#define UC unsigned char
#define UL unsigned long

typedef struct _Di { /*sum total of all info for a processor*/
    int valid;   /*if the DSP is really there.*/
    DSPRegs *dspregs; /*pointer to its host port*/
}Di;

#define NODSP (-1) /* Added by DAJ */
/*DSPs enumerations for access to dsp info structs*/
#define CPUDSP 0
/*DSPSmDn, where m = slot 2,4,6 and n = dsp# 0..4 on a board*/
#define DSPS2D0 1
#define DSPS2D1 2
#define DSPS2D2 3
#define DSPS2D3 4
#define DSPS2D4 5
#define DSPS4D0 6
#define DSPS4D1 7
#define DSPS4D2 8
#define DSPS4D3 9
#define DSPS4D4 10
#define DSPS6D0 11
#define DSPS6D1 12
#define DSPS6D2 13
#define DSPS6D3 14
#define DSPS6D4 15

#if 0 /* DAJ */
/*OR masks for selecting individual DSPs*/
#define  DSP0 0x08
#define  DSP1 0x10
#define  DSP2 0x20
#define  DSP3 0x40
#define  DSP4 0x80

/*OR masks for selecting misc resources*/
#define RESERVED_SIMULT 0x100
#define RST_NMI 0x200
#define RD_HOSTREQ 0x800
#define RD_HI 0xC00

#else

#define RESERVED_SIMULT 0x403
#define RST_NMI 0x803
#define RD_HI 0x2000
#define RD_HOSTREQ 0x3000

#endif

/*for QP_RstNmi(int dsp, int resetIt)*/
#define DO_RESET 1
#define DO_NMI 0

/*define maximum number of dsps*/
#define MAXDSPS 16

/*defs for reset_processor56() */
#define LLRESET_ALL 0
#define LLRESET_CURR 1
#define LLRESET_BOARD 2

/* ----------------------------- end QP.h -----------------------------------*/

#import <stdlib.h>
#import <sys/file.h>
#include <sys/ioctl.h>
#include <string.h>
#include <sys/fcntl.h>
#include <sys/stat.h>
#include <sys/errno.h>

/* #include "ndslot.h" */
/* ------------------------------ ndslot.h ---------------------------------
 * HISTORY
 * 27-May-89  Avadis Tevanian, Jr. (avie) at NeXT, Inc.
 *	Created.
 */

#ifndef	_SLOT_H_
#define	_SLOT_H_

#define SLOTSIZE	0x10000000		/* each physical slot is
						   really two of these */
#define SSLOTSIZE	0x01000000
#define SSLOTBASE	0xF0000000

#define SLOTCOUNT	4

#define	SLOTIOCGADDR	_IOR('s', 0, int)	/* get address of slot space */
#define	SLOTIOCGADDR_CI	_IOR('s', 1, int)	/* address of slot space, cache off */
#define	SLOTIOCDISABLE	_IO('s', 3)		/* disable translation */
#define	SLOTIOCSTOFWD	_IO('s', 4)		/* Enable NBIC store/forward */
#define	SLOTIOCNOSTOFWD	_IO('s', 5)		/* Disable NBIC store/forward */

/*
 * The following two ioctls take a packed pair of 8 bit address/mask fields
 * to be loaded into TT1, and return the user process address holding the
 * mapped address ranges.
 */
#define	SLOTIOCMAPGADDR	_IOWR('s', 6, int)	   /* map and get addr */
#define	SLOTIOCMAPGADDR_CI	_IOWR('s', 7, int) /* map and get addr, cache off */

/*
 * Form a packed address/mask value from a pair of 32 bit address/mask values.
 */
#define FORM_MAPGADDR(addr,mask)	((((addr)>>16)&0xFF00)|(((mask)>>24)&0xFF))
#ifdef KERNEL
#define UNPACK_ADDR(val)		((((val)>>8)&0xFF)<<24)
#define UNPACK_MASK(val)		((val)&0xFF)
#endif /* KERNEL */
#endif	/* _SLOT_H_  */
/* -------------------------- end ndslot.h ---------------------------------*/

#include <signal.h>
#include <setjmp.h>
#include <libc.h>

/*current Mfg ID for the QP board*/
#if 0 /* DAJ */
#define QP_ID 0x8001
#else
#define QP_ID 0x80018000
#endif

static int CheckSlotStatusAndOpen(char *name);
static int getBdId(unsigned *bdId );
static int setDspRecord(int which); 
static void alignSlotOffsets(int which);
static char const *getDriverName(int dspNum);
static void thud(int sig);
static int BoardIdForSlot[3]; /* element 0 for slot 2, 1 for slot 4, 2 for 6 */

static int dspFd = -1;
static char *slotBase; /*need to keep the base address of the slot for QPs*/
static jmp_buf	Whoops;
static unsigned dspBitVector;

/* storage for arrays to Di structures (see QP.h) */
static Di *proc[16]; /*0 is CPU's DSP, then slots 2,4,6. 
		       If no board or no DSP then
		       an element is NULL (0). Otherwise, 
		       the element is a pointer to a _Di struct.
		       */

/*accessible outside this module, but private to DSPObject.c */
static Di *_di;  /*pointer to current Di struct: private*/
/* (not used, was private) static UL _LLtimeout = 400000; */
static DSPRegs *_dspregs; /*private*/

static int me = -1;		/*the current DSP, range from 1..15*/
				/*(DSP0 is CPU board DSP, unused herein).*/

#define HF1_ON 0x10
#define HF1_OFF 0xEF

static void _hf1_on(void) /* set HF1 */
{
    UI icr;
    
    icr = _dspregs->icr;	/*get current state of ICR register*/
    _dspregs->icr = icr | HF1_ON; /*write it back with bit 4 (HF1) set*/
}

static void _hf1_off(void) /* clear HF1 */
{
    unsigned int icr;
    
    icr = _dspregs->icr;	/*get current state of ICR register*/
    _dspregs->icr = icr & HF1_OFF; /*write it back with bit 4 (HF1) clr*/
}

static DSP_BOOL if_hf1(void)
{
    return (_dspregs->icr & HF1_ON);
}

/* QP_RstNmi(dsp,resetIt)
   resets or NMIs a DSP.  Assumes slotBase has valid mapping.  If resetIt
   is DSP_TRUE then we reset the affected DSP.  IF resetIt is DSP_FALSE then we NMI
   the affected DSP.  If resetIt is DSP_TRUE and dsp == -1 then we reset all DSPs.
   The reset operation asserts then deasserts the reset bits at the QP control
   reg.  returns 0 for success, NZ for bus or seg errors.
   
   The DSP number is 0..4, the 'me' variable can't be used!  To map 'me' to
   this fn. subtract 1 then use the mod 5 remainder as the 'dsp' param.
   
   For example: DSP11 is the DSPA on a Qp in slot 6.  Subtract one to account
   for the CPU's DSP.  Divide by 5 and the mod 5 remainer is zero (DSP A).
   
   Note that it's up to the caller to be sure that the DSP to be reset or NMId
   is on a mapped-in board!
   
   */
static int QP_RstNmi(int dsp, int resetIt)
{
    void (*old_SIGBUS)();
    void (*old_SIGSEGV)();
    char val;
//    extern void usleep (unsigned int useconds);  
//    /*not in libc.h where it belongs? */
    
    old_SIGBUS = signal( SIGBUS, thud );
    old_SIGSEGV = signal( SIGSEGV, thud );
    
    if ( setjmp(Whoops) != 0 )
    {
	(void) signal( SIGBUS, old_SIGBUS );
	(void) signal( SIGSEGV, old_SIGSEGV );
	return(1);
    }
    
    if(resetIt)  /*handle resets*/
    {
	if(dsp == -1) /*all*/
	  val = 7;
	else
	  val = 7 | ~(1 << (dsp+3));  /* the '7 | ' is redundant, I think. */
	
	*((unsigned char volatile *)(slotBase+RST_NMI)) = val; 
	/* keeps NMIs off*/
	
	usleep(10000); /*wait for 10000 usec (10 msec)*/
	
	*((unsigned char volatile *)(slotBase+RST_NMI)) = 0xFF;  
	/*all resets go OFF*/
    }
    else if(dsp != -1) /*handle NMIs*/
    {
	val = 0xF8 | dsp; /*0xF8 ensures no resets occur*/
	*((unsigned char volatile *)(slotBase+RST_NMI)) = val;
    }
    
    (void) signal( SIGBUS, old_SIGBUS );
    (void) signal( SIGSEGV, old_SIGSEGV );
    return(0); /*success*/
}


/*
  CheckSlotStatusAndOpen(name)
  Checks to see if a particular device exists, specifically for
  "/dev/slot2",
  "/dev/slot4",
  "/dev/slot6",
  "/dev/slots2",
  "/dev/slots4",
  "/dev/slots6"
  Also checks that its a char device and that it's the updated driver from
  BusProbe.
  
  returns DSP_TRUE for success, DSP_FALSE for any error except if there's no NBIC, in
  which case -1 is returned.  -2 is returned if the 'new' driver is not
  found.
  
  IMPORTANT: If there's no error then the driver is left open and the base of
  the slot or slot space address in in slotBase.
  */
static int CheckSlotStatusAndOpen(char *name)
{
    struct stat stbuf;
    
    /* make sure its a character special device.*/
    if ( stat( name, &stbuf) == -1 )
      return DSP_FALSE;
    if ( (stbuf.st_mode & S_IFCHR) == 0 )
      return DSP_FALSE; 
    
    /* Try and use the new Slot driver*/
    if ( (dspFd = open( name, O_RDWR, 0)) == -1 )
      return DSP_FALSE;	/* No driver whatsoever???\*/
    
    /*see if we can map the address sucessfully (cache inhibited)*/
    if ( ioctl( dspFd, SLOTIOCGADDR_CI, (void *) &slotBase ) == -1 )
    {
	close( dspFd );
	return DSP_FALSE;
    }
    
    /* Try an ioctl in the new driver that's not in the 1.0 version */
    if ( ioctl( dspFd, SLOTIOCNOSTOFWD, (void *) 0 ) == -1 )
    {
	if ( errno == ENXIO )  /*old driver never returns this*/
	{
	    close(dspFd);	/*hence, is new driver but no NBIC*/
	    return(-1);   
	}
	else		/*old driver does not have this ioctl.*/
	{
	    close( dspFd );
	    return -2;	/*is old driver*/
	}
    }
    
    return DSP_TRUE;
}


/*returns the correct device driver name, NULL if dspNum not in range 0..15.*/
static char const * getDriverName(int dspNum) 
{
    if(dspNum==CPUDSP)
      return(NULL);
    else if((dspNum >= DSPS2D0) && (dspNum <= DSPS2D4))
      return("/dev/slot2");
    else if((dspNum >= DSPS4D0) && (dspNum <= DSPS4D4))
      return("/dev/slot4");
    else if((dspNum >= DSPS6D0) && (dspNum <= DSPS6D4))
      return("/dev/slot6");
    else
      return(NULL);
}

/* 
 * The following function added by DAJ, Oct. 7, 93, to work around 
 * thread bug.
 */

/* From: Mike_Paquette@NeXT.COM (Mike Paquette)
   Date: Thu, 7 Oct 93 17:00:09 -0700
   To: david@jaffe.com
   Subject: /dev/slot: Confusion beyond belief

   Hi David!

   I knew that mapping hack would bite someone someday.  Hardware is
   being mapped into user space by loading TT2, the 'spare' transparent
   translation register in the 68k.  This register is saved and restored
   in the THREAD state structure.  In order to get your code to work
   correctly, you'll need to

   ioctl( dspFd, SLOTIOCGADDR_CI, (void *) &slotBase );

   in each thread (!).  The open of the device need only be done once.
   This will correctly load TT2 in each thread, granting access to the
   hardware.  There shouldn't be any problem in doing this.  Multiple
   invocations per thread should be harmless, too.

*/

static void checkForRemap(void)
    /* NOTE:  This function may only work for one Quint Processor. 
     * For multiple Processors, we may have to keep a separate thread 
     * list for each Processor
     */
{
    static cthread_t *mappedThreads = NULL;
    static int mappedThreadsCount = 0;
    cthread_t *p;
    int i;
    cthread_t thisThread = cthread_self();
    if (!mappedThreadsCount)  {         /* First time? */
	mappedThreads = calloc(mappedThreadsCount = 1,sizeof(cthread_t));
	*mappedThreads = thisThread;
	me = NODSP; /* Force remap */
	return;
    }
    for (i=0, p=mappedThreads; i<mappedThreadsCount; i++) /* Look for us */
      if (thisThread == *p++)
	return;
    me = NODSP; /* Force remap */
    mappedThreads = realloc(mappedThreads,(++mappedThreadsCount * sizeof(cthread_t)));
    mappedThreads[mappedThreadsCount-1] = thisThread;
}

/*
  setCurrDsp(dspNum)
  sets the current DSP. Returns DSP_FALSE if it is not marked present.
  If the new DSP is on a different board, close the current driver and
  open a new one
  */
static DSP_BOOL setCurrDsp(int dspNum) 
{
    char const * drvr;
    
    if(proc[dspNum] == NULL)
      return(DSP_FALSE);
    
    if(proc[dspNum]->valid == DSP_FALSE)
      return(DSP_FALSE);
    
    checkForRemap(); /* Added by DAJ */

    if((me != dspNum) ||  (dspFd == -1)) /* probably true,  
					    see if we need to change drivers */
    {
	if(me == CPUDSP)	/* current DSP was built-in DSP, is error */
	  return(DSP_FALSE);
	
	else
	{
	    if( ((me >= DSPS2D0) && (me <= DSPS2D4)) &&  /*cur DSP was slot 2*/
	       ((dspNum  >= DSPS2D0) && (dspNum  <= DSPS2D4)) ) 
	      /* new DSP still slot 2 */
	      goto arrgh;  /* no need to change drivers */
	    else if( ((me >= DSPS4D0) && (me <= DSPS4D4)) && /*old DSP slot 4*/
		    ((dspNum  >= DSPS4D0) && (dspNum  <= DSPS4D4)) ) 
	      /* new DSP is still slot 4 */
	      goto arrgh;  /*no need to change drivers	  */
	    else if( ((me >= DSPS6D0) && (me <= DSPS6D4)) && /*old DSP slot 6*/
		    ((dspNum  >= DSPS6D0) && (dspNum  <= DSPS6D4)) ) 
	      /* new DSP is still slot 6 */
	      goto arrgh;  /* no need to change drivers */
	    if(dspFd != -1)	    
	    {
		ioctl( dspFd, SLOTIOCDISABLE, (void *) 0); 
		/* shut off address transl. */
		close(dspFd);
	    }
	}
	/* have to open the new driver */
	drvr = getDriverName(dspNum);
	if(drvr == NULL) 
	  return(DSP_FALSE);
	
	dspFd = open(drvr,O_RDWR,0); /*open driver*/
	if(dspFd == -1) /*could not open*/
	  return(DSP_FALSE);
	
	/*note that we open the slot with cache inhibited and storefwd off.   */
	if(ioctl(dspFd, SLOTIOCGADDR_CI, (void *) &slotBase ) == -1 )
	  return(DSP_FALSE);
	if(ioctl(dspFd, SLOTIOCNOSTOFWD, (void *) 0 ) == -1 )
	  return(DSP_FALSE);
	alignSlotOffsets(dspNum); /*set up offsets to individual DSPs*/
    }
 arrgh:
    me = dspNum;
    _di = proc[me];
    _dspregs = _di->dspregs;
    
    return(DSP_TRUE);
}

/* 
  This fn reads the board and mfg Ids from the board that may be in a
  slot.  If it returns non-zero then there was a bus error and there's no
  board. If it returns zero then the Id is returned via *bdId.  We assume an
  open slot driver mapped into slotBase
  
  Note that format is the same as in the NextBus Doc
  
  Mfg code	Board Id
  |<-b31..16->|    |<-b15..0->|
  
  For the QP, the Mfg code is $8001. For the current board rev, the Board ID 
  is also $8001.
  <note: Board ID was changed to $8000 in december 90> - DAJ
  
  */

static int getBdId(unsigned *bdId)
{
    void (*old_SIGBUS)();
    void (*old_SIGSEGV)();
    
    old_SIGBUS = signal( SIGBUS, thud );
    old_SIGSEGV = signal( SIGSEGV, thud );
    
    if ( setjmp(Whoops) != 0 )
    {
	(void) signal( SIGBUS, old_SIGBUS );
	(void) signal( SIGSEGV, old_SIGSEGV );
	return(1);
    }
    /*yeah, this is a dumb way to do this.*/
    *bdId = *((unsigned char volatile *)(slotBase + 0xFFFFF0)); 
    /* msbyte of Mfg Code */
    *bdId <<= 8;
    *bdId |= *((unsigned char volatile *)(slotBase + 0xFFFFF4)); 
    /* lsbyte of Mfg Code */
    *bdId <<= 8;	
    *bdId |= *((unsigned char volatile *)(slotBase + 0xFFFFF8)); 
    /* msbyte of Board ID */
    *bdId <<= 8;	
    *bdId |= *((unsigned char volatile *)(slotBase + 0xFFFFFc)); 
    /* lsbyte of Board ID */
    
    (void) signal( SIGBUS, old_SIGBUS );
    (void) signal( SIGSEGV, old_SIGSEGV );
    return(0); /*success*/
}

static void thud(int sig)
{
    longjmp(Whoops, sig); /* i.e., the caller of getBdId() 
			     gets a nonzero return value. */
}


static int setDspRecord(int which)
{
    Di *di;
    int siz = sizeof(struct _Di); /* done this way for debugging. */
    
    /*
     * allocate space for a DSP info record, init it, and
     * place its pointer into the
     * proc[] array
     */
    
    di = (Di *)mycalloc(1,siz);
    
    if(di == NULL) /*whoops!*/
      return (DSP_FALSE); 
    
    proc[which]=di; /*we have a struct to use.*/
    
    /* init fields as appropriate. 
       Note that they're all zero initially since calloc() used */
    
    di->valid = DSP_TRUE; /*mark this struct as valid*/
    /*init dsp pointer to NULL for safety*/
    di->dspregs = NULL;
    
    return(DSP_TRUE);
}


static void alignSlotOffsets(int which) /*set up offsets to individual DSPs*/
{
    int first,ctr;
    
    if((which >= DSPS2D0) && (which <= DSPS2D4))
      first = DSPS2D0;
    else if((which >= DSPS4D0) && (which <= DSPS4D4))
      first = DSPS4D0;
    else if((which >= DSPS6D0) && (which <= DSPS6D4))
      first = DSPS6D0;
    else /*totally wrong*/
      return;
    
    for(ctr = 0;ctr < 5; ctr++)
    {
	if(proc[first+ctr] == NULL)
	  continue; /* account for DSPs that might have been omitted 
		       from the board */
#if 0 /* DAJ */
	proc[first+ctr]->dspregs = (DSPRegs *)(slotBase + (8<<ctr));    
#else
	proc[first+ctr]->dspregs = (DSPRegs *)(slotBase + (32<<ctr));    
#endif
    }
}


static void slotAndDspFromNum(int dspNum,int *slot, int *dsp)
    /* sets the slot and dsp # into the ptd to vars. CPU DSP is slot0/DSP0 */
{
    if(dspNum == 0)
      *slot = *dsp = 0;
    else if(dspNum < 6)
    {
	*slot = 2;
#if 0 /* DAJ */
	*dsp = me - 1;
#else
	*dsp = dspNum - 1;
#endif
    }
    else if( dspNum >= 6 && dspNum < 11)
    {
	*slot = 4;
#if 0 /* DAJ */
	*dsp = me - 6;
#else 
	*dsp = dspNum - 6;
#endif 
    }
    else
    {
	*slot = 6;
#if 0 /* DAJ */
	*dsp = me - 11;
#else
	*dsp = dspNum - 11;
#endif
    }
}

#if 0 
/* This stuff was added by ARIEL for release 2.0. I don't know if we need it
 * but I'm including it here anywhay, in case. - DAJ */
static void setSimultBit(int on)
{
simultReserved(0,on);
}

static void setReservedBit(int on)
{
simultReserved(1,on);
}

static void simultReserved(BOOL which,int on)
{
static int preserve=0;

on &= 1;

if(which) //changing RESERVED bit.
    {
    preserve &= 2;  //clear bit 0
    preserve |= on; //set bit 0 if 'on' is TRUE
    }
else  //changing SIMULT bit.
    {
    preserve &= 1;  //clear bit 1
    preserve |= on<<1; //set bit 1 if 'on' is TRUE
    }
    
*((unsigned char volatile *)(slotBase+RESERVED_SIMULT)) = preserve;
}
#endif

/*
  setupDSPs()
  
  Logs in all QPs and DSPs that actually exist.  Starts at slot 2 and ends up
  at slot 6.  If a DSP exists then it has an info structure built for it.
  'Grabbing' support ignored at this time.  Big difference is that we don't
  abort if the CPU's DSP is unavailable.
  
  DSPs are enumerated starting at 1.  DSP 0 is reserved for the CPU board's
  DSP and is never marked as present (i.e., proc[0] always = NULL).
  
  May be used as a master reset for all DSPs on all boards. Rebuilds info
  structs, so one should not assume that a DSP exists after this fn is used
  for a master reset (although it probably will exist unless there is a
  hardware error).
  
  Returns DSP_TRUE for success, DSP_FALSE for fatal error (pgm should exit)
  
  Note that this fn does not load monitors or anything to the board.  It
  just determines if DSPs are present.
  
  Affects HF0 and HF1
  */

static DSP_BOOL setupDSPs(void) 
{
    int i;
    static int firstTime = DSP_TRUE;
    unsigned boardId;
    
    dspBitVector = 0;
    
    if(!firstTime)
    {
	/* Check proc[n] for non-null pointers. 
	   Clear 'valid' flags in current processors */
	for(i = 1; i < 15; i++) /*note proc[0] is always ignored.*/
	{
	    if(proc[i] != NULL)
	      proc[i]->valid = NO;
	}
	_di = proc[me];
	/*there has to be an open driver (slot or other) so close it*/
	ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);	
	close(dspFd);
	me = -1; /*not equivalent to any DSP*/
    }
    
    firstTime = DSP_FALSE;
    
    /*
      Now log in the DSPs in slots.  First, see if we have drivers and a 
      local NBIC.  We assume that all 6 slot driver names exist.  Then 
      check for our board ID. I'm doing this inline for all slots for clarity.
      */
    
    /*turn on bus error signal (in case we use this fn to restart)*/
    signal( SIGBUS, SIG_DFL );
    
    i = CheckSlotStatusAndOpen("/dev/slots2");
    if(i != DSP_TRUE)
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	if(i == DSP_FALSE)
	  fprintf(stderr,"System has no QuintProcessor slot driver.\n");	 	else if(i == -1)
	  fprintf(stderr,"QP driver: no NBIC\n");
	else if(i == -2)
	  fprintf(stderr,"QP driver: old slot drivers found, unusable\n");
	return(DSP_FALSE);
    }
    
    /*if slots2 is OK, read the board ID*/
    
    i = getBdId(&boardId);
    ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
    close(dspFd); /*no longer need access to slots2*/
    
    /*shut off bus error signal*/
    signal( SIGBUS, SIG_IGN );
    
    if(i == 0)  /*was able to read board id*/
    {
	BoardIdForSlot[0] = boardId; /*save the board ID */
#if 0 /* DAJ */
	boardId = (boardId >> 16) & 0xFFFF;  /*get rid of the lsword of ID */
	/*(the board ID is not*/
	/*important, only care about the mfg ID right now).*/
#endif
	if(boardId == QP_ID) /*and it was the QP's ID*/
	{ /*check for the DSPs on each board and install info structs*/
	    i = CheckSlotStatusAndOpen("/dev/slot2"); /*try to open slot 2*/
	    /*at return, slot is open, slotBase*/
	    if(i == DSP_TRUE) /* OK. Simple test for DSP existence is to remove 
			     reset from all and then set/clear HF0 */
	    {
		i = QP_RstNmi(-1, DO_RESET); /*returns 0 for success*/
		if(i == 0) /*all DSPs are now un-reset.*/
		{
		    for(i=0;i<5;i++) /*loop thru 5 possible DSPs on board*/
		    {
#if 0 /* DAJ */
			_dspregs = (DSPRegs *)(slotBase + (8<<i));
#else
			_dspregs = (DSPRegs *)(slotBase + (32<<i));
#endif
			_hf1_on(); /*turn HF1 on*/
			if(if_hf1()) /*if it actually is on, maybe have a DSP*/
			{
			    _hf1_off(); /*turn it off*/
			    if(!if_hf1()) /*if it IS off, we have a DSP*/
			    {
				if(proc[1+i] == NULL)
				{
				    if(!setDspRecord(1+i))
				      return(DSP_FALSE);  /*fatal error */
				}
				else proc[1+i]->valid = DSP_TRUE;
			    }
			}
		    }
		}
		ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
		close(dspFd); /*no longer need access to slot2*/
	    }
	}
    } /*that's it for board 2*/
    
    /*turn on bus error signal*/
    signal( SIGBUS, SIG_DFL );
    
    if(CheckSlotStatusAndOpen("/dev/slots4") != DSP_TRUE) return(DSP_FALSE);
    i =getBdId(&boardId);
    ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
    close(dspFd); /*no longer need access to slots4*/
    
    /*shut off bus error signal*/
    signal( SIGBUS, SIG_IGN );
    
    if(i == 0)  /*was able to read board id*/
    {
	BoardIdForSlot[1] = boardId; /*save the board ID*/
#if 0 /* DAJ */
	boardId = (boardId >> 16) & 0xFFFF;  /*get rid of the lsword of ID */
#endif
	/*(the board ID is not*/
	/*important, only care about the mfg ID right now).*/
	if(boardId == QP_ID) /*and it was the QP's ID*/
	{ /*check for the DSPs on each board and install info structs*/
	    i = CheckSlotStatusAndOpen("/dev/slot4"); /*try to open slot 4*/
	    /*at return, slot is open, slotBase*/
	    if(i == DSP_TRUE) /* OK. Simple test for DSP existence is to remove 
			     reset from all and then set/clear HF0 */
	    {
		i = QP_RstNmi(-1, DO_RESET); /*returns 0 for success*/
		if(i == 0) /*all DSPs are now un-reset.*/
		{
		    for(i=0;i<5;i++) /*loop thru 5 possible DSPs on board*/
		    {
			_dspregs = (DSPRegs *)(slotBase + (32<<i));
			_hf1_on(); /*turn HF1 on*/
			if(if_hf1()) /*if it actually is on, maybe we have a DSP*/
			{
			    _hf1_off(); /*turn it off*/
			    if(!if_hf1()) /*if it IS off, we have a DSP*/
			    {
				if(proc[1+5+i] == NULL)
				{			   
				    if(!setDspRecord(1+5+i))
				      return(DSP_FALSE);  /*fatal error */
				}
				else proc[1+5+i]->valid = DSP_TRUE;
			    }
			}
		    }
		}
		ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
		close(dspFd); /*no longer need access to slot4*/
	    }
	}
    } /*that's it for board 4*/
    
    /*turn on bus error signal*/
    signal( SIGBUS, SIG_DFL );
    
    if(CheckSlotStatusAndOpen("/dev/slots6") != DSP_TRUE) return(DSP_FALSE);
    i =getBdId(&boardId);
    ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
    close(dspFd); /*no longer need access to slots6*/
    
    /*shut off bus error signal*/
    signal( SIGBUS, SIG_IGN );
    
    if(i == 0)  /*was able to read board id*/
    {
	BoardIdForSlot[2] = boardId; /*save the board ID*/
	boardId = (boardId >> 16) & 0xFFFF;  /*get rid of the lsword of the ID */
	/*(the board ID is not*/
	/*important, only care about the mfg ID right now).*/
	if(boardId == QP_ID) /*and it was the QP's ID*/
	{ /*check for the DSPs on each board and install info structs*/
	    i = CheckSlotStatusAndOpen("/dev/slot6"); /*try to open slot 6*/
	    /*at return, slot is open, slotBase*/
	    if(i == DSP_TRUE) /* OK. Simple test for DSP existence is to remove reset from all
			     and then set/clear HF0 */
	    {
		i = QP_RstNmi(-1, DO_RESET); /*returns 0 for success*/
		if(i == 0) /*all DSPs are now un-reset.*/
		{
		    for(i=0;i<5;i++) /*loop thru 5 possible DSPs on board*/
		    {
#if 0 /* DAJ */
			_dspregs = (DSPRegs *)(slotBase + (8<<i));
#else
			_dspregs = (DSPRegs *)(slotBase + (32<<i));
#endif
			_hf1_on(); /*turn HF1 on*/
			if(if_hf1()) /*if it actually is on, maybe we have a DSP*/
			{
			    _hf1_off(); /*turn it off*/
			    if(!if_hf1()) /*if it IS off, we have a DSP*/
			    {
				if(proc[1+5+5+i] == NULL)
				{			    
				    if(!setDspRecord(1+5+5+i))
				      return(DSP_FALSE);  /*fatal error */
				}
				else proc[1+5+5+i]->valid = DSP_TRUE;
			    }
			}
		    }
		}
		ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
		close(dspFd); /*no longer need access to slot6*/
	    }
	}
    } /*that's it for board 6*/
    
    
    /*shut off bus error signal for the rest of the program*/
    signal( SIGBUS, SIG_IGN );
    dspFd = -1; /*indicates that there is no open slot driver right now.*/
    return(DSP_TRUE);
}

/*if type == 0 then do a total reset, 1 = current DSP, 2 = current board*/
/*
  #define LLRESET_ALL 0
  #define LLRESET_CURR 1
  #define LLRESET_BOARD 2
  
  Returns DSP_FALSE if CPU DSP is referenced or if LLRESET_ALL and an error occurs.
  Note that 'total reset' does not reset the CPU's DSP.
  */

static DSP_BOOL reset_processor56(int type) /* resets the DSP(s)  */
{
    int slot,dsp;
    
    if(type == LLRESET_ALL) /*reset everything */
    {
	QP_RstNmi(-1, DO_RESET);
	return(setupDSPs());
    }
    
    slotAndDspFromNum(me,&slot,&dsp); /*slot is just the current slot*/
    if( (slot == 0) || (type == LLRESET_CURR)) 
      /* trap LLRESET_BOARD for CPUDSP @ slot==0 */
    {
	if(slot==0) /*CPU's DSP*/
	  return(DSP_FALSE);
	
	else
	  QP_RstNmi(dsp, DO_RESET);
    }
    else /*reset the current slot*/
      QP_RstNmi(-1, DO_RESET);
    
    return(DSP_TRUE);
}

#if 0
static DSP_BOOL setupOneDspOnly(int slot, int dsp) /* For resetting single DSP */
{
    int i,dspNum;
    unsigned boardId;
    char *dvr,*dvrS;
    
    
    if(slot != 2 && slot != 4 && slot != 6) /*check range for slot*/
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	fprintf(stderr,"\nQP driver: slot # invalid in setupOneDspOnly()\n");
	return(DSP_FALSE);
    }
    
    if(dsp < 0 || dsp > 4) /*check range for dsp*/
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	fprintf(stderr,"\nQP driver: DSP # invalid in setupOneDspOnly()\n");
	return(DSP_FALSE);
    }
    
    switch(slot){ /*determine the base DSP number for a slot*/
    case 2: dspNum = 1; dvr = "/dev/slot2", dvrS = "/dev/slots2"; break;
    case 4: dspNum = 6; dvr = "/dev/slot4", dvrS = "/dev/slots4"; break;
    default: dspNum = 11; dvr = "/dev/slot6", dvrS = "/dev/slots6";
    }
    
    dspNum += dsp;  /*add the offset to the DSP we want to use*/
    
    
    /*check proc[dsp] for a non-null pointer. Clear 'valid' flags if found*/
    if(proc[dspNum] != NULL)
    {
	proc[dspNum]->valid = NO;
	if(dspFd != -1) /*an open driver exists*/
	{
	    ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);	
	    close(dspFd);
	}
	me = -1; /*not equivalent to any DSP*/
    }
    
    /*turn on bus error signal (in case we use this fn to restart)*/
    signal( SIGBUS, SIG_DFL );
    
    /*open slot space*/
    i = CheckSlotStatusAndOpen(dvrS);
    if(i != DSP_TRUE)
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	if(i == DSP_FALSE)
	  fprintf(stderr,"System has no QuintProcessor slot driver.\n");
	else if(i == -1)
	  fprintf(stderr,"QP driver: no NBIC\n");
	else if(i == -2)
	  fprintf(stderr,"QP driver: old slot drivers found, unusable\n");
	return(DSP_FALSE);
    }
    
    i = getBdId(&boardId);
    ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
    close(dspFd); /*no longer need access to slot space*/
    
    /*shut off bus error signal*/
    signal( SIGBUS, SIG_IGN );
    if(i != 0)
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	fprintf(stderr,"\nQP driver: Could not read board ID\n");
	return(DSP_FALSE);
    }
    /*else was able to read board id*/
    BoardIdForSlot[(slot/2)-1] = boardId; /*save the board ID*/
    
#if 0 /* DAJ */
    boardId = (boardId >> 16) & 0xFFFF;  /*get rid of the lsword of the ID */
    /*(the board ID is not*/
    /*important, only care about the mfg ID right now).*/
#endif
    if(boardId != QP_ID) /*error if it wasn't the QP's ID*/
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	fprintf(stderr,"\nQP driver: Board ID incorrect\n");
	return(DSP_FALSE);
    }
    
    i = CheckSlotStatusAndOpen(dvr); /*try to open slot*/
    /*at return, slot is open if i == DSP_TRUE*/
    if(i != DSP_TRUE) /*could not open slot*/
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	fprintf(stderr,"\nQP driver: Could not open slot driver\n");
	return(DSP_FALSE);
    }
    
    i = QP_RstNmi(dsp, DO_RESET); /*returns 0 for success*/
    
    if(i != 0) /*error doing reset*/
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	fprintf(stderr,"\nQP driver: Could not reset the DSP\n");
	return(DSP_FALSE);
    }
    
#if 0 /* DAJ */
    _dspregs = (DSPRegs *)(slotBase + (8<<dsp));
#else
    _dspregs = (DSPRegs *)(slotBase + (32<<dsp));
#endif
    _hf1_on(); /*turn HF1 on*/
    if(if_hf1()) /*if it actually is on, maybe we have a DSP*/
    {
	_hf1_off(); /*turn it off*/
	if(!if_hf1()) /*if it IS off, we have a DSP*/
	{
	    if(proc[dspNum] == NULL)
	    {
		if(!setDspRecord(dspNum))
		{
		    if(!_DSPVerbose) return(DSP_FALSE);
		    fprintf(stderr,"\nQP driver: Could not allocate a DSP info struct\n");
		    return(DSP_FALSE);
		}
		else proc[dspNum]->valid = DSP_TRUE;
	    }
	}
	else
	{
	    if(!_DSPVerbose) return(DSP_FALSE);
	    fprintf(stderr,"\nQP driver: No DSP in this slot\n");
	    return(DSP_FALSE);
	}
    }
    else 
    {
	if(!_DSPVerbose) return(DSP_FALSE);
	fprintf(stderr,"\nQP driver: No DSP in this slot\n");
	return(DSP_FALSE);
    }
    
    ioctl( dspFd, SLOTIOCDISABLE, (void *) 0);
    close(dspFd); /*no longer need access to slot*/
    
    /*shut off bus error signal for the rest of the program*/
    signal( SIGBUS, SIG_IGN );
    dspFd = -1; /*indicates that there is no open slot driver right now.*/
    return(DSP_TRUE);
}

static int boardVersion(void)
{
    int slot,dsp;
    
    slotAndDspFromNum(me,&slot, &dsp);
    
    return(BoardIdForSlot[(slot/2)-1] & 0xFFFF); /*mask out board ID*/
}

#endif

static unsigned masterSetup(void) /* [Hacked by JOS to remove monitor load] */
{
    int i,flag,slot,dsp;
    
    dspBitVector = 0;
    
    if(!setupDSPs())
      return(0);
    
    /*
     * Loop thru all DSPs and prepare dspBitVector.
     */
    
    dspFd = -1; /*sets up things correctly for next call (is also redundant)*/
    for(i=1; i<MAXDSPS ;i++)
    {
	if(setCurrDsp(i)) /*if we have a DSP here*/
	{
	    dspBitVector |= (1 << i);
	    slotAndDspFromNum(me,&slot,&dsp);
	}
    }
    
    if(dspBitVector == 0) 
      return(0);
    
    /* finally, activate the 'lowest' dsp in the set of available DSPs - DAJ */
    for(i=1,flag=DSP_FALSE;i<MAXDSPS;i++)
    {
	if(setCurrDsp(i)) /*if we have a DSP here*/
	{
	    flag = DSP_TRUE;  /*indicate that there is at least one avail dsp*/
	    break;
	}
    }
    
    return(flag ? dspBitVector : 0);
}


static DSP_BOOL dspExists(int dspNum) /*returns DSP_TRUE if a DSP exists*/
{
    return(proc[dspNum] && proc[dspNum]->valid);
}


static DSPRegs *getRegsPointer(int dspNum) 
{
    return proc[dspNum]->dspregs;
}


