; hmlib.asm - Host message library
;
;; Copyright 1989,1990 NeXT Inc.
;; J.O. Smith
;;
;;   Included by allocsys.asm.
;;
;;   These routines comprise the set of possible HOST MESSAGES.
;; 
;;   A "host message" is defined as the host-initiated execution of a DSP
;;   subroutine at interrupt level.  The host writes the subroutine arguments
;;   to the DSP TX registers, each word written causing a fast DSP interrupt to
;;   place the arg on the Host Message Stack (HMS), and after all args are
;;   written, the host issues the "XHM" host command (meaning "execute host
;;   message").
;; 
;;   See /usr/local/lib/dsp/smsrc/handlers.asm for the xhm* host-command exception
;;   handlers and the jsr_hm routine that calls these routines, as well as
;;   all the other DSP exception handlers.
;;
;;  *** EACH ROUTINE HERE MAY BE CALLED AT HOST INTERRUPT LEVEL ***
;;	The xhm host-command handler calls (in handlers.asm) 
;;	  save_alu,   which saves A2,A1,A0,B2,B1,B0,X1,X0,Y1,Y0,  and
;;	  save_temps, which saves R_I1,R_I2,R_O,N_I1,N_I2,N_O,M_I1,M_I2,M_O
;;      Any other resources needed must be saved and restored explicitly here.
;;
;;  ***	R_I1 MUST BE SAVED AND RESTORED IF SUBROUTINES ELSEWHERE ARE CALLED
;;	SUCH AS IN JSRLIB.ASM.
;;
;;  *** On dismissal here, register R_I1 must point to one before the
;;	first host-message argument written by the host.
;;	This happens naturally when the arguments are consumed sequentially
;;	as y:(R_I1)+ for each argument. Each host message handler must
;;      make this condition true or else a DE_HMARGERR DSP message will
;;	be generated.  The check detects if there is
;;      an error in the number of arguments written by the host OR
;; 	the number consumed by the host message handler.  The checking
;;      of R_I1 is done at label xhm8 in handlers.asm.
;;
;;   Host messages to consider adding:
;;	getMemoryConstants (so memory-map can be changed on the fly)
;;
;; ----------------------------------------------------------------
;;
;;   The host message handlers below can be called in two ways:
;;	  (1) In response to an untimed host message
;;	  (2) By the service_tmq routine to execute a timed host message
;;
;;   Case (1) is at interrupt level, and case (2) is at user level.
;;
;; ----------------------------------------------------------------
;; Modification history
;;
;;  02/26/90/jos - Added timed-zero message support at idle_1 (grep TZM *.asm)
;;  05/04/90/jos - Flushed echo_0 loopback test code
;;  05/04/90/jos - Absorbed halt_0 into hm_halt
;;  05/16/90/jos - Absorbed remains of hmdispatch.asm into this file
;;
;; hmdispatch.asm post-1.0 modification history
;; ----------------------------------------
;; 05/05/90/jos - Moved hm_first to allocsys.asm!
;;                This is because we are flushing the dispatch table
;;                to enable dynamic adaptation to any memory size.
;;                Instead of indirect dispatch, we jump directly to
;;                any loaded subroutine, using the symbol table in the
;;                DSPLoadSpec to find the addresses at run time.
;; ----------------------------------------------------------------
;;   12/05/92/daj - Added poke_sci
;; HMS FORMAT
;;
;; Host Message Stack (HMS) state upon entry to any of the hm routines below:
;;
;;   See handlers.asm
;;
;; ----------------------------------------------------------------
;;
;; TMQ FORMAT
;;
;; Timed Message Queue (TMQ) state upon entry to any of the hm routines below:
;;
;; 		   TMQ_HEAD	   ; first free element (marked)
;;		       0 	   ; Empty message terminates TMQ (0 wd count)
;;		       0	   ; hi-order word of final time stamp = 0
;; x:X_TMQWP -->       0	   ; lo-order word of final time stamp = 0
;;		      <.>	   ; more messages
;;	link -->    TMQ_MEND	   ; non-opcode denoting end of message packet
;;	   	     <arg1>	   ; first argument written by host
;;	   	      ...	   ; other arguments (handler knows how many)
;;	  +          <argN>	   ; last argument or nargs
;;	  -	    <opcode>	   ; can cat opcodes (R_I1 updated in handler!)
;;	  	     <arg1>	   ; first argument written by host
;;	  	      ...	   ; other arguments
;;	R_I1 -->     <argN>	   ; last argument written by host (or nargs)
;;		    <opcode>	   ; host message dispatch address
;;		     <link>	   ; pointer to next msg, 0, or words remaining
;;		  <timeStampHi>	   ; high-order word of absolute time stamp
;;		  <timeStampLo>	   ; low-order word of absolute time stamp
;; x:X_TMQRP -->    TMQ_TAIL	   ; Tail marker
;;
;; NOTES
;; - When the TMQ is empty, x:X_TMQRP + 1 =  x:X_TMQWP, and the TMQ 
;;   consists of only a tail marker, a null message, and a head marker.
;; - If <link> is less than YB_TMQ, it is assumed to be a remaining-word count.
;; - If <link> is 0, opcodes are executed until TMQ_END appears where 
;;   the next opcode would. Multi-opcode execution is more dangerous because
;;   it relies on the corresponding host message handler returning with R_I1
;;   pointing to the next opcode. It is safer but slower to use only one 
;;   opcode per timed message.
;;
;;----------------------------------------------------------------

;; ================================================================
;; Unimplemented or discontinued host messages:
;; hm_echo              jmp >unwritten_subr
;; hm_reset_soft        jmp >unwritten_subr
;; hm_reset_ipr         jmp >unwritten_subr
;; hm_set_break         jmp >unwritten_subr
;; hm_clear_break       jmp >unwritten_subr
;; hm_step              jmp >unwritten_subr
;; hm_hms_room          jmp >unwritten_subr
;; hm_trace_on          jmp >unwritten_subr
;; hm_trace_off         jmp >unwritten_subr
;; hm_save_state        jmp >unwritten_subr ; host wants a total state dump
;; hm_load_state        jmp >unwritten_subr ; host wants to swap in new state
;; hm_adc_loop          jmp >unwritten_subr ; A/D conversion via serial port
;; hm_host_wd_done      jmp >unwritten_subr ; replaced by host_w_done + state
;; hm_stderr            jmp >stderr	   ; call dsp error handler remotely
;; hm_execute_hm 	execute code in HMS (see hm_execute_hm.asm)
;; hm_set_dma_r_m	poke DMA M read reg (now we directly poke X variables)
;; hm_set_dma_w_m	poke DMA M write reg
;; hm_set_tinc 		set current tick increment (now use poke long)
;; hm_set_time 		set current tick value (now use poke long)
;; hm_get_time 		set current tick value (now use peek long)
;; hm_set_start    	set start address
;
; **************** ROUTINES CALLED BY BOTH APMON AND MKMON *******************
;
;; ================================================================
; Quickies

hm_halt             DEBUG_HALT          ; Force break (fall into DEGMON)
                    rts

hm_block_on         bset #B__DMQ_LOSE,y:Y_RUNSTAT
                    rts                 ;* set run status to allow blocking

hm_block_off        bclr #B__DMQ_LOSE,y:Y_RUNSTAT
                    rts                 ;* set run status to stop blocking

; ================================================================
; hm_idle - Place DSP system in the idle state.
;		Only supported in SYS_DEBUG version
;;
;; Forcing idle from the host (via hm_idle) is useful for debugging.
;;   It changes the minimum amount of state necessary to get
;;   the DSP's attention.  After forcing idle, the host may
;;   read whatever state it wants with the DSP stopped.
;;
;;   FIXME: To really do this right, hm_idle should save
;;   all modified state before modifying.
;;
;; If a DMA read is in progress, it is terminated exactly
;; as in hm_host_r_done0 above.  The DM_HOST_R_DONE message
;; before the DM_IDLE message indicates that the DMA was aborted.
;;
hm_idle
	if !AP_MON
	jsr dma_abort		; Let any DMA in progress finish, then disable
	endif
	jsr abort_interrupt	; clear state associated with interrupt
idle_2  clr A #DM_IDLE,X0   	; tell host this happened (entry from reset_)
	jsr dspmsg	    	; ok to clobber registers
idle_1 
	if !AP_MON
	jsset #B__TZM_PENDING,x:X_DMASTAT,loc_xhmta_return_for_tzm
	endif
	jmp idle_1	  	; busy wait. * THIS IS THE DEFAULT IDLE LOOP *
;
; ================================================================
hm_dm_off    	; turn off DSP messages
		bset #B__DM_OFF,x:X_DMASTAT
		move #DM_DM_OFF,X0
dm_off_buzz	jclr #1,x:$FFE9,dm_off_buzz	; wait for HTDE
		move X0,x:$FFEB	; send final DSP message
		bclr #1,x:$FFE8	; Clear Host Transmit Intrpt Enable (HTIE)
		rts
; ================================================================
hm_dm_on    	; turn on DSP messages
		; Two "garbage words" will be read from the host interface
		; before the ack is seen.  The ack is effectively inserted
		; in front of all pending DSP messages.
		bclr #B__DM_OFF,x:X_DMASTAT
		move #DM_DM_ON,X0
dm_on_buzz	jclr #1,x:$FFE9,dm_on_buzz	; wait for HTDE
		move X0,x:$FFEB	; send message demarcating msg start
		bset #1,x:$FFE8	; Set Host Transmit Intrpt Enable (HTIE)
		rts
; ================================================================
; *** FIXME - The following can be replaced by a four-word generic array poke
;		(the 4th word being the M register which cannot be set here)
;		Be sure to use the poke mechanism, not a pseudo-DMA write!
;
; hm_host_r - host wants to read a block of data.
;
; ARGUMENTS (in the order written by the host)
;   space     - memory space of destination address (x=1,y=2,p=4)
;		or channel number if this is to satisfy a DSP-initiated
;		read-data request.
;   address   - address of first word
;		or zero to satisfy a DSP-initiated read-data request.
;   increment - skip factor (e.g. 1 means contiguous locations)
;
; Note that the M index register used in the transfer is x:X_DMA_R_M.
; This register defaults to -1 and can be set to any value via a host 
; message.
;
; Host-initiated reads such as this can only happen on channel 0.
; Hence no channel number argument.
;
; DESCRIPTION
;   The DMA channel is claimed and 
;   The R and N address registers for DMA reads are initialized.
;
hm_host_r
	move y:(R_I1)+,X0		; DMA skip factor (last arg)
	move X0,x:X_DMA_R_N		; save in user-initiated DMA chan data
	move y:(R_I1)+,X0		; DMA start address
	move X0,x:X_DMA_R_R		; save in user-initiated DMA chan data
	move y:(R_I1)+,X0		; memory space code (first arg)
	move X0,x:X_DMA_R_S		; save in user-initiated DMA chan data
	rts
; ================================================================
;  if INTEL  -- FIXME
; Note that we have to check for chan==0 all over and change it to chan!=1
; hm_host_r_req
;	; busy wait on B__HOST_READ set
;	jset #B__HOST_READ,x:X_DMASTAT,hm_host_r_req
;	jsr hm_host_r
;	move y:(R_I1)+,A		; channel
;	move #DM_HOST_R_SET1,X0		; HOST_R setup word 1
;	jsr dspmsg			; enqueue read request
;	rts
;  endif
; ================================================================
; hm_host_r_done - host has finished reading block of DSP private memory
;
;	Note that the current DMA channel number is stored in p:hx_channel
;	We can refer to it if we need to know.  There is also p:hx_space.
;
;	*** FIXME: Distinguish between DSP and host initiated DMA terminations.
;
hm_host_r_done
	jclr #B__HOST_READ,x:X_DMASTAT,hrd_ignore ; Not in pdma mode
			; The simulator can cause this in a case like
			; sound-out (see dspbeep.c). This means the r_done 
			; is lost.

	; ! exit_pdma_r_mode does not modify R_I1 and promises not to
	jsr exit_pdma_r_mode ; (handlers.asm) Restore DSP Message ntrpt handler

	; WD_PENDING is set within host_read_request when a write-data
	; is definitely the current DMA read to the host.  There is nothing
	; that can stop the write-data transfer except this host message.
	; (Actually, the hm_idle host message below will tear it down.)
	; No error termination is provided, so we assume a successful WD.
	;
	bclr #B__HOST_WD_PENDING,x:X_DMASTAT ; Clear pending DMA WD status

	move R_IO,A			; send address pointer as arg
	move #-1,M_IO			; not necessary, but convention
	move #DM_HOST_R_DONE,X0		; load message code
	or X0,A		    		; install opcode with arg
	move A,x:$FFEB			; overwrite 2nd garbage word with ack

	bclr #B__DM_OFF,x:X_DMASTAT	; enable DSP messages
;
;	  Note that the R_DONE ack gets inserted ahead of all pending
;	  DSP messages.  It is preceded by one garbage word in the
;	  host interface.  If a DM_ON message is sent before reading
;	  any words from RX, the DM_ON ack will follow immediately behind
;	  this ack.  Thus, you'll see <garbage-word>,R_DONE,DM_ON,<msg>,<msg>,
;
;*d*	  move x:X_SAVED_R_I1_DMA,R_I1	; to pass arg-check at xhm_host_r
	  ; leave HTIE set in case there are any waiting DSP msgs
hrd_ignore
	  rts  
; ================================================================
; hm_host_w - prepare DSP for DMA to private memory from host.
;
; ARGUMENTS (in the order written by the host)
;   space     - memory space of destination address (x=1,y=2,p=4)
;   address   - address of first word
;   increment - skip factor (e.g. 1 means contiguous locations)
;
;; Note that the M index register used in the transfer is x:X_DMA_R_M.
;; This register defaults to -1 and can be set to any value via a host 
;; message.
;;
;; Additional notes:
;;	Host should wait until the "HC" and "DSP Busy" Flags clear
;;	before starting transfer.  DMA channel 0 is implicit.
;;
;; DESCRIPTION
;;   This is how all DMA transfers are done from the host to the DSP.
;;   After this host message completes (HF2 clears), all writes by the
;;   host to the TX register will go to the destination set up by 
;;   this host message.  Host messages are therefore disabled.
;;   The transfer is terminated via the hc_host_w_done host command which
;;   terminates the routing of TX writes to the destination array
;;   and restores the normal routing of TX to the HMS.
;;
;;   Note: It is not actually necessary to place the DSP host interface
;;   in DMA mode for the "DMA write." Instead, a sequence of programmed 
;;   IO writes to the TX register can be performed with the same result.
;;
;;   Execution of this host command sets a status bit #B__HOST_WRITE. 
;;
;;   DMA writes (host to DSP) use R_HMS since there is no other use for it.
;;   DMA reads use R_IO since R_HMS is then useable for host messages.
;;   Consequently, a simulated DMA write (polling on TXDE) can go 
;;   simultaneously with a true DMA read.
;;
hm_host_w ; host wants to write a block of DSP private memory
	  jclr #B__HOST_WRITE,x:X_DMASTAT,dhw_ok ; this would kill saved regs
dhw_bad         move #DE_DMAWRECK,X0	; error code
	        jsr stderr		; issue error
dhw_ok	  bset #B__HOST_WRITE,x:X_DMASTAT ; claim DMA channel

	  move x:X_HMSRP,R_HMS		; Save *POPPED* HMS frame pointer
  	  move R_HMS,x:X_HMSWP		; (pop not executed on return)
	  move R_HMS,x:X_SAVED_R_HMS 	; Save HMS pointers for later restoral
	  move N_HMS,x:X_SAVED_N_HMS	; by host_w_done (below)
	  move M_HMS,x:X_SAVED_M_HMS
	  move y:(R_I1)+,N_HMS		; DMA skip factor (last arg)
	  move y:(R_I1)+,R_HMS		; DMA start address
	  move x:X_DMA_W_M,M_HMS	; indexing type

	  movem p:iv_host_rcv,X0	; Save host_rcv vector
	  move X0,x:X_SAVED_HOST_RCV1	;  = interrupt vector for HMS service
	  movem p:iv_host_rcv2,X0	; Save 2nd word of host_rcv vector
	  move X0,x:X_SAVED_HOST_RCV2	;  = nop normally
	  move y:(R_I1)+,A		; memory space code (first arg)
;*d*	  move R_I1,x:X_SAVED_R_I1_DMA	; save this for arg-check when done
	  move A1,N_I2			; offset
	  move #(*+3),R_I2		; pointer to 1st word of instruction -1
	  jmp >dhw1
dhw_x	  movep x:$FFEB,x:(R_HMS)+N_HMS	; DMA write to x data  memory
dhw_y	  movep x:$FFEB,y:(R_HMS)+N_HMS	; DMA write to y data  memory
dhw_l	  movep x:$FFEB,x:(R_HMS)+N_HMS	; DMA write to x data  memory
dhw_p	  movep x:$FFEB,p:(R_HMS)+N_HMS	; DMA write to program memory
dhw_nop	  nop
dhw1	  movem p:(R_I2+N_I2),X0	; 1st word of new host_rcv vector
	  movem X0,p:<iv_host_rcv	; Replace HMS host_rcv vector
	  movem p:dhw_nop,X0		; 2nd word of new host_rcv vector
	  movem X0,p:<iv_host_rcv2	; Drop it in place
;;	  bset #0,x:<HCR>		; Enable host_rcv interrupts (assumed)
	  ; Host knows we're ready for DMA by when HF2 clears => HC processed.
	  rts
;; ================================================================
; hm_host_w_done  - terminate host-initiated write to DSP private memory
;
; ARGUMENTS: None (The HMS is disabled until this is executed!)
; This routine is called by the hc_host_w_done host command handler.
; It is not really a host message.  As a result, its 
;
;; DESCRIPTION
;;   When the host-to-DSP DMA was host-initiated, we only
;;   revive host message service and free up the DMA channel. 
;;   When the DMA transfer was DSP-initiated, we in addition
;;   clear the read-data sync flag so that the DSP knows it is done.
;;
;; Note that a message handler hook hm_host_w_done is not necessary because
;; host_w_done cannot be called by a host message (die to the write in 
;; progress). Instead, host_w_done is always called by the "terminate write" 
;; host command.
;;
hm_host_w_done				; called by hc_host_w_done
	  move R_HMS,A			; DSP message argument below
	  move x:X_SAVED_R_HMS,R_HMS    ; restore HMS service
	  move R_HMS,x:X_HMSWP		; for xhm_done error detection
	  move x:X_SAVED_N_HMS,N_HMS
	  move x:X_SAVED_M_HMS,M_HMS
	  move x:X_SAVED_HOST_RCV1,X0	; Restore host_rcv exception vector
	  movem X0,p:iv_host_rcv	;  which services host messages
	  move x:X_SAVED_HOST_RCV2,X0	; Second word of host_rcv vector
	  movem X0,p:iv_host_rcv2	; Restore host_rcv exception vector
	  bclr #B__HOST_WRITE,x:X_DMASTAT    ; Let go of DMA channel
	  rts  
;
; **************************** NON-DMA IO ************************************

	if !AP_MON

peek_common 	tfr A,B
		and X0,A #DM_PEEK0,X0
		jsr dspmsg		; send low-order two bytes
		move B,X0 #>@pow(2,-16),Y0 ; right-shift 16 places
		mpy X0,Y0,A #>$FF,X0	; top byte of A1 to low byte, 16b mask
		and X0,A #DM_PEEK1,X0
		jsr dspmsg		; send high-order byte
	        rts
; ================================================================
; hm_peek_x - read a single word from x memory
;
; ARGUMENTS
;   address   - address of peek
;
hm_peek_x 	move y:(R_I1)+,R_I2	; memory address
		move #>$FFFF,X0		; 16-bit mask
		move x:(R_I2),A1	; peek's return value
		jmp peek_common
; ================================================================
; hm_peek_y - read a single word from y memory
;
; ARGUMENTS
;   address   - address of peek
;
hm_peek_y 	move y:(R_I1)+,R_I2	; memory address
		move #>$FFFF,X0		; 16-bit mask
		move y:(R_I2),A1	; peek's return value
		jmp peek_common
; ================================================================
; hm_peek_p - read a single word from p memory
;
; ARGUMENTS
;   address   - address of peek
;
hm_peek_p 	move p:(R_I1)+,R_I2	; memory address
		move #>$FFFF,X0		; 16-bit mask
		move p:(R_I2),A1	; peek's return value
		jmp peek_common
; ================================================================
; hm_peek_r           jmp >unwritten_subr ; read DSP register
; ================================================================
; hm_peek_n           jmp >unwritten_subr ; peek multiple words
; ================================================================

	endif ; !AP_MON

; hm_poke_x - write a single word into x memory
; ARGUMENTS (in the order written by the host)
;   value     - word to write at address
;   address   - address to poke
hm_poke_x 	move y:(R_I1)+,R_I2	; memory address
	        move y:(R_I1)+,X0	; value to poke
	        move X0,x:(R_I2)	; poke
	        rts
; ================================================================
; hm_poke_y - write a single word into y memory
; ARGUMENTS (in the order written by the host)
;   value     - word to write at address
;   address   - address to poke
hm_poke_y 	move y:(R_I1)+,R_I2	; memory address
	        move y:(R_I1)+,X0	; value to poke
	        move X0,y:(R_I2)	; poke
	        rts
; ================================================================
; hm_poke_p - write a single word into p memory
; ARGUMENTS (in the order written by the host)
;   value     - word to write at address
;   address   - address to poke
hm_poke_p 	move y:(R_I1)+,R_I2	; memory address
	        move y:(R_I1)+,X0	; value to poke
	        movem X0,p:(R_I2)	; poke
	        rts
; ================================================================
; hm_poke_l - write a single 48-bit word into l memory
; ARGUMENTS (in the order written by the host)
;   hi-order 24-bit word of new value
;   lo-order 24-bit word of new value
;   address to poke
hm_poke_l 	move y:(R_I1)+,R_I2	; memory address
	 	move y:(R_I1)+,X0	; low-order word
	        move y:(R_I1)+,X1	; high-order word
		move X,l:(R_I2)		; set it
	        rts
; ================================================================
; hm_poke_n - multi-word poke, space passed explicitly
; Prior to call, the array to be transferred has been pushed onto the 
; HMS in NATURAL order (i.e. do not push the array on backwards).
;
; ARGUMENTS (in the order written by the host)
;   count     - number of words to poke
;   skip      - skip factor (use positive number)
;   address   - *** last *** address to poke (transfer is in REVERSE order)
;   space     - memory space of poke
	        remember 'poke_n is for compacting TMQ. Put space code in MSB?'
hm_poke_n 	move #pn_tab,R_O	; table of transfer words
		move y:(R_I1)+,N_O	; space (xylp) = (1234)
		move y:(R_I1)+,R_I2	; last address
		move y:(R_I1)+,N_I2	; skip factor
		move p:(R_O+N_O),X0	; transfer instruction
		move X0,p:pn_xfer_ins	; self-modifying code
		do y:(R_I1)+,pn_loop
			move y:(R_I1)+,A	; get next word
pn_xfer_ins		move A,x:(R_I2)-N_I2	; deposit it
pn_loop
	        rts

pn_tab		nop			; space 0
		move A,x:(R_I2)-N_I2	; space 1 = x
		move A,y:(R_I2)-N_I2	; space 2 = y
		move A,l:(R_I2)-N_I2	; space 3 = l (should not be used)
		move A,p:(R_I2)-N_I2	; space 4 = p
; ================================================================
; hm_poke_r           jmp >unwritten_subr ; write DSP register
; ================================================================
; ******************************* CONTROL ************************************
; ================================================================
; hm_say_something - request "I am alive" message from DSP
hm_say_something move #>sys_ver,X0		; system version
		move #>@pow(2,-16),X1		; 1 byte leftshift = 2 byte rsh
		mpy X0,X1,A #>sys_rev,X0 	; system revision
		move A0,A1			; result in A0
		or X0,A				; install sys_rev
	   	move #DM_IAA,X0			; load message code
		jsr dspmsg			; send it along
		rts
; ===============================================================
; hm_go - start execution at start_address (written above)
;;
;; ARGUMENTS	none
;;
;;		Reset the system stack and start user at (x:X_START).
;;
;;		Enough cleanup is done here so that the user program
;;		need not begin with a reset_soft.  Normally, after a
;;		host message, the code following label xhm_done in 
;;		/usr/local/lib/dsp/smsrc/handlers.asm is executed.  The code here
;;		attempts to arrive at the same state.
;;
hm_go	       	move #0,sp		; clear stack
		clear_sp		; set stack ptr to base val (misc.asm)
		move x:X_HMSRP,R_HMS	; Read pointer. Points to first arg.
		move R_HMS,x:X_HMSWP	; R_HMS = write pointer
		bclr #B__ALU_SAVED,y:Y_RUNSTAT   ; We'll not restore ALU
		bclr #B__TEMPS_SAVED,y:Y_RUNSTAT ; nor temp regs (handlers.asm)
		jclr #B__HM_DONE_INT,y:Y_RUNSTAT,go_noint ; "done" msg req'd?
		   clr A #DM_HM_DONE,X0		; "host message done" message
		   jsr dspmsg
go_noint
		move x:X_START,ssh	; This sets sp to 1
		move #>0,ssl		; *** LEAVE INTERRUPTS ENABLED ***
		bclr #4,x:$FFE8		; Clear (HF3 = "TMQ full" or "AP busy")
		bclr #3,x:$FFE8 	; Clear (HF2 = "HC in progress")
		rti			; User is top level now
; ================================================================
; hm_execute - execute arbitrary instruction in arg1,arg2
;		Only supported in SYS_DEBUG version

xqt_0		dc 0	; this is where it actually gets executed
xqt_1		dc 0
		rts

hm_execute      ; execute arbitrary instruction in arg1,arg2
; ARGUMENTS (in the order written by the host)
;   word1   - first word of instruction to execute
;   word2   - second word of instruction to execute
	if SYS_DEBUG
		move X0,x:X_SAVED_X0
	        move y:(R_I1)+,X0		; 2nd word
	        move X0,p:xqt_0
	        move y:(R_I1)+,X0		; 1st word
	        move X0,p:xqt_1
		jsr xqt_0			; do it
		move x:X_SAVED_X0,X0
	        rts
	else
		jmp unwritten_subr
	endif
; ================================================================
; hm_jsr - execute arbitrary subroutine
;		Only supported in SYS_DEBUG version
;;
;; ARGUMENTS
;;   address   - address of DSP subroutine to execute
;;
;; DESCRIPTION
;;   Used to get around restriction that host messages be contained in this
;;   file
hm_jsr
	if SYS_DEBUG
 		move X0,x:X_SAVED_X0
		move y:(R_I1),X0	; JSR address to X0
	        move X0,p:>(*+3)	; Poke it into the following "JSR"
	         jsr >0	 ; This calls the routine (or RESET if we missed ha ha)
		move x:X_SAVED_X0,X0
		rts
	else
		jmp unwritten_subr
	endif
; ================================================================
; hm_hm_first - return first host-message dispatch address
hm_hm_first 	move #>hm_first,A1	; defined in allocsys.asm
	        move #DM_HM_FIRST,X0
		jsr dspmsg
	        rts
; ================================================================
; hm_hm_last - return last host-message dispatch address
hm_hm_last 	move #>hm_last,A1
	        move #DM_HM_LAST,X0
		jsr dspmsg
	        rts

; ================================================================
; hm_get_long - get long value from l memory
;; Value is sent via 3 normal DSP messages, LONG0,LONG1,LONG2. NOT OUT OF BAND.
hm_get_long 	
	        move y:(R_I1)+,R_I2	; address
		nop
		move l:(R_I2),Y		; desired value
		jsr send_long		; send it
	        rts

; ================================================================

; "JSR LIB" and "HANDLER" SUBROUTINES CALLABLE FROM C SOFTWARE
; ------------------------------------------------------------
;; The point of having this level of indirection is so that we can
;; enforce all host messages to be contained in this file, rather
;; than opening up all of jsrlib.asm and handlers.asm to become 
;; host message targets.  In allocsys.asm, where this file is included,
;; the start and end is measured and used by jsr_hm to check validity
;; of the dispatch.  If not for this validity checking, we could just
;; place an "hm_" prefix on the desired entry points wherever they occur
;; (in order for dspmsg to collect them as host message entry points)
;; and also xdef them there.

hm_main_done            jmp >main_done1 ; only in apmon, but asm'd in mkmon 
				; so mkmon.lod has ap globals for dspmsg

        if AP_MON
hm_abort                jmp >abort_now
        else
hm_abort                jmp >abort1	; *** FIXME: already have abort HC!
hm_service_tmq          jmp >service_tmq1
hm_write_data_switch    jmp >write_data_switch1
hm_service_write_data   jmp >service_write_data1
	; FIXME: remove above dispatch


; *****************************************************************************
; hmlib_mk.asm - included by hmlib.asm for !AP_MON case (Music Kit Monitor)
;
; *****************************************************************************
; *****************************************************************************
; ********************** ROUTINES CALLED BY MKMON ONLY ************************
; *****************************************************************************
; *****************************************************************************
;
; ******************************* CONTROL ************************************

; Quickies

; *** FIXME: Replace these with a single "set bit" call. Place "B__"
;	     symbols in symbol table so they're known in C.

hm_tmq_lwm_me       bset #B__TMQ_LWM_ME,y:Y_RUNSTAT
                    rts                 ;* enable message on TMQ low-water mark

hm_done_int         bset #B__HM_DONE_INT,y:Y_RUNSTAT
                    rts                 ;* interrupt host when host msg done

hm_done_noint       bclr #B__HM_DONE_INT,y:Y_RUNSTAT
                    rts                 ;* interrupt on host msg done

hm_normal_srate     bclr #B__HALF_SRATE,y:Y_RUNSTAT
                    rts                 ;* select high sampling rate

hm_half_srate       bset #B__HALF_SRATE,y:Y_RUNSTAT
                    rts                 ;* select low sampling rate

hm_close_paren      bclr #B__TMQ_ATOMIC,x:X_DMASTAT ;* end atomic TMQ block
                    rts

hm_unblock_tmq_lwm  bclr #B__BLOCK_TMQ_LWM,y:Y_RUNSTAT
                    rts                 ;* disable blocking

hm_open_paren 		bset #B__TMQ_ATOMIC,x:X_DMASTAT 
			bset #B__TMQ_ACTIVE,y:Y_RUNSTAT ; To block if need be
			rts

hm_block_tmq_lwm 	bset #B__BLOCK_TMQ_LWM,y:Y_RUNSTAT ; Block on TMQ empty
			bset #B__TMQ_ACTIVE,y:Y_RUNSTAT ; To block if need be
			rts

; ******************************* QUERY ************************************
;
; ================================================================
; hm_tmq_room - determine free space in timed message queue (in words)
hm_tmq_room 	jsr measure_tmq_room	; jsrlib.asm ... result in A
		move #DM_TMQ_ROOM,X0	; opcode
		jsr dspmsg
	        rts
; ******************************* DMA IO ************************************
;
; ================================================================
; hm_clear_dma_hm - init state of sound buffers to turned off & clear condition
;		 Buffers are not zeroed. Use hm_fill_y.
;
hm_clear_dma_hm move R_I1,x:X_SAVED_R_I1_HMLIB ; only R_I1 needs saving
	     	jsr clear_dma_ptrs ; jsrlib - flush and reset DMA pointers
		jsr wd_buffer_clear ; zero out write-data buffers
		if SSI_READ_DATA    ; Was READ_DATA-DAJ
		   jsr rd_buffer_clear ; zero out read-data buffers
		endif
		move x:X_SAVED_R_I1_HMLIB,R_I1
	        rts
; ================================================================
; hm_host_rd_on - host ready to supply read data
		; Called by DSP driver.
hm_host_rd_on 	move y:(R_I1)+,A	; channel number (ignored)
		if READ_DATA
		bset #B__HOST_RD_ENABLE,x:X_DMASTAT
		remember 'Must now share i/o buf pool between RD and WD'
		endif
		rts
; ================================================================
; hm_host_rd_off - host has no more read data
hm_host_rd_off 	move y:(R_I1)+,A	; channel number
		if READ_DATA
	        bclr #B__HOST_RD_ENABLE,x:X_DMASTAT
		endif
		rts
; ================================================================
; Write-data (WD) enables
;
; Before WD is enabled, the write-data buffer ring is freely written
; by the orchestra loop without waiting for buffers to be read by the
; host and without sending DMA requests to the host. When WD is enabled,
; a DMA request goes out immediately for the currently filling buffer.
;
; When a host_wd_off is received to disable WD, the effect is to
; inhibit the generation of future DMA requests (see write_data_buffer_out
; in jsrlib.asm).
;
; ================================================================
; hm_host_wd_on - host ready to take write data
hm_host_wd_on 	move y:(R_I1)+,A	; channel number (ignored. should be 1)
		move R_I1,x:X_SAVED_R_I1_HMLIB ; only R_I1 not saved
		jsr wd_buffer_clear
	        bset #B__HOST_WD_ENABLE,x:X_DMASTAT
		jscc wd_dma_request
		move x:X_SAVED_R_I1_HMLIB,R_I1
		rts
; ================================================================
; hm_host_wd_off - host does not want write data
hm_host_wd_off 	move y:(R_I1)+,A	; channel number
		move #>1,X0		; channel 1
		cmp X0,A		; only channel 1 supported now
		jeq hwoff_ok
			DEBUG_HALT
hwoff_ok 	
		if 0
		  remember 'Write-data termination disabled'
		  remember 'Real fix is to allow any pending DMA to finish'
		else
		  remember 'Write-data termination ENABLED => ENDGAME CAN HANG'
		  remember 'Real fix is to allow any pending DMA to finish'
		  bclr #B__HOST_WD_ENABLE,x:X_DMASTAT
		endif
		rts
; ================================================================
hm_dma_rd_ssi_on    jsr start_ssi_read_data
                    rts                      ;* sum in read data from ssi

; ================================================================
hm_dma_rd_ssi_off   jsr stop_ssi_read_data
                    rts                      ;* no read data from ssi (default)

; ================================================================
; hm_dma_wd_ssi_on - forward write data to ssi. requires !hub/sat wd/rd
hm_dma_wd_ssi_on 	jsr start_ssi_write_data
	 		rts
; ================================================================
; hm_dma_wd_ssi_off - no write data to ssi
hm_dma_wd_ssi_off	jsr stop_ssi_write_data
			rts
; ================================================================
  if QP_SAT
; hm_dma_wd_hub_on - forward write data to hub. requires !ssi wd
hm_dma_wd_hub_on 	jsr start_hub_write_data
	 		rts
  endif
; ================================================================
  if QP_SAT
; hm_dma_wd_hub_off - no write data to hub
hm_dma_wd_hub_off	jsr stop_hub_write_data
			rts
  endif
; ================================================================
  if QP_HUB
hm_dma_rd_sat_on    jsr start_sat_read_data
                    rts                      ;* read data from satelites

  endif
; ================================================================
  if QP_HUB
hm_dma_rd_sat_off   jsr stop_sat_read_data
                    rts                      ;* no read data from satelites
  endif
; ================================================================
  if QP_HUB
hm_dram_refresh_on  
    jset #B__DRAM_AUTOREFRESH,y:DEVSTAT,_dram_on_no_change      ; already on
    bset #B__DRAM_AUTOREFRESH,y:DEVSTAT				; turn on mode
    jset #B__DRAM_ACCESSING,y:DEVSTAT,_dram_on_no_change	; in access block
    bset #7,y:Y_QP_MASTER_CTL					; turn refresh on
_dram_on_no_change
    rts
  endif
; ================================================================
  if QP_HUB
hm_dram_refresh_off  
    jclr #B__DRAM_AUTOREFRESH,y:DEVSTAT,_dram_off_no_change     ; already off
    bclr #B__DRAM_AUTOREFRESH,y:DEVSTAT				; turn off mode
    jclr #B__DRAM_ACCESSING,y:DEVSTAT,_dram_off_no_change	; in access block
    bclr #7,y:Y_QP_MASTER_CTL					; turn refresh off
_dram_refoff jset #7,y:Y_QP_MASTER_CTL,_dram_refoff  ; wait for it to really turn off
_dram_off_no_change
    rts
  endif
; **************************** NON-DMA IO ************************************
; Fill's are not in the AP monitor because there are AP modules for that.
; ================================================================
; hm_fill_x - set x memory block to a constant
; ARGUMENTS (in the order written by the host)
;   count     - number of elements
;   value     - word to write at address through address+count-1
;   address   - first address to write
hm_fill_x 	move y:(R_I1)+,R_I2	; memory address
	        move y:(R_I1)+,X0	; value to poke
		do y:(R_I1)+,fill_x_loop
		        move X0,x:(R_I2)+	; poke
fill_x_loop		
	        rts
; ================================================================
; hm_fill_y - set y memory block to a constant
hm_fill_y 	move y:(R_I1)+,R_I2	; memory address
	        move y:(R_I1)+,X0	; value to poke
		do y:(R_I1)+,fill_y_loop
		        move X0,y:(R_I2)+	; poke
fill_y_loop		
	        rts
; ================================================================
; hm_fill_p - set p memory block to a constant
hm_fill_p 	move y:(R_I1)+,R_I2	; memory address
	        move y:(R_I1)+,X0	; value to poke
		do y:(R_I1)+,fill_p_loop
		        move X0,p:(R_I2)+	; poke
fill_p_loop
	        rts
; ================================================================
; hm_poke_sci - write a single word into sci transmit register STX, 
;		waiting if needed.  Note that only one byte of the
;               word is actually transferred.  See DSP manual for
;               explanation.
; ARGUMENTS (in the order written by the host)
;   value     - word to write at address (only one byte will be used)
;   address   - address to poke. One of x:$fff3,x:fff4,x:fff5,x:fff6
hm_poke_sci 	
		move y:(R_I1)+,R_I2	; memory address
	        move y:(R_I1)+,X0	; value to poke
		; Wait for TDRE (transmit data register empty) 
		; 	to be set in SCI status register
wait_sci_free	jclr #M_TDRE,x:M_SSR,wait_sci_free 
	        move X0,x:(R_I2)	; poke 
	        rts
;
; ================================================================
; BLT's are not in the AP monitor because there are AP modules for that.
; ================================================================
; hm_blt_x - block transfer in x memory
;
; ARGUMENTS (in the order written by the host)
;   count	- number of elements
;   source    	- first address to read
;   sourceskip	- skip factor for source block (1 is typical)
;   dest      	- first address to write
;   destskip	- skip factor for dest block (1 is typical)
;
; NOTES: 
;	If the source and destination blocks overlap, and the skip factors
;	are positive, we must have source>dest.  In other words, normal
;	overlapping block transfers must move to a smaller address.
;
;	However, by setting the skip factors negative and the source and
;	dest address to the last element of the desired blocks, a forward
;	overlapping block transfer can be accomplished.  
;
;	Finally, by setting one skip factor negative and the other positive, a
;	block of DSP memory can be reversed in order.
;
hm_blt_x	move y:(R_I1)+,N_I2	; destination skip factor
	        move y:(R_I1)+,R_I2	; destination memory address
	        move y:(R_I1)+,N_O	; source skip factor
	        move y:(R_I1)+,R_O	; source memory address
		do y:(R_I1)+,blt_x_loop
		        move x:(R_O)+N_O,X0
		        move X0,x:(R_I2)+N_I2
blt_x_loop
	        rts
; ================================================================
; hm_blt_y - block transfer in y memory
hm_blt_y 	move y:(R_I1)+,N_I2	; destination skip factor
	        move y:(R_I1)+,R_I2	; destination memory address
	        move y:(R_I1)+,N_O	; source skip factor
	        move y:(R_I1)+,R_O	; source memory address
		do y:(R_I1)+,blt_y_loop
		        move y:(R_O)+N_O,X0
		        move X0,y:(R_I2)+N_I2
blt_y_loop
	        rts
; ================================================================
; hm_blt_p - block transfer in p memory
hm_blt_p 	move y:(R_I1)+,N_I2	; destination skip factor
	        move y:(R_I1)+,R_I2	; destination memory address
	        move y:(R_I1)+,N_O	; source skip factor
	        move y:(R_I1)+,R_O	; source memory address
		do y:(R_I1)+,blt_p_loop
		        move p:(R_O)+N_O,X0
		        move X0,p:(R_I2)+N_I2
blt_p_loop
	        rts
; ================================================================
; hm_sine_test - perform sine test
hm_sine_test 	move y:(R_I1)+,X0	; duration of test in output buffers
		if !ASM_BUG56_LOADABLE
		  jmp sine_test		; resets back to idle loop when done
		else
		  jmp unwritten_subr
		endif

; ================================================================
; hm_host_w_dt - host write deferred termination (read-data only)
		; Called by DSP driver.
		remember 'need to add support for channel number argument'
hm_host_w_dt 	move y:(R_I1)+,X0	; channel number
		bset #B__HOST_RD_OFF_PENDING,x:X_DMASTAT
		rts

; ================================================================
; hm_host_w_swfix - same as hm_host_w but with software fix for DMA problem
		; into DSP.  Fix is to throw away the 1st chunk (4 words)
		; of the transfer. Called by DSP driver itself.
		; 3/10/91/jos - ripped out since not being used.

hm_host_w_swfix rts

; ================================================================
; hm_host_rd_done - Tell DSP last DMA was an RD buffer
; ARGUMENT
;   chan       - read data channel whose request was satisfied
;
; *** FIXME: Not supported by driver.
;	Need to infer this from hm_host_r_done by means of bit set
;	when transfer was started by hm_host_r.  There we can tell
;	DSP-initiated case by 0 address and RD channel # in space code.

hm_host_rd_done move y:(R_I1)+,X0	; read data channel (always 1 for now)
		bclr #B__HOST_RD_PENDING,x:X_DMASTAT ; should be per channel
		bclr #B__RD_BLOCKED,y:Y_RUNSTAT ; should be per channel
		bchg #B__READ_RING,x:X_DMASTAT ; should be per channel
			; We can change the above to B__RBUF_PARITY
		rts
; ================================================================
	endif ; !AP_MON (end of hmlib_mk include)

