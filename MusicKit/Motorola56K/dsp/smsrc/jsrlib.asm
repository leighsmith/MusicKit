; jsrlib.asm - system subroutines - included by allocsys.asm
;
;; Copyright 1989, NeXT Inc.
;; Author - J.O. Smith.  
;;
;; SSI and QuintProcessor support by D. Jaffe., Copyright 1993, CCRMA, 
;; Stanford U.
;;
;; Modification history:
;; 03/21/90/jos - deleted extra jsset #B__TZM_PENDING,.. at service_write_data1
;; 03/21/90/jos - added "jsset #B__TZM_PENDING,.." at st_buz_lwm
;;		  A TZM while blocking on TMQ empty gave deadlock.
;; 03/21/90/jos - added "jsset #B__ABORTING,.." at st_buz_lwm
;; 03/21/90/jos - Also broke block at st_buz_tm on aborting and cleared TZM.
;; 06/20/90/jos - Added di_read for DSP-initiated read requests
;; 08/21/90/jos - Cleaned up abort_now cruft since driver fixed
;; 07/16/91/jos - Added hm_system_tick_updates to end of mkmon-only section
;; 11/29/92/jos - Removed support of DEGMON_TRACER_LOC which was never used
;;  2/11/93/daj - Added support for DSP serial port
;;  2/14/93/daj - Changed clear_tick and 1/2 srate support
;;  7/12/95/daj - Support for Frankenstein box

system_magic dc SYS_MAGIC	; sentinel word checked to detect clobberage
SKIP_DSP_A	EQU 0

;
; **************** ROUTINES CALLED BY BOTH APMON AND MKMON *******************
;

; ============================================================================
; unwritten_subr - force break on execution of nonexistent routine
unwritten_subr	    ; force break on execution of nonexistent routine
		    move #DE_ILLSUB,X0	; illegal subroutine
		    movec ssh,A1	; location of error detection
		    jsr stderr		; report
		    rts

; ================================================================
; dspmsg.asm - enqueue a DSP message for the host or read-mapped user
;
;; ARGUMENTS:
;;   X0 = message opcode, left-justified
;;   A1 = message word
;;
;; SIDE EFFECTS
;;   X0 is clobbered
;;
;; DESCRIPTION
;;   Place DSP message word into the DSP Message Queue (DMQ).
;;
;;   Note that Host Transmit Interrupt Enable (HTIE) is always
;;   set (to enable host-transmit-data-empty interrupts) because it's 
;;   faster than testing status and, having been called, we're 
;;   guaranteed to have something to send. The interrupt enable
;;   is cleared by the host-xmt interrupt handler when the DMQ
;;   is empty.
;;
;;   DMQ full is detected by read-pointer = write-pointer.
;;   DMQ empty is detected by read-pointer+1 = write-pointer.
;;
;;   When a DMA transfer is in progress from the DSP to the host,
;;   the HTIE enable is skipped since it is already enabled for the
;;   DMA transfer.  During DMA, the host_xmt vector is overridden,
;;   and dsp messages will resume as soon as the vector is restored.
;;
;;   History
;;      2/26/88 - simulated successfully the boot-up message
;;      3/01/88 - DMQWP was not getting updated properly after write
;;      3/10/88 - deadlocked detected: blocking for host when host locked.
;;      4/10/88 - added register save/restore
;;
     remember 'study effect of dsp-to-host dma on HTIE'
;;
dspmsg_noblock
    ; the following added by DAJ. 
    ; This avoids sending a message if the DMQ is full.
    ; CLOBBERS Y0 and B !!!
	move x:X_DMQWP,Y0   ; DMQ read pointer
	move x:X_DMQRP,B    ; DMQ write pointer
	cmp Y0,B		; Check for DMQ full
	jsne dspmsg         ; If it's not full send the message
	rts
dspmsg
	mask_host	      ; Can't let an HTDE interrupt happen now
dspmsg1
	move X1,x:X_DSPMSG_X1
	move B2,x:X_DSPMSG_B2
	move B1,x:X_DSPMSG_B1
	move A1,x:X_DSPMSG_A1
	move B0,x:X_DSPMSG_B0
	move R_O,x:X_DSPMSG_R_O
	move M_O,x:X_DSPMSG_M_O

 	move #>$FFFF,X1     ; 16-bit mask
	and X1,A	    ; ensure only low 16 bits are used (A1 restored)
	or X0,A		    ; install opcode
 	move x:X_DMQRP,X0   ; DMQ read pointer
	move x:X_DMQWP,B    ; DMQ write pointer
	cmp X0,B  B1,R_O    ; Check for DMQ overflow, DMQWP to R_O
	move #NB_DMQ-1,M_O  ; modulo
	jne dspmsg2
;
; *** DMQ is full *** Block until host reads a message, unless aborting
;
	        bset #B__DMQ_FULL,y:Y_RUNSTAT 		; enter full state
	        jset #B__DMQ_LOSE,y:Y_RUNSTAT,dspmsg2	; ok to lose messages
;DAJ	        jset #B__SIM,y:Y_RUNSTAT,dspmsg2	; simulator
		jsset #B__ABORTING,y:Y_RUNSTAT,abort_now ; abrt => can't block
		lua (R_O)+,R_O		; read ptr points one behind current
dm_buzz		jclr #1,x:$ffe9,dm_buzz	; wait for HTDE in HSR
		move R_O,x:X_DMQRP	; Update incremented DMQRP
		movep y:(R_O)-,x:$FFEB  ; Write HTX, point to new input cell
		bclr #B__DMQ_FULL,y:Y_RUNSTAT ; exit full state
dspmsg2
;
; *** Insert message into DMQ ***
;
	  move A1,y:(R_O)+    ; install word ("move A" will not work)
	  move R_O,x:X_DMQWP  ; update DMQ write pointer

;*	  unmask_host	        ; restore interrupt priority mask (pop SR)
	  ; Since dspmsgs could be called at interrupt level (e.g. by hmlib)
	  ; we can't invoke unmask_host (which doesn't keep a nesting count).
	  ; Therefore, we let the rti below take care of restoring sr.

	  jset #B__DM_OFF,x:X_DMASTAT,dmpathoff
;
;	The DM_OFF bit of the run status register is set whenever
;	DSP messages have been turned off.
;	Operation in this case is to inhibit the turning on of HTIE.
;
	  bset #1,x:$FFE8     ; Set Host Transmit Intrpt Enable (HTIE) in HCR
;	  <zap>		      ; HTDE interrupt happens here.
dmpathoff
	move x:X_DSPMSG_X1,X1
	move x:X_DSPMSG_B2,B2
	move x:X_DSPMSG_B1,B1
	move x:X_DSPMSG_B0,B0
	move x:X_DSPMSG_A1,A1
	move x:X_DSPMSG_R_O,R_O
	move x:X_DSPMSG_M_O,M_O

        rti
	nop ; this is here just to shield breakpoints on stderr (prefetch)

; =============================================================================

send_long ; send out a 48-bit value in 3 messages
	  move #DM_LONG2,X1		; Long 2 message code
	  tfr X1,B  #DM_LONG1,X1	; Long 1 message code
	  move X1,B0 
	  move #DM_LONG0,X0	        ; Long 0 message code

send_long_1
	  move Y0,A			; low-order word to send
	  jsr dspmsg			; deliver lower 16 bits (X0 ready)

	  move #>@pow(2,-16),X1		; 16-bit right-shift multiplier
	  mpy X1,Y0,A	#>$FF,X1	; low-order 8 bits of middle
	  and X1,A			; bare low byte
	  tfr Y1,A A1,Y0		; upper half to A, low byte to Y0
	  and X1,A			; bare low byte
	  move A1,X0			; low byte back around
	  move #>@pow(2,-16),X1		; Byte-shift-left multiplier
	  mpy X1,X0,A			; upper byte of middle status chunk
	  move A0,A1			; add 24 to -16 in effect
	  or Y0,A	B0,X0		; or in low byte of middle
	  jsr dspmsg			; deliver the message

	  move #>@pow(2,-8),X1		; shift right one byte
	  mpy Y1,X1,A	B1,X0		; upper half
	  jsr dspmsg			; deliver the message

	rts

; ================================================================
; di_read - DSP-initiated read
;
; USAGE
;   Set x:X_DMA1_R_S to memory space of destination address (x=1,y=2,p=4)
;   Set x:X_DMA1_R_R to address of first word of transfer
;   Set x:X_DMA1_R_N to skip factor (e.g. 1 means contiguous locations)
;   Set x:X_DMA1_R_M to desired addressing mode (M address register)
;   move #>1,X0
;   jsr di_read
;
; ARGUMENTS
;   X0 = channel number (zero = user-initiated channel, 1-16 for DSP-init)
;   Currently, as of 6/20/90, only channel 1 should occur here.
;
; CLOBBERS
;   X0,A
;
di_read
	tfr X0,A #DM_HOST_R_SET1,X0	; HOST_R setup word 1
	jsr dspmsg			; enqueue read request
	rts
; =============================================================================

;**FIXME if AP_MON
; Need to generate constant in dsp_memory_map.h for AP library.
; How best to handle this? 
;
; ********************** ROUTINES CALLED BY APMON ONLY ************************
;
; ================================================================
; main_done - entered via "jmp" when an array proc main program ends
	; Inform host that AP program finished and return to idle loop.
main_done1
	bclr #M_HF3,x:M_HCR	; Clear HF3 = "AP Busy" flag in AP mode
				;   Allows polling of busy status
	clr A #DM_MAIN_DONE,X0  ; "main program done" message
	jsr dspmsg		;   Provides interrupt for host on main done.
	clear_sp		; set stack pointer to base value (misc.asm)
	move #0,sr		; clear status register
	jmp idle_1		; jump to idle loop without DM_IDLE message

;**FIXME  endif ; AP_MON

; =============================================================================
; stderr - send a standard dsp error message = error code + status and info
;
; ARGUMENTS
;    X0		= left-justified 8-bit error code (dspmsgs.asm)
;    A1		= additional info (low-order 2 bytes sent)
;
; EXAMPLE CALL
;    move #DE_ERRORCODE,X0
;    move bad_result,A #DE_ERRORCODE,X0
;    jsr stderr
;
stderr	  
	jsr dspmsg		; deliver the error message
	if SYS_DEBUG
	  jsr abort		; debug system halts awaiting Bug56
	else
	  rts			; release system presses on
	endif
;
; ********************** ROUTINES CALLED BY MKMON ONLY ************************
;
	if !AP_MON

; ================================================================

	  if SYS_DEBUG
send_time_with_error
	  move #DE_TIME2,X1		; Time 2 message code
	  tfr X1,B  #DE_TIME1,X1	; Time 1 message code
	  move X1,B0 
	  move #DE_TIME0,X0	        ; Time 0 message code
	  move l:L_TICK,Y		; Current tick long
	  jmp send_long_1
	  endif ; SYS_DEBUG

; ================================================================
start_host_write_data	      ; set up dma sound-out to host
	  bset #B__HOST_WD_ENABLE,x:X_DMASTAT ; enable host WD service
	  rts
; ================================================================
stop_host_write_data	      ; cease dma sound-out to host
	  bclr #B__HOST_WD_ENABLE,x:X_DMASTAT ; disable host WD service
	  rts
