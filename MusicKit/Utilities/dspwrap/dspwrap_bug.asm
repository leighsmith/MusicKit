Problem: literal does not set address space type => following address
inherits sticky address space.

*** Need (xaddress) and (yaddress) declarations (and p and l?) ***

To reproduce, change name to readssi.asm in ugsrc, cd to uglib and do:

me /me/P/dsp/ugsrc/lib localhost> MakeUG readssi.asm
dspwrap -t 16 -ug -nodoc -local ../../smsrc -dsploadwrapDir /usr/bin -macroDir .. ../readssi.asm
Local include directory set to ../../smsrc
Local dsploadwrap directory set to /usr/bin
Local macro directory set to ..

 Reading source file:   ../readssi.asm
 Arg template: (prefix)pf(instance)ic(dspace)sout(datum)aout(literal)y(address)abuf(literal)x(address)aptr
dspwrap: ugargnames = [aout,abuf,aptr] 
 Writing main program  :        readssi_x.asm
 DSP linker output file:        readssi_x.lnk ** ALREADY EXISTS **
 Skipping assembly of:  readssi_x.asm
dspwrap: ugargnames = [aout,abuf,aptr] 
 Generating DSP C function from:        readssi_x.lnk
 ========================= dsploadwrap LOG ========================
/usr/bin/dsploadwrap -trace  16 -ug -argtemplate xaxaxa[aout,abuf,aptr]  readssi_x.lnk
dsploadwrap: Appending type chars XA to symbol aout:
                X:readssi_aout                  (GRIXA) = $0
dsploadwrap: Appending type chars XA to symbol abuf:
                Y:readssi_abuf                  (GRIXA) = $0
dsploadwrap: Appending type chars XA to symbol aptr:
                Y:readssi_aptr                  (GRIXA) = $1
...


;;  Copyright 1990 NeXT Computer, Inc.  All rights reserved.
;;  Author - Julius Smith
;;
;;  Modification history
;;  --------------------
;;  03/09/91/jos - created from readticks.asm
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      readssi (UG macro) - read mono SSI signal to patchpoint
;;
;;  SYNOPSIS
;;      readssi pf,ic,sout,aout0,sbuf,abuf0,sptr,aptr0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (arbitrary since only 1 instance)
;;      ic        = instance count (arbitrary since only 1 instance allowed)
;;      sout      = output vector memory space ('x' or 'y')
;;      aout0     = output vector memory address (any patchpoint)
;;      sbuf      = input buffer memory space (*** ONLY 'y' ALLOWED ***)
;;      abuf0     = input buffer start address (any 'y' memory patchpoint)
;;      sptr      = input pointer memory space (*** ONLY 'x' ALLOWED ***)
;;      aptr0     = input pointer address (set to X_SSIWP from mkmon)
;;
;;  DSP MEMORY ARGUMENTS
;;      Access         Description              Initialization
;;      ------         -----------              --------------
;;      x:(R_X)+       Output address           aout0
;;      y:(R_Y)+       Buffer address           abuf0
;;
;;  DESCRIPTION
;;      
;;      The readssi unit-generator writes a patchpoint from data coming
;;	in on the Synchronous Serial Interface (SSI) port of the DSP.
;;	In addition to the output patchpoint, a second 'y' patchpoint is
;;	supplied to serve as a buffer.  The readssi unit generator
;;	blocks until a full "tick" has been read from the SSI port
;;	to the buffer.  The buffer is copied into the output and the
;;	UG resets the buffer pointer and falls through. This process
;;	is then repeated.
;;
;;	The SSI port is turned on automatically if necessary.
;;
;;	The buffer must be in 'y' memory because the standard ssi_rcv
;;	interrupt handler that comes with the Music Kit DSP Monitor is
;;	used to field SSI interrupts.  This handler is wired to place
;;	the SSI word into a 'y' memory buffer.
;;      
;;      For best performance, the the output patchpoint should be 'x' memory.
;;
;;      In pseudo-C notation:
;;
;;      aout = x:(R_X)+;
;;      abuf = y:(R_Y)+;
;;      aptr = y:(R_Y)+;
;;
;;	if (ssi_not_enabled)
;;		readssi_init();
;;
;;	while(y:(sptr:aptr) != abuf+I_NTICK)
;;		; /* wait for SSI interrupts to fill buffer */
;;	sptr:aptr = abuf; /* reset buffer */
;;
;;      for (n=0;n<I_NTICK;n++)
;;           sout:aout[n] = sbuf:abuf[n];
;;
;;  DSPWRAP ARGUMENT INFO
;;      readssi (prefix)pf,(instance)ic,
;;         (dspace)sout,aout,
;;         (literal)y,(address)abuf
;;         (literal)x,(address)aptr
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/readssi.asm
;;
;;  ALU REGISTER USE
;;      Y1 = start address of input buffer
;;      Y0 = last address of input buffer
;;       B = temporary register for output signal, read pointer
;;
readssi macro pf,ic,sout,aout0,sbuf,abuf0,sptr,aptr0
	new_xarg "readssi_",aout,aout0   ; output address arg
	new_yarg "readssi_",abuf,abuf0   ; start-address arg
	new_yarg "readssi_",aptr,aptr0   ; pointer-address arg

	if "sbuf"!='y'
		fail 'SSI buffer must be in y memory space'
	endif

	if "sptr"!='x'
		fail 'SSI write-pointer must be stored in x memory space'
	endif

	move x:(R_X)+,R_O       ; output address to R_O
	move y:(R_Y)+,R_I1      ; read pointer to R_I1, update on exit
	move #I_NTICK,N_I1

	jsclr #7,x:M_PCC,readssi_init	; SSI rcv data pin

	lua (R_I1)+N_I1,R_I2	; last write-pointer value
	move R_I2,X0		;   used for comparison with SSIWP
	move y:(R_Y)+,R_I2	; X_SSIWP = SSI write pointer
	nop
readssi_block
	move x:(R_I2),B		; pointer to next word to be written by SSI
	cmp X0,B
	jne readssi_block
	move R_I1,x:(R_I2)	; reset SSI write pointer
	move sbuf:(R_I1)+,B	; rev up pipe
	do #I_NTICK,readssi_tickloop
	  if "sout"=="sbuf"
	    move B,sout:(R_O)+
	    move sbuf:(R_I1)+,B
	  else
	    move sbuf:(R_I1)+,B 	B,sout:(R_O)+
	  endif
readssi_tickloop    
     endm

readssi_init
;
;	The following must be done by the caller via
;		DSPMKEnableSSISoundOut();
;
;	bset #B__SSI_RD_ENABLE,x:X_DMASTAT	; turn on "SSI read data"
;
	move y:(R_Y),R_I2	; X_SSIWP = SSI write pointer
	nop
	move R_I1,x:(R_I2)	; reset it to start of buffer
;
; 	Start SSI port.
; 	See /usr/local/lib/dsp/smsrc/jsrlib.asm(setup_ssi_sound)
;
cra_init equ	$4100   ; SSI Control Register A
crb_init equ    $0a00	; SSI Control Register B
pcc_init equ    $1e0	; Port C Control Register 
	movep	#cra_init,x:M_CRA	; Set up SSI serial port
	movep	#crb_init,x:M_CRB	; 	in network mode
	movep   #pcc_init,x:M_PCC	; Enable SSI peripheral
	rts