; ================================================================
stop_ssi_write_data	 ; cease sound output to ssi port.
	  bclr #B__SSI_WD_ENABLE,x:X_DMASTAT  ; disable ssi out service
	  bclr #B__SSI_WD_RUNNING,x:X_DMASTAT ; indicate need for ptr reset
 	  bclr #M_STE,x:<<M_CRB	      	      ; clear TE  in SSI control register B
	  bclr #M_STIE,x:<<M_CRB	      ; clear TIE in SSI control register B
	  rts
; ================================================================
  if QP_SAT
stop_hub_write_data	 ; cease sound output to hub.
	  bclr #B__IPS_ENABLE,y:Y_DEVSTAT     ; disable hub out service
	  bclr #B__IPS_RUNNING,y:Y_DEVSTAT    ; indicate need for ptr reset
          bclr #3,x:$FFFF                     ; disable irqb (level-sensitive)
	  rts
  endif
; ================================================================
  if QP_HUB
stop_sat_read_data	      	
    bclr  #B__IPS_ENABLE,y:Y_DEVSTAT 
    rts
  endif
; ================================================================
stop_ssi_read_data	 ; cease sound output to ssi port.
	  bclr #B__SSI_RD_ENABLE,x:X_DMASTAT  ; disable ssi out service
	  bclr #B__SSI_RD_RUNNING,x:X_DMASTAT ; indicate need for ptr reset
 	  bclr #M_SRE,x:<<M_CRB	      	      ; clear TE  in SSI control register B
	  bclr #M_SRIE,x:<<M_CRB	      ; clear TIE in SSI control register B
	  rts
; ================================================================
;; setup_ssi_sound - turn on SSI serial port for 16-bit sound input or output
;; Note that you must call DSPMKSetupSerialPort().  setup_ssi_sound just
;; sets the real-time bit.
setup_ssi_sound
	bset  #B__REALTIME,y:Y_RUNSTAT ; SSI is a real time device
      if MOTO_EVM
	jsr init_codec
      endif
	rts

; ================================================================
; start_ssi_write_data - set up sound output to ssi port.
;;
;; DESCRIPTION
;;   Start write-data output to the synchronous serial interface (SSI).
;;   Write-data is sound output from the DSP.  SSI output is assumed to
;;   go to something like the MetaResearch "Digital Ears".
;;   With little or no modification, this handler can be used to connect
;;   any serial audio device using the 44.1KHz, serial format 
;;   used internally by Sony in their CD players, etc.
;;
;;   After calling this routine, the SSI port is set up but not running.
;;   It will be turned on by write_data_buffer_out when a buffer is actually
;;   ready to go. 
;;
;;   start_ssi_write_data and start_ssi_read_data may be called in any order.
;;   Thus, the ssi registers must be programmed using individual bit 
;;   manipulations. (Or we could AND and OR with the right things.)
;;
start_ssi_write_data	      	; set up sound output to ssi port.
    bset  #B__SSI_WD_ENABLE,x:X_DMASTAT ; enable ssi out in DMA status
    remember 'consider zeroing write data buffers when starting WD'
    remember 'What happens if SSI WD turned on at a random time?'
    jsr setup_wd_ptrs           ; set up pointers (we need to do this here
				; because SKIP factors may have changed since boot)
    jsr setup_ssi_sound	        ; start up SSI in 16-bit sound mode
    rts
; ================================================================
  if QP_SAT
start_hub_write_data	      	; set up sound output to ssi port.
    bset  #B__IPS_ENABLE,y:Y_DEVSTAT ; enable hub write data
    jsr setup_wd_ptrs           ; set up pointers (we need to do this here
				; because SKIP factors may have changed since boot)
    rts
  endif
; ================================================================
  if QP_HUB
start_sat_read_data	      	
    bset  #B__IPS_ENABLE,y:Y_DEVSTAT 
    jsr setup_hub_rd_ptrs       ; set up pointers (we need to do this here
				; because SKIP factors may have changed since boot)
    rts
  endif
; ================================================================
; start_ssi_read_data - set up sound input from ssi serial port.
;;
;; DESCRIPTION
;;   Start read-data input from the synchronous serial interface (SSI).
start_ssi_read_data	 	; set up sound input to ssi port.
     bset  #B__SSI_RD_ENABLE,x:X_DMASTAT ; enable ssi input in DMA status
     remember 'consider zeroing read data buffers when starting RD'
     jsr setup_rd_ptrs          ; set up pointers (we need to do this here
				; because SKIP factors may have changed since boot)
     jsr setup_ssi_sound	; start up SSI in 16-bit sound mode
     rts

; ================================================================
; wd_buffer_clear - zero out write-data buffers
; called by hmlib:wd_host_on0 and clear_dma_ptrs below
wd_buffer_clear
;DAJ	jset #B__SIM,y:Y_RUNSTAT,wdbc_loop
	move #YB_DMA_W,R_I1	; beginning of write-data double-buffer ring
	clr A #>NB_DMA_W,B	; total size of both buffers (cf. sys_ye.asm)
	tst B			; zero is disastrous (and MAY OCCUR)
	jle wdbc_loop
	do B,wdbc_loop	; largest immediate DO count is 12 bits, so use B
	  move A,y:(R_I1)+
wdbc_loop
	rts
; ================================================================
; rd_buffer_clear - zero out read-data buffers
; called by hmlib:rd_host_on0 and clear_dma_ptrs below
rd_buffer_clear
	if SSI_READ_DATA        ; was READ_DATA-DAJ
;DAJ	jset #B__SIM,y:Y_RUNSTAT,rdbc_loop
	move #YB_DMA_R,R_I1	; beginning of read-data double-buffer ring
	clr A #>NB_DMA_R,B	; total size of both buffers (cf. sys_ye.asm)
	tst B			; zero is disastrous (and MAY OCCUR)
	jle rdbc_loop
	do B,rdbc_loop	; largest immediate DO count is 12 bits, so use B
	  move A,y:(R_I1)+
rdbc_loop
	rts
	else
	   jsr unwritten_subr
	endif ; READ_DATA
; =============================================================================
; setup_wd_ptrs - set up the initial values of X_DMA_WFB, X_DMA_WFP, X_DMA_WFN,
;	       and DMA_WEB.  This is called from clear_dma_ptrs
;	       and start_ssi_write_data
  if QP_HUB
setup_hub_rd_ptrs
  endif
setup_wd_ptrs
	       ; We have to really set up WFN correctly.  
	       ; Otherwise, switch_write_data will get invoked prematurely,
	       ; messing up ssi read data pointer progress (we don't maintain
               ; a RFN--we rely on REP and WFP being in synch)
	       move #>YB_DMA_W,A0   ; Write DMA buffer, 1st half
	       move A0,x:X_DMA_WFB  ; Start of initial "write-filling" buffer
	       move A0,x:X_DMA_WFP  ; Corresponding "write-filling" pointer
	       move x:X_O_SFRAME_W,Y0 ; This is 4 for AD64x, 2 otherwise
				    ; For up-sampling output, this is twice as big.
		; Explanation of output variables.
		;
		; O_SFRAME_W = output sample frame write increment
		; 		This is the size of a sample frame
		;		as the orchestra loop sees it.
		; O_SFRAME_R = output sample frame read increment
		; 		This is the size of a sample frame
		;		as the external hardware device sees it.
		;
		; If the two are equal, there is no half-sampling going on.
		; If O_SFRAME_R = O_SFRAME_W/2 then the orchestra is running
		; at half the output sampling rate.
		;
		; O_CHAN_OFFSET = this is the output channel offset.
		; 		It is the number of samples to advance from
		;		the first channel's sample to get to the second
		;		channel's sample.  It is used by Out1bUG and Out2sum
		;		It is always equal to I_SFRAME_R/num_chans 
		;
	       move #>(I_NTICK/2),X1  ; Samples per tick
	       ; /2 because we are multiplying a fractional number by 
	       ; a non-fractional number.  Hence, there's a sign bit missing
	       ; that ends up contributing a factor of 2.  So we pre-divide by 2.
	       ; The DSP is using a fractional multiply, and you can think of the 
	       ; one-bit left-shift in the result as coming from the fact that the 
	       ; low-order product has no sign bit.
	       mac Y0,X1,A          ; DMA_WFN = (I_NTICK) * O_SFRAME_W + YB_DMA_W
	       move A0,x:X_DMA_WFN  ; Corresponding "write-fill-next" pointer
	       move #>YB_DMA_W2,X0  ; Write DMA buffer, 2nd half
 	if QP_HUB
	       mpy Y0,X1,B X0,x:X_DMA_WEB  ; Start of initial "write-emptying" buffer
	       move B0,x:X_SAT_R_INCR  ; This is used to step pointers along.
	       move x:X_SAT1_REB,A     ; This is set by the Orchestra
	       move #>(NB_DMA_W/2),X0  ; Compute SAT1_RFB
	       add X0,A A1,x:X_SAT1_REP ; Copy to REP init value		      
	       add X0,A A1,x:X_SAT1_RFB
	       move A1,x:X_SAT2_REB
	       add X0,A A1,x:X_SAT2_REP
	       add X0,A A1,x:X_SAT2_RFB
	       move A1,x:X_SAT3_REB
	       add X0,A A1,x:X_SAT3_REP
	       add X0,A A1,x:X_SAT3_RFB
	       move A1,x:X_SAT4_REB
	       add X0,A A1,x:X_SAT4_REP
	       move A1,x:X_SAT4_RFB
	else
	       move X0,x:X_DMA_WEB  ; Start of initial "write-emptying" buffer
	endif
	       rts
; =============================================================================
; setup_rd_ptrs  - set up the initial values of X_SSI_REB, X_SSI_REP, X_SSI_RFB,
;	       X_IN_INCR, etc.  This is called from clear_dma_ptrs
;	       and start_ssi_read_data
setup_rd_ptrs
		if SSI_READ_DATA    ; Was if READ_DATA--DAJ
		move #>YB_DMA_R,X1  ; Read DMA buffer, 1st half
		; We start things up as follows:
		; REB (and REP) is the first half of the buffer and 
		; RFB is the second half of the buffer.
		; But we don't turn on read data until write_data_buffer_switch,
		; i.e. until In1a has read the first half of the buffer (which is
		; garbage.)
		; At that point, we switch the buffers so that REB is the second
		; half and RFB is the first half.  We initialize R_IO2 to
		; write to the first half (RFB) and In1a reads the second half
		; (REB).  
		move X1,x:X_SSI_REB ; Current "read-emptying" buffer
		move X1,x:X_SSI_REP ; Current "read-emptying" pointer
		; Explanation of input variables.
		;
		; I_SFRAME_R = input sample frame read increment
		; 		This is the size of a sample frame
		;		as the orchestra loop sees it.
		; I_SFRAME_W = input sample frame write increment
		; 		This is the size of a sample frame
		;		as the external hardware device sees it.
		;
		; If the two are equal, there is no half-sampling going on.
		; If I_SFRAME_W = I_SFRAME_R/2 then the orchestra is running
		; at half the input sampling rate.
		;
		; I_CHAN_OFFSET = this is the input channel offset.
		; 		It is the number of samples to advance from
		;		the first channel's sample to get to the second
		;		channel's sample.  It is used by In1bUG.
		;		It is always equal to I_SFRAME_R/num_chans 
		;
		; REP always points to the first sample frame and jumps by
		; sample frames. REN always points to the next tick's first 
		; sample frame.
		;
		; But some devices which use I_SFRAME_W != 1, such as the AD64x, 
		; are "little endian", which is what we call when data comes in as
		; (<skipped sample(s)>,sample,<skipped sample(s)>,sample). 
		; The little endian compensation is made in read_data_buffer_in
		;
	        move #>(I_NTICK/2),Y1 ; Compute input buff tick size
	        ; /2 because we are multiplying a fractional number by 
	        ; a non-fractional number.  
	        move x:X_I_SFRAME_R,Y0 
	        mpy Y0,Y1,A         ; Tick size * skip  
		move A0,x:X_IN_INCR ; Used in service_write_data1
		move A0,A1	     
 		add X1,A	    ; SSI_REB + IN_INCR
		move A,x:X_SSI_REN  ; Next value of SSI_REP
		move #>YB_DMA_R2,X0 ; Read DMA buffer, 2nd half
		move X0,x:X_SSI_RFB ; Start of initial "read-filling" buffer

		endif ; READ_DATA
		rts   
; =============================================================================
; clear_dma_ptrs - init dma buffer state to the turned off and clear condition
;	      dma buffers are not zeroed. This should be done dynamically.
;	      Called in reset_boot.asm and in hmlib_mk.asm
;
clear_dma_ptrs move #0,X0	   ; 0 => no active DMA (cf. sys_xe.asm)
	       move X0,x:X_DMASTAT ; dma is OFF initially
	       jsr setup_wd_ptrs
	       jsr setup_rd_ptrs
	       rts

;==============================================================================
; service_write_data (dispatched from hmdispatch.asm by 1.0 MK orchloopbegin)
;;
;; DESCRIPTION
;;   Advance write-data fill-pointer and check to see if it's time to 
;;   switch write-data output buffers
;;
service_write_data1
	jclr #B__HALF_SRATE,y:Y_RUNSTAT,swd_no_half_srate
	move x:X_O_SFRAME_R,X1      ; output sample frame read increment
	move x:X_O_CHAN_OFFSET,N_I1 ; channel offset
	move x:X_DMA_WFP,A          ; current position in dma output buffer
	add X1,A A,R_I1		    ; R_I1 is loc of sample being read
	move A,R_O		    ; set R_O to blank half
	add X1,A N_I1,N_O 	    ; prepare A; both get chan offset
	move x:X_O_CHAN_COUNT,N_X   ; use this for chan count
	do #(I_NTICK),_copy_tick  
	  do N_X,_copy_sample_frame
	     move y:(R_I1)+N_I1,B   ; get samp
	     move B,y:(R_O)+N_O     ; put samp
_copy_sample_frame
	  add X1,A A,R_I1	    ; compute R_O, update R_I1
	  add X1,A A,R_O	    ; compute next R_I1, update R_O
_copy_tick

swd_no_half_srate
  if QP_HUB
	jclr #B__IPS_ENABLE,y:Y_DEVSTAT,swd_no_sat_rd
	move x:X_SAT_R_INCR,X1      ; Increment all pointers
	move x:X_SAT1_REP,A	    ; No need to do it modulo because 
	add X1,A 		    ; if there's a buffer change, it'll get
	move A,x:X_SAT1_REP 	    ; 'fixed' by write_data_buffer_out
	move x:X_SAT2_REP,A
	add X1,A 
	move A,x:X_SAT2_REP
	move x:X_SAT3_REP,A
	add X1,A 
	move A,x:X_SAT3_REP
	move x:X_SAT4_REP,A
	add X1,A 
	move A,x:X_SAT4_REP
swd_no_sat_rd
  endif
	move x:X_DMA_WFN,X0	   ; Next dma write-fill pointer (out.asm)
	move X0,x:X_DMA_WFP	   ; Make it current
	move x:X_DMA_WEB,A	   ; Address of other half of ring buffer to A
	cmp X0,A		   ; When time to switch, we get equality
	jseq write_data_switch     ; Switch write buffers on equality
				   ; QP_HUB: This also manages the slave read data,
				   ; which is constrained to be the same
				   ; buffer size (etc.) as the hub's write data.
;
; *** Clear next tick in DMA sound-out buffer ***
	clr B x:X_DMA_WFP,R_O       ; get tick pointer in dma output buffer

	; The conditional assembly below is not needed (it could be always true)
	; if we're willing to accept 3 extra instructions on each tick for
	; all versions of the monitor. Note that we are not entirely general here:  
	; In the case of non-zero outputPadding, we assume stereo, with
	; no skip between samples within a sample frame. Sigh. - DAJ 12/95
	move #(NB_DMA_W-1),M_O      ; write-data buffer is modulo ring size
   if O_PADDING_POSSIBLE
	move x:X_O_PADDING,A	    ; output padding, if any
	cmp B,A 
	jeq _fast_clear_tick	    ; if no output padding, use faster version
	move #>I_NTICK,X0
	move #3,N_O
 	do X0,_end_slow_clear_tick 
	     move B,y:(R_O)+        ; clear 
	     move B,y:(R_O)+N_O     ; clear and skip over control settings
_end_slow_clear_tick
	jmp _end_fast_clear_tick    ; skip over fast version
_fast_clear_tick
   endif	
	move x:X_O_CHAN_OFFSET,N_O  ; channel B offset
	move x:X_O_TICK_SAMPS,X0    ; This is set by the Music Kit (orchControl.m)
 	do X0,_end_fast_clear_tick 
	     move B,y:(R_O)+N_O     ; clear 
_end_fast_clear_tick
	move R_O,x:X_DMA_WFN        ; next write-fill pointer

   if SSI_READ_DATA
	jclr #B__SSI_RD_ENABLE,x:X_DMASTAT,swd_no_ssi_rd ; don't bother if no ssi rd
	move x:X_SSI_REN,X0	    ; Next ssi input empty pointer (in1a.asm)
	move X0,x:X_SSI_REP         ; Make it current
	move x:X_SSI_RFB,A          ; Address of other half of ring buffer to A
	cmp X0,A		    ; When time to switch, we get equality
	jseq read_data_ssi_switch   ; Switch buffers on equality

	; Assumes M_O has been set by clear_tick
	move x:X_IN_INCR,N_O        ; Size of tick in input buffer
	move x:X_SSI_REP,R_O	
	nop
	move (R_O)+N_O
	move R_O,x:X_SSI_REN
swd_no_ssi_rd
   endif
  	move #-1,M_O                ; always assumed
	rts
;
;==============================================================================
; write_data_switch - switch write-data buffer-ring halves
;;
;; DESCRIPTION
;;   write_data_switch is called at the two crossover points between the two 
;;   halves of the write-data buffer ring.  See the end_orcl macro in
;;   /usr/local/lib/dsp/smsrc/beginend.asm for an example call.	 This is also a convenient
;;   time to check for underrun errors and the like (jsr check_errors).
;;
write_data_switch
write_data_switch1
;*	  jsr check_errors	   ; error messages from interrupt level
	  remember '"jsr check_errors" removed because wd underrun too common'
	  ; we hear about it once in ssi_xmt_exc already.
	  jsr write_data_wait	   ; wait until DMA_WEB is traversed by all
				   ; also waits for ssi read data
	  move x:X_DMA_WFB,X0	   ; current write-data fill buffer (now full)
	  move x:X_DMA_WEB,Y0	   ; write-data empty buffer (better be done!)
	  move Y0,x:X_DMA_WFB	   ; new write-data fill buffer
;daj	  move Y0,x:X_DMA_WFP	   ; new write-data fill pointer
	  move X0,x:X_DMA_WEB	   ; new write-data empty buffer

	  bchg #B__WRITE_RING,x:X_DMASTAT ; indicate parity of wd ring

	  jsr write_data_buffer_out 

	  rts
;==============================================================================
; read_data_ssi_switch - switch read-data buffer-ring halves
;;
;; DESCRIPTION
;;   read_data_switch is called at the two crossover points between the two 
;;   halves of the read-data buffer ring.  
;;
    if SSI_READ_DATA
read_data_ssi_switch
	  jsr read_data_ssi_wait   ; wait until DMA_WEB is traversed by all
				   ; also waits for ssi read data

	  move x:X_SSI_RFB,X0	   ; current read-data fill buffer (now full)
	  move x:X_SSI_REB,Y0	   ; read-data empty buffer (better be done!)
	  move Y0,x:X_SSI_RFB	   ; new read-data fill buffer
	  move X0,x:X_SSI_REB	   ; new read-data empty buffer

	  jsr read_data_buffer_in

	  rts
    endif
;==============================================================================
; write_data_wait - wait until WD readers (SSI and/or HOST) finish reading.
;	Called by write_data_switch.
;
;; DESCRIPTION
;;   Here is where we block waiting for the emptying write-data buffer
;;   to make it to safety. Either or both of the host and the SSI may be taking
;;   the write data, and we must wait for both of them to get their data.
;;   Typically, the SSI is nearly in real time, and the host is much faster
;;   than real time. Thus, we normally wait a while for the SSI, but should
;;   rarely, if ever, wait for the host to get its data.
;;   
;;   Note: we always wait until each DMA request is satisfied before sending
;;   out another. In other words, there is never more than one pending DMA
;;   request in each direction.
;;

write_data_wait

	; WD DMA req pending? If not, either WD is disabled or
	; host has taken all past buffers (see hmlib:hm_host_r_done)
	; If yes, block till host reads the WD-emptying buffer (WEB).

	; If SSI is reading, block till SSI reads WEB also.

	; Note that overrun of the read-pointers is not detected.
	; The read-pointer can get as much as a whole buffer ahead before 
	; losing.  The modulo addressing is the reason overrun is undetectable.

; ** HERE IS WHERE WE SPEND A LOT OF TIME BLOCKED AWAITING WRITE-DATA **
;    (assuming we are running ahead of real time)
;
; State table (WD = B__HOST_WD_PENDING bit) (DM = DSP Message)
;
; WDP HTIE	Meaning
; --- ----	-------
;  0    0 	no DMA, no DMs
;  0    1 	DMs in progress
;  1    0	DMA is pending and is hung waiting for the buffer to be filled
;  1    1 	Active DMA
;
; If READ_DATA is active, state (1,0) never happens.
;
; Here we want to block if we are in state (1,1) since this is the DMA-out
; of the previously filled buffer (not the one filled just now).  That DMA was
; actually started (by blocking if necessary until HTIE could be set to 
; start the transfer) when the newly filled buffer began filling.

wdw_block_host
	bset #B__BLOCK_WD_FINISH,y:Y_RUNSTAT 	; indicate blocked status
 	jclr #1,x:$FFE8,wdw_no_block_host 	; Wait until HCR(HTIE) == 0
	jclr #B__HOST_WD_PENDING,x:X_DMASTAT,wdw_no_block_host ; or ~pending
	jmp wdw_block_host
wdw_no_block_host
	bclr #B__BLOCK_WD_FINISH,y:Y_RUNSTAT 	; clear blocked status

; Join also on SSI reads.
; Note: The SSI block-read is sensed automatically.
; We could do automatic block transfer sensing for the host also, thus
; eliminating the need for the DSP_HM_HOST_R_DONE message from the host.
; However, automatic sensing can fail to detect overrun of the read
; (which should never happen in this case).  It seems there is
; plenty of time for the host to tell the DSP
; it has taken the block.  Perhaps another good reason is that presently
; the host can assume no new HOST_R_REQ can come in until it
; has sent the "DSP_HM_HOST_R_DONE" host message.  If we automatically
; sensed the transfer, the next R_REQ could race with the DMA complete
; interrupt in the host and possibly increase the number of states in the
; kernel.

;; Write data uses a single piece of memory, divided in two.
;; Hence the fill buffer (the half we just filled)
;;    may be the upper or lower half.
;; There are 4 main cases:
;;
;; Fill buffer		SSI status
;; 1.  upper half	not done
;; 2a. upper half	done
;; 2b. upper half	ahead (we've fallen out of realtime)
;; 3.  lower half	not done
;; 4a. lower half	done
;; 4b. lower half	ahead (we've fallen out of realtime)
;;
;; First we check which half we just filled.  
;; If we filled the upper half (case 1 or 2), we jump to wdw_block_ssi2. 
;; This code subtracts SSIRP (R_IO) from DMA_WFB.  
;; If DMA_WFB-SSIRP <= 0 (SSIRP >= DMA_WFB), then we're done (case 2).
;; If it is postive, we're not done (case 1).
;; 
;; Otherwise, we just filled the first half (case 3 or 4).
;; We can't just compare directly to SSIRP because SSIRP
;; will always be >= DMA_WFB.  Instead, we compare
;; SSIRP to the first location in the upper half.
;; That is, we compute (DMA_WFB + NB_DMA_W/2 - SSIRP).
;; If this is <= 0, then we're not done (case 3).
;; If it is positive, we are done (case 4).
;; (Note that if we want to differentiate between whether 
;; SSI is done or ahead in case 4, we'd need an extra check 
;; of whether F==R.)
;;
;; These four cases are illustrated below:
;;
;; Let R = SSIRP, L = NB_DMA_W/2 and F = DMA_WFB.
;;
;; Case 1:
;; 	|	|	|	F-R > 0 -> SSI not done
;;          R   F
;; Case 2a:
;; 	|	|	|	F-R == 0 -> SSI done
;;              F 
;;              R
;; Case 2b:
;; 	|	|	|	F-R < 0 -> SSI ahead
;;              F    R
;; Case 3:
;; 	|	|	|       F+L-R <= 0 -> SSI not done
;;      F       F+L   R
;; Case 4a & 4b:
;; 	|	|	|	F+L-R > 0 -> SSI done or ahead
;;      F   R   F+L      
;;
;;

	jclr #B__SSI_WD_PENDING,x:X_DMASTAT,wdw_no_ssi_wd
	move x:X_DMA_WFB,X1
	move #>YB_DMA_W2,A	; A = 2nd buff addr
 	cmp X1,A 	 	; Compute A-X1.
	jeq wdw_block_ssi2      ; Jump if we filled second half 
wdw_block_ssi1		     	; block until ssi reads its write-data buffer
	move #>YB_DMA_W2,A	; A = 2nd buff addr
 	move R_IO,X0 		; Compute A-X1.  X0 = SSIRP
	sub X0,A 		; Case 3 or 4.  A = YB_DMA_W2 - SSIRP.  
	jle wdw_block_ssi1	; >0, SSI has not read whole emptying buffer
	jmp wdw_unblock_ssi
wdw_block_ssi2			; We filled second half (case 1 or 2)
	move #>YB_DMA_W2,A	; A = 2nd buff addr (DMA_WFB)
	move R_IO,X0
	sub X0,A 		; DMA_WFB - SSIRP 
	jle wdw_unblock_ssi	; If <=0, SSI has read whole emptying buffer
	jmp wdw_block_ssi2	; No, Wait
wdw_unblock_ssi
	bclr #B__SSI_WD_PENDING,x:X_DMASTAT ; clear pending status
wdw_no_ssi_wd

	; QP_SAT: We don't have to wait for hub write data because we wait
	; in write_data_buffer_out
	; QP_HUB: Satellite blocking is done in write_data_buffer_out, since
	; sound is coming in synchronously in the case of SAT  read data.
	rts

;==============================================================================
; read_data_ssi_wait - wait until RD writers (SSI and/or HOST) finish writing.
;	Called by read_data_switch.
;
;; DESCRIPTION
;;   Here is where we block waiting for the emptying read-data buffer
;;   to make it to safety. 
;;   
;; Read data uses a single piece of memory, divided in two.
;;
;; We just emptied the E half of the buffer and we want to start
;; emptying the other half.  
;;
;; Case 1:
;; 	|	|	|	E-W > 0 -> SSI not done
;;          W   E
;; Case 2a:
;; 	|	|	|	E-W == 0 -> SSI done
;;              E 
;;              W
;; Case 2b:
;; 	|	|	|	E-W < 0 -> SSI ahead
;;              E    W
;; Case 3:
;; 	|	|	|       E+L-W <= 0 -> SSI not done
;;      E       E+L   W
;; Case 4a & 4b:
;; 	|	|	|	E+L-W > 0 -> SSI done or ahead
;;      E   W   E+L      
;;
;; The only difference between this and write_data_wait
;; is that with write_data, we compute a buffer of samples
;; then turn on write data.  Here we read a buffer of read data
;; then we start computing samples.  But another way to look at 
;; this is that we turn it on read data a buffer late AND we
;; ignore the first buffer.  Since we write 0s anyway (the
;; way the Music Kit works), this is fine!  
;;
read_data_ssi_wait		; Added by DAJ.
	jclr #B__SSI_RD_PENDING,x:X_DMASTAT,rdw_no_ssi_rd
	move x:X_SSI_REB,X1     ; Which half did In1a just finish reading?
	move #>YB_DMA_R2,A	; A = 2nd buff addr
 	cmp X1,A  	 	; Compute A-X1.  
	jeq rdw_block_ssi2      ; Jump if In1a just read second half 
	; We just read first half
rdw_block_ssi1		     	; block until ssi finishes writes of second half 
	move #>YB_DMA_R2,A	; A = 2nd buff addr
	move R_IO2,X0 		; get system's write pointer
	sub X0,A 		; Case 3 or 4.  A = YB_DMA_R2 - SSIWP.  
	jle rdw_block_ssi1	; >0, SSI has not written whole buffer
  				; else fall through
rdw_unblock_ssi
	bclr #B__SSI_RD_PENDING,x:X_DMASTAT ; clear pending status

rdw_no_ssi_rd
	rts
rdw_block_ssi2			; We just read second half (case 1 or 2)
	move #>YB_DMA_R2,A	; A = 2nd buff addr (SSI_REB)
	move R_IO2,X0 		; get system's write pointer
	sub X0,A 		; SSI_REB - SSIWP 
	jle rdw_unblock_ssi	; If <=0, SSI has written whole buffer
	jmp rdw_block_ssi2	; No, Wait
; =============================================================================
; read_data_wait - wait until read-data buffer is complete from host.
;		   SSI read-data is handled separately since it does
;		   not share the host read-data buffer.
;
; TODO: If deferred termination is pending, when current buffer is consumed, 
; read-data is turned off before the next W_REQ goes out.
;
read_data_wait
	if READ_DATA
	bset #B__BLOCK_RD_FINISH,y:Y_RUNSTAT 	; indicate blocked status
rdw_block_host
	jset #B__HOST_RD_PENDING,x:X_DMASTAT,rdw_block_host ; block for rd
	bclr #B__BLOCK_RD_FINISH,y:Y_RUNSTAT 	; clear blocked status
	endif
	rts
; =============================================================================
read_data_request
	remember 'This should take a channel number from 1 to 16'
	if READ_DATA
	move #>2,A		; channel 2 (driver DSP stream 2) used
	move #DM_HOST_W_REQ,X0  ; host-read request for host
	jsr dspmsg
	endif
	rts
; =============================================================================
read_data_buffer_in
;
; Start SSI input if necessary
;
;DAJ
	  jclr #B__SSI_RD_ENABLE,x:X_DMASTAT,rdbi_no_ssi_rd ; must be enabled
	  jset #B__SSI_RD_RUNNING,x:X_DMASTAT,rdbi_ssi_running ; already set up
	  move x:X_SSI_SBUFS,A     ; We don't turn on SSI RD until soundout buffers 
	  move #>1,X1              ;    have a chance to fill.
	  add X1,A		   ; Increment start buffs count (SSI_SBUFS)
	  move A,x:X_SSI_SBUFS  
	  move x:X_SSI_SBUFS_GOAL,X1 ; Compare it to our goal 
	  cmp X1,A		   ; If equal, start SSI
	  jne rdbi_no_ssi_rd       ;    else wait a while longer
	  jset #B__SSI_RD_RUNNING,x:X_DMASTAT,rdbi_ssi_running ; already set up

	  move #NB_DMA_W-1,M_IO2   ; Make it modulo like DMA write buffers
	  move x:X_SSI_RFB,R_IO2   ; Read-data fill buffer
	  bset #B__SSI_RD_RUNNING,x:X_DMASTAT ; once started, do not reset
	  bset #M_SRE,x:M_CRB	   ; SET RE  = Receive Enable
wait_ssi_frame
	  jclr #M_RFS,x:M_SR,wait_ssi_frame ; Wait for frame sync boundary
	  clr A x:X_IN_INITIAL_SKIP,X0
	  ; For little endian with skip, inputSampleSkip != 0
  	  ; Some devices which use I_SFRAME_W, such as the AD64x, are "little 
          ; endian.", meaning that when the sample frame is != 2, 
          ; data comes in as 
          ; (<skipped sample(s)>,sample,<skipped sample(s)>,sample). So
          ; we have to eat the first in_skip samples. 
          ; For example, for AD64x, samples come in as (0,sample,0,sample)
          ; and the I_SFRAME_W is 4. So we eat one sample. 
	  cmp X0,A
	  jeq rdbi_ssi_grab
	  do X0,rdbi_ssi_grab
wait_ssi_data_r
	     jclr #M_RDF,x:M_SR,wait_ssi_data_r  ; Wait for data	  	  
	     movep x:M_RX,X1                     ; throw it away
rdbi_ssi_grab
wait_ssi_data_r2		; This is needed if IN_INITIAL_SKIP = 0
	  jclr #M_RDF,x:M_SR,wait_ssi_data_r2  ; Wait for data	  	  
	  movep x:M_RX,y:(R_IO2)+  ; first sample
	  ; Now let data flow into buffer
	  bset #M_SRIE,x:M_CRB	   ; SET RIE = Receive Interrupt Enable
rdbi_ssi_running
	  bset #B__SSI_RD_PENDING,x:X_DMASTAT ; mark pending status
	  remember 'check that conditions set by ssi rd turn-on still hold'
	  ;; e.g. check SSI control bits, compare WEB to SSIRP, etc.
rdbi_no_ssi_rd
	  rts  			   
; =============================================================================
; write_data_buffer_out - prompt write-data takers to read new DMA_WEB
;
;; DESCRIPTION
;;   This is called by write_data_switch when a write-data buffer has been 
;;   filled and needs to be sent out to the host or the ssi or both.
;
write_data_buffer_out
  if QP_HUB
;
; We have the SAT read data here, rather than read_data_buffer_in because
; SAT read data is closely tied to write data.  In particular the buffer
; MUST be the same size. 
;
; From the satellite's point of view, it computes a buffer, then it blocks 
; until it has the "semaphore word" from the hub.  The presence of this word 
; means "hub is no longer reading previous buffer".  Then the satellite reads 
; the word.  Reading the word signals the hub and means "satellite has the 
; next buffer ready".  Then the satellite goes ahead and computes the next buffer.

; From the hub's viewpoint, when it is ready to grab a buffer from the satellites, 
; it waits until all satellites have read the semaphore word that the hub previously 
; sent.   Then it knows the satellites are ready with their new buffer and it 
; proceeds to read that buffer.  When it's done reading the buffer, it sends 
; the semaphore word again, meaning "hub is no longer reading previous buffer".  
; Then it goes ahead and computes its next buffer.

; For start-up, the hub has to send the semaphore word to get things going.  

; There's one more subtlty:
; The satellite uses a fast 2-word post-increment interrupt handler to write the 
; buffer.  The hub reads an entire buffer. When the hub reads the last word, the 
; satellite interrupt is triggered, causing the satellite to write one extra word 
; of garbage (it's the first word of the not-yet-computed buffer).    Thus, the 
; satellite resets the pointer to the X_DMA_WEB before it reads the semaphore word, 
; but after it knows that word is there.  By waiting for the word to be there, 
; the satellite knows it's ok to reset R_IO, because the hub has finished reading 
; the buffer.  By resetting R_IO before reading the word, it knows that R_IO will 
; be ready when the first interrupt comes.  On the hub side, after seeing that all 
; satellites have read their semaphore words, the hub waits for all satellites to 
; have sent it data.  Then it throws away the first word.   That is because this 
; first word is actually the extra word that the satellite wrote on the previous 
; buffer.    

; For start-up, the hub has to send the semaphore word to get things going.  
; And the satellite has to send one word of garbage before turning on the interrupt.

          ; FIXME May want to support individual satellite enables.
	  jclr #B__IPS_ENABLE,y:Y_DEVSTAT,wdbo_no_sat_rd ; must be enabled
	  jset #B__IPS_RUNNING,y:Y_DEVSTAT,wdbo_sat_running ; already set up
	  bset #B__IPS_RUNNING,y:Y_DEVSTAT ; once started, do not reset
          move X0,y:Y_QP_DATA_ALL  ; Set up initial semaphore word

wdbo_sat_running
	  move R_X,N_X           ; Store in an unused place
	  move x:X_SAT1_RFB,R_O  ; Set up pointers 
	  move x:X_SAT2_RFB,R_I1
	  move x:X_SAT3_RFB,R_I2
	  move x:X_SAT4_RFB,R_X
	  ; Wait until all satellites have read the word we previously sent.
	  ; This condition means they all have a buffer ready.  
	  ; Also incidentally wait for all our receive data ports to be	
	  ; full, so that we don't need to check the bits below when we read
	  ; the "dummy" word.  
  if SKIP_DSP_A
	  move #>$FC,X0
  else
	  move #>$FF,X0		 
  endif
_wdbo_sat_wait_all
	  move y:Y_QP_SLAVE_INT_STAT,A
	  and X0,A	  	 ; I've found that high bits of INT_STAT may not be 0
	  cmp X0,A	  	  	  	  	  
	  if SYS_DEBUG
	    move A,x:X_QPSTAT2
	  endif
	  jne _wdbo_sat_wait_all

	  ; Read dummy word from each 
  if !SKIP_DSP_A
	  move y:Y_QP_DATA_A,X0
  endif
	  move y:Y_QP_DATA_B,X0
	  move y:Y_QP_DATA_C,X0
	  move y:Y_QP_DATA_D,X0
	  ; could make this smarter and pull only needed samples, taking into account
	  ; skip factors and such. Repeat N times:  reads a sample from the four data 
	  ; ports. Each time a sample is read from the data port, an IRQ B interrupt is 
	  ; generated in the slave to write the next word.
	  do #((NB_DMA_W)/2),_wdbo_sat_loop
		if SYS_DEBUG
	          movec lc,x:X_QPSTAT 	; Save for debugging
		endif
  if !SKIP_DSP_A
_wdbo_sat_a_wait	
	        jclr #0,y:Y_QP_SLAVE_INT_STAT,_wdbo_sat_a_wait
		movep y:Y_QP_DATA_A,y:(R_O)+
  endif
_wdbo_sat_b_wait	
	        jclr #2,y:Y_QP_SLAVE_INT_STAT,_wdbo_sat_b_wait
		movep y:Y_QP_DATA_B,y:(R_I1)+
_wdbo_sat_c_wait	
	        jclr #4,y:Y_QP_SLAVE_INT_STAT,_wdbo_sat_c_wait
		movep y:Y_QP_DATA_C,y:(R_I2)+
_wdbo_sat_d_wait	
	        jclr #6,y:Y_QP_SLAVE_INT_STAT,_wdbo_sat_d_wait
		movep y:Y_QP_DATA_D,y:(R_X)+
_wdbo_sat_loop
	  ; Deposit the semaphore word in slave's data port.  This word means
	  ; "I've read the buffer. It's ok to clobber it now".  This word won't
	  ; be read by the slave until its next buffer is ready.
	  move X0,y:Y_QP_DATA_ALL 
	  if SYS_DEBUG
	    move #>QP_B__RUNNING,X0	   ; Indicate that we've made it
	    move X0,x:X_QPSTAT
          endif
	  move x:X_SAT1_RFB,X0	   ; Swap buffers
	  move x:X_SAT1_REB,Y0	   
	  move Y0,x:X_SAT1_RFB	   
	  move X0,x:X_SAT1_REB	   

	  move X0,x:X_SAT1_REP

	  move x:X_SAT2_RFB,X0	   
	  move x:X_SAT2_REB,Y0	   
	  move Y0,x:X_SAT2_RFB	   
	  move X0,x:X_SAT2_REB	   

	  move X0,x:X_SAT2_REP

	  move x:X_SAT3_RFB,X0	   
	  move x:X_SAT3_REB,Y0	   
	  move Y0,x:X_SAT3_RFB	   
	  move X0,x:X_SAT3_REB	   

	  move X0,x:X_SAT3_REP

	  move x:X_SAT4_RFB,X0	   
	  move x:X_SAT4_REB,Y0	   
	  move Y0,x:X_SAT4_RFB	   
	  move X0,x:X_SAT4_REB	   

	  move X0,x:X_SAT4_REP

  	  move N_X,R_X           ; restore R_X
	  ; Currently assumes all enabled FIXME
wdbo_no_sat_rd
  endif
;
; Start SSI output if necessary
;
	  jclr #B__SSI_WD_ENABLE,x:X_DMASTAT,wdbo_no_ssi_wd ; must be enabled
	  bset #B__SSI_WD_PENDING,x:X_DMASTAT ; mark pending status
	  jset #B__SSI_WD_RUNNING,x:X_DMASTAT,wdbo_ssi_running ; read the below
	  move #NB_DMA_W-1,M_IO    ; Make it modulo like DMA write buffers
	  move x:X_DMA_WEB,R_IO     ; Write DMA buffer, 1st half
	  bset #B__SSI_WD_RUNNING,x:X_DMASTAT ; once started, do not reset
	  bset #12,x:M_CRB	   ; SET TE  = Transmit Enable
	  clr A x:X_OUT_INITIAL_SKIP,X0
	  cmp X0,A
	  jeq wait_ssi_data_w2
	  do X0,wdbo_ssi_put
wait_ssi_data_w
	    jclr #M_TDE,x:M_SR,wait_ssi_data_w  ; Wait for room
	    movep #0,x:M_TX	   ; Move initital zero to SSI
wdbo_ssi_put

wait_ssi_data_w2		   ; This is needed if OUT_INITIAL_SKIP = 0
	  jclr #M_TDE,x:M_SR,wait_ssi_data_w2  ; Wait for room
          movep y:(R_IO)+,x:M_TX   ; Move initital sample to SSI
	  bset #14,x:M_CRB	   ; SET TIE = Transmit Interrupt Enable

wdbo_ssi_running
	  remember 'check that conditions set by ssi wd turn-on still hold'
	  ;; e.g. check SSI control bits, compare WEB to SSIRP, etc.
	  rts  			   ; DAJ: SSI out & DMA out can't coexist
				   ; QP_SAT: SSI out and QP out can't coexist
wdbo_no_ssi_wd
  if QP_SAT
	  jclr #B__IPS_ENABLE,y:Y_DEVSTAT,wdbo_no_hub_wd ; must be enabled
	  jset #B__IPS_RUNNING,y:Y_DEVSTAT,wdbo_hub_wait ; read the below
	  bset #B__IPS_RUNNING,y:Y_DEVSTAT ; mark running (steal SSI bit)
	  movep X0,y:Y_QP_DATA     ; write a word of garbage to the hub.
	  move #NB_DMA_W-1,M_IO    ; Make it modulo like DMA write buffers
 	  bset #3,x:$FFFF          ; IRQ B interrupt enable
	  ; We won't get an interrupt until hub reads the garbage word, which
	  ; won't happen until we read the semaphore word.
;	  rep #3		   ; make sure the interrupt gets enabled 
;		nop
wdbo_hub_wait
	     if SYS_DEBUG
	  move #>QP_B__WAITING,X0
	  move X0,x:X_QPSTAT	   ; save for debugging
	     endif
	  jclr #23,y:Y_QP_CMD_STAT,wdbo_hub_wait ; wait until hub has written to us
	  jclr #23,y:Y_QP_CMD_STAT,wdbo_hub_wait ; Duplication is essential! 
						 ; See pg. 83 or QP man
	  move x:X_DMA_WEB,R_IO    ; New emptying buffer.  (Needed because we let
				   ; pointer increment an extra time). This must
				   ; be after check above and before reading below!
	  movep y:Y_QP_DATA,X0     ; read word from data port (ignore it).  This
				   ; signals hub to proceed to read buffer
	     if SYS_DEBUG
	  move #>QP_B__RUNNING,X0
	  move X0,x:X_QPSTAT	   ; save for debugging
	     endif
	  rts  			   ; No host write data exists for QP_SAT
wdbo_no_hub_wd
  endif  ; QP_SAT

;
; Write-data DMA is started up is as follows.
;
; We first block until B__HOST_WD_PENDING is 1, HTIE is 0, and HF1 is 1.
; This means the DMA for the current buffer has been set up and is waiting to
; go.  We set HTIE to start this DMA.  Next, if read-data is NOT enabled,
; we enqueue a HOST_R_REQ for the NEXT buffer to be filled.  
; When the HOST_R_REQ message is delivered (in the
; host_xmt handler), that DMA will be set up (setting B__HOST_WD_PENDING)
; with HTIE off in the case of disabled read-data, and on in the case of
; enabled read-data. HTIE will remain on as long as we are in the current DMA.
; B__HOST_WD_PENDING is logically B__HOST_READ for channel 0.  If a DMA on
; another channel is in progress, B__HOST_WD_PENDING will not be set, and we
; will continue to wait. B__HOST_WD_PENDING is cleared in the hm_host_r_done
; handler.
;

  if DMA_SOUND_OUT
	if WRITE_DATA_16_BITS
; First, we need to shift the buffer just filled:
	move x:X_DMA_WEB,R_I1
	move #1,N_I1
	move #@pow(2,-8),X0	; for shifting right 8 bits
	move y:(R_I1),Y0
;	move #>$00FFFF,Y1	; For debugging.  DAJ 11/24/95
	do #I_NDMA,wdbo_shift
;
; We cannot do a mpyr below, because a $7FFF,,1xx will wrap around to $8000
;
		mpy X0,Y0,A y:(R_I1+N_I1),Y0
;		and Y1,A	; Mask off high byte (debugging) DAJ 11/24/95
		move A,y:(R_I1)+
wdbo_shift
	endif ; WRITE_DATA_16_BITS

; Referring to the state table in write_data_wait, we now want to wait
; explicitly for state (1,0) in which the DMA is started but hung awaiting
; HTIE to be set to enable the transfer.  In addition, we await the host
; flag HF1 which the kernel sets when it has completed the INIT of the
; host interface in DMA mode. 

;DAJ	jset #B__SIM,y:Y_RUNSTAT,wdbo_unbuzz ; don't block in simulator
	; if not B__HOST_WD_ENABLE and not B__HOST_WD_PENDING, don't block

	remember 'rewrite this ENABLE jump around since now there are R and W'
	jset #B__HOST_WD_ENABLE,x:X_DMASTAT,wdbo_buzz

    if READ_DATA
;
; If read-data is enabled, we are not setting up DMAs in advance,
; and we need to issue a request for this buffer.
; FIXME: should not block until after the NEXT buffer is filled!
;
	jsset #B__HOST_RD_ENABLE,x:X_DMASTAT,wd_dma_request
	jset #B__HOST_RD_ENABLE,x:X_DMASTAT,wdbo_buzz ;don't need pending if RD
    endif

	jset #B__HOST_WD_PENDING,x:X_DMASTAT,wdbo_buzz ; !RD => need pending
	jmp wdbo_unbuzz

wdbo_buzz
	bset #B__BLOCK_WD_START,y:Y_RUNSTAT ; indicate blocked status
    if !SYS_DEBUG
	jclr #B__HOST_WD_PENDING,x:X_DMASTAT,wdbo_buzz 	; need DMA pending
	jset #1,x:$FFE8,wdbo_buzz  ; HTIE must be clear => DMA not active
				   ; and DSP messages are off
	jclr #4,x:$FFE9,wdbo_buzz  ; wait for HF1     *** 02/24/89/jos ***
    else
	jset #B__HOST_WD_PENDING,x:X_DMASTAT,wdbo_gotp 	; need DMA pending
	  bset #B__BLOCK_WD_PENDING,y:Y_RUNSTAT ; indicate reason for blocking
	  jmp wdbo_buzz
wdbo_gotp
	bclr #B__BLOCK_WD_PENDING,y:Y_RUNSTAT
	jclr #1,x:$FFE8,wdbo_gotc  ; HTIE must be clear => DMA not active
	  bset #B__BLOCK_WD_HTIE,y:Y_RUNSTAT ; indicate reason for blocking
	  jmp wdbo_buzz
wdbo_gotc
	  bclr #B__BLOCK_WD_HTIE,y:Y_RUNSTAT
	  ; *** 02/24/89/jos CHANGED FROM HF0 ***
	  jset #4,x:$FFE9,wdbo_unbuzz ; wait for HF1 => host did DMA INIT
	  bset #B__BLOCK_WD_HF1,y:Y_RUNSTAT ; indicate reason for blocking
	  jmp wdbo_buzz
    endif ; !SYS_DEBUG

wdbo_unbuzz
	bclr #B__BLOCK_WD_HF1,y:Y_RUNSTAT
	bclr #B__BLOCK_WD_START,y:Y_RUNSTAT ; clear blocked status
;
; We are in DMA mode. DSP messages are off and a DMA read is hanging
; for the previously filled buffer.  Start the DMA transfer:
;
	if !ASM_BUG56_LOADABLE	   ; Don't do this if running under Bug56
	  bset #1,x:$FFE8 	   ; Set HTIE in HCR to enable DMA transfer
	endif
;
; If read-data is NOT enabled,
; enqueue a DMA transfer request for the buffer we are starting to fill now.
; When this message goes out (in turn after the current DMA completes), we 
; will go back into hung DMA mode [state (1,0)] until the currently filling
; buffer is full.  At that time, we will arrive here again and the transfer
; to the host will be enabled.
;
    if READ_DATA
	jset #B__HOST_RD_ENABLE,x:X_DMASTAT,wdbo_no_host_wd
    endif
;
; *** Tell host to pick up write-data buffer, if write-data is enabled ***
;
	jsset #B__HOST_WD_ENABLE,x:X_DMASTAT,wd_dma_request
;
; *** Blocking for SSI WD complete is done in write_data_wait
;
wdbo_no_host_wd

  if 0    ; Commented out by DAJ
	  jclr #B__SIM,y:Y_RUNSTAT,wdbo_done ; do following only for SIMULATOR
		bclr #14,x:M_CRB	; Nevermind SSI transmit interrupts
		bclr #12,x:M_CRB	; (Note: SSIRP is ADVANCED already)
		bclr #B__SSI_WD_PENDING,x:X_DMASTAT  ; clear SSI pending status
	        move x:X_DMA_WEB,R_I1	; Emptying buffer (not SSIRP!)
		move #NB_DMA_W-1,M_I1   ; Make it modulo for the heck of it
	        do #I_NDMA,dma_out_simulator
		    move y:(R_I1)+,A	; Outgoing DMA buffer sample
		    move A,y:I_OUTY	; WD output is to y:I_OUTY file
dma_out_simulator			; With SSI transmit interrupts off,
	        move R_I1,R_IO	        ;   this will satisfy write_data_wait
		move #-1,M_I1    	; Assumed by the world
   endif

   endif				; endif DMA_SOUND_OUT
wdbo_done  rts	    
;
; =============================================================================
; wd_dma_request - request DMA output of currently filling write-data buffer
;
; First, we make sure DSP messages are turned off because we can't let a
; host_xmt interrupt happen until all three words are are written to the DMQ.
; We can be called from (1) write_data_buffer_out, in which case DSP messages
; are off and a DMA read (DSP to host) has just been enabled, or from (2)
; the host_wd_on handler in hmlib in which case DSP messages may be on
; but the host_xmt exception cannot happen until after the handler exits,
; or from (3) the sine_test handler which explicitly turns off DSP messages.
;
wd_dma_request
;DAJ    jset  #B__SIM,y:Y_RUNSTAT,wdr_ok	; don't block if simulating
	jset #B__DM_OFF,x:X_DMASTAT,wdr_ok	; if DSP messages are off
	move sr,A 				; or host is locked out
	move #>$300,X0
	and X0,A
	jne wdr_ok				; then we're ok
		DEBUG_HALT			; else we can be interrupted
wdr_ok
	move #>SPACE_Y,X0 		; memory space code
	move X0,x:X_DMA1_R_S		; to DSP-initiated channel data

	move x:X_DMA_WFB,X0		; DMA start address
	move X0,x:X_DMA1_R_R		; to DSP-initiated channel data

	move #>1,X0			; DMA skip factor
	move X0,x:X_DMA1_R_N		; to DSP-initiated channel data

	move #-1,X0			; Linear addressing mode
	move X0,x:X_DMA1_R_M		; to DSP-initiated channel data

	move #>I_WD_CHAN,A		; DSP initiated channel = msg arg
	move #DM_HOST_R_SET1,X0		; HOST_R setup word 1
	jsr dspmsg			; enqueue

 	rts
; =============================================================================
; service_tmq		 ; execute timed messages for current tick
;;			 ; called once per tick loop at user level
;;
;; DESCRIPTION
;;
;;   While (l:L_TICK equals time-stamp of next timed message) {
;;	  lock TMQ
;;	  point R_I1 to opcode
;;	  Execute the timed message
;;	  pop top frame of TMQ
;;	  unlock TMQ
;;   }
;;
;;   Dispatched from hmdispatch.asm by 1.0 MK orchloopbegin.
;;
;;   See /usr/local/lib/dsp/smsrc/hmlib.asm for TMQ format.
;;
;; BUGS
;;   The entire message is executed with the host masked which means
;;   no host messages or DSP messages can get through.  If something 
;;   goes wrong in executing the message, debugging is difficult.  
;;   (We could use the IRQA interrupt to reset the IPR for this.)
;;
;;   To allow host messages to come in, we could use a status bit to indicate
;;   that the TMQ is in use, and the xhmta handler could block when it
;;   needs to move a message from the HMS to the TMQ which would overwrite an
;;   unread message.
;;
	remember 'Can we flush link/count and use TMQ_MEND only?'
;	Link is good for independently popping off message from Q
;	rather than depending on each hm handler to leave ptrs right.
;	Maybe use count only for this.

service_tmq1 ; execute timed messages for current tick

	  jclr #B__TMQ_ACTIVE,y:Y_RUNSTAT,st_TMQ_empty
	  remember 'TMQ active check happening twice, as is time stamp compare'

service_tmq2
	  mask_host		   ; set interrupt pri mask to stifle host

	if 0
	  msg 'avoiding sound underrun' 

          jset #B__TMQ_ATOMIC,x:X_DMASTAT,process_tmq
                                   ; If we're in parens, gotta process tmq
		;;; Maybe need check for write data running?
		;;; Maybe need to do this for SSI output only?
          move R_IO,X1             ; Get write data output pointer
          move x:X_DMA_WFP,B       ; Get sound computation pointer
          sub X1,B #>I_NTICK,X0    ; Form WFP-R_IO
          jlt process_tmq          ; If it's negative, 2 possibilities:
                                   ; 1) We've already lost.  
				   ; 2) R_IO is in the upper buffer and we're in
				   ;    the lower buffer (an OK condition)
				   ; In either case, continue processing TMQ.
          cmp X0,B                 ; See if WFP-R_IO < NTICK
          jgt process_tmq          ; Got time. process TMQ.
          unmask_host              ; Getting close to underrun. Return now.
          rts
process_tmq

	endif

	  move #NB_TMQ-1,M_I1	   ; TMQ is a modulo buffer
	  move x:X_TMQRP,R_I1	   ; TMQ read pointer (points to tail mark)
	  move R_I1,R_I2	   ; nop
st_check_tmq			   ; see if TMQ has something to execute
	if SYS_DEBUG
	  move y:(R_I1),B	   ; TMQ tail mark to B1. R_I1 -> time stamp.
	  move #TMQ_TAIL,X0	   ; What tail should look like
	  cmp X0,B		   ; Check for clobberage
	  jeq st_tm_ok
	       move #DE_TMQTMM,X0  ;	No TMQ tail
	       jsr stderr	   ;	Complain
st_tm_ok  
	endif
	  clr B	(R_I1)+		   ; Get B2 clear. B will hold time stamp.
	  move y:(R_I1)+,B0	   ; low-order word of time stamp
	  move y:(R_I1)+,B1	   ; high-order word of time stamp
	  tst B			   ; check for TMQ empty
	  jne st_TMQ_not_empty	   ; ZERO TIME-STAMP DENOTES EMPTY TMQ:
				   ; (since such a msg would have gone to UTMQ)
	       bclr #B__TMQ_ACTIVE,y:Y_RUNSTAT ; turn off TMQ
 	       clr A #DE_KERNEL_ACK,X0 ; Wake up Mach Added by JOS--4/93
	if (SEND_KERN_ACKS)
        jsr dspmsg_noblock      ; Added by JOS--4/93
	endif
	     if SYS_DEBUG
	       move y:(R_I1)+,B    ; link word
	       tst B		   ; must be zero in null msg terminating TMQ.
	       jne st_nme	   ; nonzero = null message error.
	       move #TMQ_HEAD,X0   ; make sure head marker is in place too
	       move y:(R_I1)+,B	   ; should be head
	       cmp X0,B
	       jeq st_tmq_done				    
st_nme		 tfr B,A #DE_TMQHMM,X0 ; TMQ head mark missing or link fouled
		 if 1		   ; FIXME: temporary while UTMQ not existent
			lua (R_I1)-,R_I1 ; zero time stamp means do it now
			jmp st_TMQ_not_empty ; note that HMM not detected also
		 endif
		 jsr stderr
	     endif ; SYS_DEBUG
		 jmp st_tmq_done
st_TMQ_not_empty
;
; *** HERE IS WHERE THE TIME STAMP IS LOOKED AT AND UNDERRUN IS DEALT WITH ***
;
; The message is executed when the tick time (in samples) is greater than
; or equal to the time stamp (in samples).  If the tick time exceeds the
; time stamp by a whole tick or more, an underrun error message is generated.
;
	move l:L_TICK,A	   	; tick count (already updated for next tick)
	cmp A,B #>I_NTICK,X0	; form sign of B-A = timeStamp-TICK
	jgt st_tmq_done		; NOPE, next thing to do still in future

	if TMQU_MSGS
	    jeq st_xct_tm	   ; If not TMQ underrun, process the message
	    move B0,Y0		   ; save time stamp in B to Y (could use l:)
	    clr B B1,Y1
	    move X0,B0		   ; tick size to B as long
	    sub B,A  Y1,B 	   ; A = previous TICK
	    move Y0,B0
	    cmp A,B		   ; B-A = timeStamp-TICK+NTICK
	    jgt st_xct_tm	   ; Previous tick saw message in the future
	      move #DE_TMQU,X0     ;   else UNDERRUN (timeStamp<TICK)
	      move y:Y_TICK,A	   ; Current time at underrun (low-order word)
	      jsr dspmsg
	 endif ; TMQU_MSGS
st_xct_tm			   ; Execute next item in TMQ

	  clr A y:(R_I1)+,X0	   ; next-message link, or wd-count-left, or 0
	  move X0,R_O		   ; link word to R_O in case it's a link
	  move #>YB_TMQ,A  	   ; TMQ start address
	  cmp X0,A		   ; start address - (link|count)
	  remember 'IGNORING LINKS because have_link code still not written'
; !!!	  jle st_have_link	   ; link >= start address, count always less

st_no_link     move y:(R_I1),X0	   ; Op code or message terminator TMQ_MEND
	       move #TMQ_MEND,A	   ; check for message terminator
	       cmp X0,A		   ; if not there, assume opcode
	       jeq st_nolink_done
		    jsr jsr_hm	   ; execute message (handlers.asm)
		    jmp st_no_link ; keep going until terminator TMQ_END seen
st_nolink_done
	       move #TMQ_TAIL,X0   ; advance tail over executed messages
	       move X0,y:(R_I1)	   ; overwrite TMQ_MEND with TMQ_TAIL
	       move R_I1,x:X_TMQRP ; update TMQ read pointer to new tail

st_did_one
	;
	; Even though we are never called at interrupt level,
	; host-interface interrupts are disabled.  Thus, there
	; is not much point in calling check_tmq_full after each
	; message in order to post an early HF3 clear. On the
	; other hand, if deadlock is a problem, calling it here
	; could help.

		; *** LOOP BACK POINT ***
	       jmp st_check_tmq 	; go check for another timed message

st_have_link
	  remember 'no link support at present'
	  jsr unwritten_subr
	  jmp st_did_one

st_tmq_done
	;
	; Check to see if the TMQ is full.
	;
	  jsr check_tmq_full  	   ; unblock timed messages if there's room
	;
	; Now, HF3 is SET if the TMQ is full, CLEAR if it is not full, and
	; #B__TMQ_FULL,y:Y_RUNSTAT is SET to HF3
	; 
	;
	; ************************* BLOCKING LOOPS ***************************
	;
	; Enable host interrupts so host messages can come in.
	; Can block within parens or in low water.
	;
	; HOWEVER, HF2 will be set if a timed-zero message comes in.
	; We must watch for this and execute all timed-zero messages
	; as they come in.
	;
	; We also inhibit blocking if the ABORTING bit is set.
	;
	move #-1,M_I1		   ; M registers assumed -1 always
	unmask_host		   ; restore interrupt priority mask (pop SR)

	; *** PARENTHESES BLOCKING ***
	jclr #B__TMQ_ATOMIC,x:X_DMASTAT,st_not_atomic
	; Here we are in an atomic block, and the host must send us more
	; timed messages up to the close_paren message.
	;; However, if a "timed-zero message" is pending, it can't get in,
	;; so we must clear that up now.  Since we are at a tick boundary,
	;; (because "jsr hm_service_tmq" only appears at the top of the orch.
	;; loop), the TZM is legal to do now.
st_buz_tm 
	jsset #B__TZM_PENDING,x:X_DMASTAT,loc_xhmta_return_for_tzm
	;; Also refrain from blocking if we're aborting:
	jsset #B__ABORTING,y:Y_RUNSTAT,abort_now	; abort => can't block
	jset #B__TMQ_FULL,y:Y_RUNSTAT,st_not_atomic ; no point waiting if full
	jclr #B__TMQ_ACTIVE,y:Y_RUNSTAT,st_buz_tm ; wait for new timed msg
	jmp service_tmq2	   ; keep processing TMQ until close_paren seen
st_not_atomic

st_TMQ_empty
	;
	; *** LOW-WATER-MARK BLOCKING (Actually blocking on empty) ***
	;
	jset #B__TMQ_ACTIVE,y:Y_RUNSTAT,st_no_block ; have a future msg q'd
;	txd_interrupt ; ***DAJ***
st_buz_lwm
	jclr #B__BLOCK_TMQ_LWM,y:Y_RUNSTAT,st_no_block
	;; Here we want more host messages in the TMQ to avoid underrun.
	;; Clear any waiting timed-zero message:
	jsset #B__TZM_PENDING,x:X_DMASTAT,loc_xhmta_return_for_tzm
	;; Refrain from blocking if we're aborting:
	jsset #B__ABORTING,y:Y_RUNSTAT,abort_now	; abort => can't block
	jclr #B__TMQ_ACTIVE,y:Y_RUNSTAT,st_buz_lwm ; wait for new timed msg
	jmp service_tmq2 ; give new msg a chance to be executed
st_no_block

	rts

; =============================================================================
; check_tmq_full - Determine if Timed Message Queue is too full.
;; Note: it is not sufficient to declare full when there is room for 
;; one maximum message or less because
;; a write may already be in progress to the HMS.  That is, at the time
;; we turn on HF3, a max length message may be coming for sure.  Thus,
;; there should be at least two times NB_HMS as margin.
;
check_tmq_full
	jsr measure_tmq_margin		; result in A = # TMQ data words free
	jle st_tmq_full			; 	otherwise, TMQ is nearly full
	  clear_hf3
	  bclr #B__TMQ_FULL,y:Y_RUNSTAT
	  ; Normally we rely on sound-out requests to wake up the
	  ; DSP driver so it can notice the TMQ is no longer full.
	  ; If sound output is to the SSI port only, we have to send
	  ; a message to wake up the kernel:
	  ; *** NOTE *** If message on TMQ low-water mark feature is enabled
	  ; (see check_tmq_lwm below) then this is not needed.
	  jcc ct_exit ; if TMQ_FULL bit was already clear, skip the below
  if DMA_SOUND_OUT
	  ; if we're not doing DMA_SOUND_OUT, we definitely have either 
	  ; SSI_WD or HUB_WD in both cases, we want to "kick" the host so
	  ; no need for these two tests.
	  jset #B__HOST_WD_ENABLE,x:X_DMASTAT,ct_exit
	  jclr #B__SSI_WD_ENABLE,x:X_DMASTAT,ct_exit 
  endif 
	    clr A #DE_KERNEL_ACK,X0 ; Wake up Mach
;	    txd_interrupt

	if 0
	    ; The following code checks if the DMQ is empty.  If the DMQ
	    ; is not empty, there's no need to send the DE_KERNEL_ACK
	    ; I tried enabling this but it caused clicks.
 	    move x:X_DMQRP,R_O  ; DMQ read pointer
	    move #NB_DMQ-1,M_O  ; modulo
	    move x:X_DMQWP,Y0   ; DMQ write pointer
	    move (R_O)+
	    move #-1,M_O        ; un-modulo
	    move R_O,B
	    cmp Y0,B		; Check for DMQ empty
	    jseq dspmsg         ; It's empty, so send DE_KERNEL_ACK
	endif

	if (SEND_KERN_ACKS)
        jsr dspmsg_noblock
	endif
	    jmp ct_exit
st_tmq_full
	bset #B__TMQ_FULL,y:Y_RUNSTAT
	jset #M_HF2,x:M_HCR,ct_exit  	; HF2 & HF3 together mean "abort"
	set_hf3
ct_exit
	rts

measure_tmq_margin ; result in A is positive when there is "enough" TMQ room.
		   ; called above and in handlers.asm for the host message.
	jsr measure_tmq_room		; result in A = # TMQ data words free
	move #>2*NB_HMS,X0		; large margin
	sub X0,A			; must be positive (allow for opcode)
	rts

; =============================================================================
measure_tmq_room ;  Compute number of free DATA words in tmq (result in A)
		 ;  You can send a single message to the TMQ if the data part
		 ;  (that which is written to TX) does not exceed room.
		 ;  The opcode (which is the last thing written to TX)
		 ;  is not counted (i.e. room for it is reserved here).
		 ;  The purpose of reporting DATA room only is to suppress
		 ;  details of the TMQ format should it change.
		 ;  Registers X0, A, and B are used.
		 ;  Result is in A.  It can be negative.
	move  x:X_TMQWP,X0	; TMQ write pointer (points to null message)
	clr B x:X_TMQRP,A	; TMQ read pointer (points to tail mark)
	sub X0,A #>NB_TMQ,X0	; Compute rp - wp = number of free words
	tlt X0,B		;   mod out buffer length
	add B,A	#>9,X0		;   (since TMQ is a ring)
	if SYS_DEBUG
	jge ct_nowrap		; negative means we're lost in space
		move #DE_TMQRWPL,X0  ; read or write pointer garbaged?
	        jsr stderr	; never returns
ct_nowrap
	endif
	sub X0,A		; rp-wp-4(nullmsg&hmk)-5(ts,op,link,MEND)
;; 	jclr #B__TMQ_LWM_ME,y:Y_RUNSTAT,ct_no_lwm_ck
;;
;; See if TMQ is nearly empty.
;; If so, set the bit and issue KERNEL_ACK message
	move #>I_NTMQ_ROOM_HWM,Y1 ; TMQ free-space HWM
	cmp Y1,A #DM_TMQ_LWM,X0	; #wds_free - #fs_hwm = (+) if too much FS
	jle ctl_high_water	; 			(+) => "low water"

;; If we have any more hanging problems, we should try uncommenting the
;; four lines below.  They send a KERN_ACK when the TMQ is almost empty.  
;; This should never be needed (?) because we send one when the TMQ goes 
;; non-full, so in theory, there should be no blocking when nearly empty ever.

;;	  bset #B__TMQ_LWM,y:Y_RUNSTAT ; indicate below low-water-mark status
;;	  clr A #DE_KERNEL_ACK,X0 ; Wake up Mach
;;	if !(QP_HUB||QP_SAT)
;;	  jsr dspmsg_noblock
;;	endif
;;	  rts

;; Old version of the above:
;;	  bset #B__TMQ_LWM,y:Y_RUNSTAT ; indicate below low-water-mark status
;;	  jsset #B__TMQ_LWM_ME,y:Y_RUNSTAT,dspmsg
;;	  bclr #B__TMQ_LWM_ME,Y:Y_RUNSTAT	; *** MUST ENABLE EACH MSG ***
;;	  rts

ctl_high_water
	bclr #B__TMQ_LWM,y:Y_RUNSTAT ; indicate above low-water-mark status
	rts

ct_no_lwm_ck
	rts

;; ================================================================
; hm_system_tick_updates - abort DSP execution
;;	  Falls into monitor mode awaiting debugger
;;
hm_system_tick_updates
;
freeze_	jset #3,x:$FFE9,freeze_ ; freeze if requested via HF0 ("abort" in 1.0)
;	
;    check timed message queue
;
	jsset #B__TZM_PENDING,x:HW_X_DMASTAT,loc_xhmta_return_for_tzm
	jclr #B__TMQ_ACTIVE,y:HW_Y_RUNSTAT,stu_TMQ_empty
	jsr service_tmq1	; execute timed messages for current tick

stu_TMQ_empty

;    finish off sound-in tick
;	  <test read-data bit>
;	  <if read-data happening, see if it's time to switch buffers>
	  remember 'read-data check not yet written in end_orcl'

;    finish off sound-out tick
;	write-data buffers are always written. Hence no jsset or jsclr here.
;
	jsr service_write_data1
;
	remember 'service_write_data1 could be moved to inline code above'
;;	NOTE: The 1.0 Music Kit uses an orchloopbegin which dispatches
;;	via hm_service_write_data to service_write_data1.
;;	Making this inline requires maintaining the service_write_data1
;;	entry point which means service_write_data1 must be last which
;;	means things happen here in a different order.  This change is 
;;	too scary for me to contemplate right now.

;    update sample counter (current time)
;
	move l:HW_L_TICK,A	; current tick to A
	move l:HW_L_TINC,B	; tick size in samples to B
	add B,A	  #<0,X0	; increment tick count, get a zero into X0
	tes X0,A		; roll over to zero on overflow (extension set)
	move A,l:HW_L_TICK	; save for next time around

; David says change this to 0 if we can't get the hanging to stop
; Nick 12/11/94

;;; Nick changed to 0 on 1/13/94 in an attempt to fix sporadic DSP behavior
;;; experienced by Andy, Scott, Tim & Nick (at request of daj)

      if 0
	if (SEND_KERN_ACKS)
	msg 'i am alive check enabled'
	move #>I_ALIVE_PERIOD,X0
	move y:HW_L_TICK,A	; get low portion of tick to A1
	and X0,A x:X_ALIVE,B	; Mask bit, get previous masked
	cmp B,A  A,x:X_ALIVE	; Equal? Save current
	jeq stu_no_ack		; Send ack only on transitions (neq)
        clr A #DE_KERNEL_ACK,X0 ; prepare for msg
        jsr dspmsg_noblock      ; send it
stu_no_ack
        endif
      endif

	unmask_host

	rts

;; ================================================================
	endif ; !AP_MON
;; ================================================================

;
; **************** MORE ROUTINES CALLED BY BOTH APMON AND MKMON ***************
;
	if SYS_DEBUG
abort_save
; Save everything we are about to change
	move X0,x:X_ABORT_X0	; save X0 for later inspection
	move A1,x:X_ABORT_A1	; save A1 for later inspection
	movec sp,A1
	move A1,x:X_ABORT_SP
	movec sr,A1
	move A1,x:X_ABORT_SR
	move x:$FFE8,A1	; HCR
	move A1,x:X_ABORT_HCR
	move x:$FFE9,A1	; HSR
	move A1,x:X_ABORT_HSR
	move R_HMS,x:X_ABORT_R_HMS
	move R_IO,x:X_ABORT_R_IO
	move M_IO,x:X_ABORT_M_IO
	move R_I1,x:X_ABORT_R_I1
	move x:X_DMASTAT,A1
	move A1,x:X_ABORT_DMASTAT
	move y:Y_RUNSTAT,A1
	move A1,x:X_ABORT_RUNSTAT
	rts
	endif 			; SYS_DEBUG
;; ================================================================
; abort - abort DSP execution
;;	  DMA in progress is completed. (A DMA read gets an abort symbol.)
;;	  Queued up DSP messages are sent out.
;;	  Execution stack is rolled back to 0.
;;	  Host interrupts are enabled.
;; 	  Host communication status is reset.
;;	  Falls into monitor mode awaiting debugger
;;
abort1
	bset #B__EXTERNAL_ABORT,x:X_DMASTAT 	; called via hmdispatch
	jset #B__ABORTING,y:Y_RUNSTAT,ab_nosave ; Don't save regs twice!
abort						; called internally
	bset #B__ABORTING,y:Y_RUNSTAT ; Inhibit DMA requests (host_xmt)

	if SYS_DEBUG
	  jsr abort_save
	endif
ab_nosave
	jsr dma_abort		; Let any DMA in progress finish, then disable
ab_buzz	jset_htie ab_buzz 	; let DSP messages out
	jsr abort_now		; never returns. We JSR to leave stack trail.

; ================================================================
; dma_abort - Let any DMA in progress finish, then return.
;	Called by abort(handlers.asm) & reset_soft(jsrlib.asm) (hence on boot)

dma_abort
		; First we must enable interrupts so that the DMA termination
		; host command can get through

		jsr abort_interrupt	; clear state associated with interrupt

;DAJ        	jclr  #B__SIM,y:Y_RUNSTAT,dmaa_ck_r ; SWI if simulating
;DAJ			SWI
;
;	Wait until DMA completes
;
dmaa_ck_r	jclr #B__HOST_READ,x:X_DMASTAT,dmaa_r_done ; check DMA read
		jclr_hf1 dmaa_r_done ; misc.asm	; HF1 <=> host DMA in progress
;*		bset_htie			; Is this needed sometimes?
		jmp dmaa_ck_r			; keep going until host_r_done
dmaa_r_done 	jsset #B__HOST_READ,x:X_DMASTAT,hm_host_r_done ; if hf1 cleared
dmaa_buzz	jset_hf1 dmaa_buzz	    	; if host_r_done only

	    if READ_DATA
		fail '*** FIXME *** Make rd case analogous to wd case'
	    endif ; READ_DATA

	    rts

; ============================================================================
; abort_interrupt - clear state associated with servicing an interrupt.
;; 	Call this routine to abort from interrupt level, e.g., during
;; 	the execution of a host message.  Called by hm_idle and abort
abort_interrupt
	bclr #B__ALU_SAVED,y:Y_RUNSTAT  ; We'll not restore ALU
	bclr #B__TEMPS_SAVED,y:Y_RUNSTAT ; nor temp regs (handlers.asm)
	bclr #M_HF2,x:M_HCR    		; clear "DSP Busy" flag
        move x:X_HMSRP,R_HMS 		; reset HMS write pointer back
        move R_HMS,x:X_HMSWP 		;   to read pointer to avoid arg error
        unmask_host   	   		; allow interrupts
	rts
;; ================================================================
; abort_now - abort DSP execution
;;	  Falls into monitor mode awaiting debugger
;;
abort_now  			; "abort" entry point is in hmdispatch.asm
	movec #$300,sr 		; disable interrupts to freeze things until
				; debugger (BUG56) arrives on the scene
	move x:$ffe8,A1		; get HCR
	move #>$18,X0	        ; set HF2 and HF3 to indicate we're done

	or X0,A
	move A1,x:$ffe8		; This tells the Mach world we've aborted

;; Wait for HF0 (HF0 alone means "abort DSP").  This is asserted by dspabort
;; when driver is put to sleep by setting ICR to 0.  Without this it is a race
;; between the driver and dspabort for the following output.  Note that there
;; is still the possibility that the driver will come back to life, set ICR to
;; 1, and intercept output below.  For this reason, the driver needs to be
;; modified (in the device interrupt loop: snd_dspdev.c near line 705)
;; to ignore DSP input (and in fact abort) when it sees HF2 and HF3 both set.

	await_hf0
	jset_hf1 an_send_start	; BUG56 sets HF0 and HF1 together

; Send stack pointer
	clr A #DE_SP,X0		; SP message code
	movec sp,A1		; SP to A1 for message
	or X0,A A,B		; install SP message code, and save SP in B
	write_htx A1

; Send PC backtrace
	tst B B,Y1		; Compare SP to 0, save original SP to Y1
	jle an_no_bt		; SP must be positive for backtrace to exist
	clr A #DE_PC,X0		; PC message code
an_bt	movec ssh,A1		; PC to A1, right justified (*pop*)
	or X0,A			; install "PC" message code
	write_htx A1		; send PC backtrace component
	move sp,B		; current sp to B
	tst B
	jgt an_bt		; send ssh until stack pointer is 0
an_no_bt
	move Y1,sp		; restore original SP
	write_htx #DEGMON_L+((DEGMON_H-DEGMON_L+1)*65536) ; for dspabort
	await_hf1		; HF0 and HF1 indicates debugger has control
	await_hf0		; Make sure this is still on
; send start address (bits 0..15) and length of DEGMON (bits 16..23) to BUG56:
an_send_start
	write_htx #DEGMON_L+((DEGMON_H-DEGMON_L+1)*65536)
	movec #0,sr  		; Allow host interrupts only to debugger
	move #>$BF080,X0	; Get "JSR" opcode (two-word type)
	movem X0,p:iv_swi_	; Install it at SWI vector
	move #>abort,X0		; What we use
	movem X0,p:(iv_swi_+1)
	DEBUG_HALT		; force a breakpoint

  if MOTO_EVM
	  include 'cs4215'    	; cs4215 codec code
  endif

