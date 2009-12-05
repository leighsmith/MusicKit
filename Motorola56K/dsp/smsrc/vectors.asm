; vectors.asm - DSP 56001 interrupt vector contents
;;
;; Copyright 1989, NeXT Inc.
;; Author - J.O. Smith
;;
;;   Included by ./allocsys.asm.
;;   These vectors call routines in ./handlers.asm.
;;   They are installed last to avoid forward references to the handlers.
;;   (which triggered complaint from the assembler).
;;
;;   *** WARNING ***
;;   A single two-word instruction used as a fast interrupt
;;   vector will most definitely run the risk of at some point returning
;;   from the fast interrupt to a JSR instruction in the main program code
;;   which will result in the status register interrupt mask bits being updated
;;   as if a long interrupt routine had been invoked.  As I understand it
;;   this bug is in all the 56000 revisions that have been released to date. 
;;   4/12/89.  {This comment is probably no longer true--12/18/92}
;;
;; 05/26/90/jos - added iv_host_r and iv_host_w host commands.
;;

vectors	       ident 0,9	 ; Install two-word interrupt vectors

; ------------------- INTERRUPT VECTORS ----------------

	       if *!=0
	       fail 'attempt to load interrupt vectors other than at p:0'
	       endif

		org p_i:0	; can't be anywhere else
iv_reset_       jsr >reset_boot ; reset vector for offchip boot load
				; after boot, "jsr reset_" used instead
iv_stk_err     	DEBUG_HALT	;stack overflow error
		nop
iv_trace_      	DEBUG_HALT
		nop
iv_swi_	       	DEBUG_HALT
		nop
  if QP_SAT
iv_irq_a	jsr >abort1
iv_irq_b       	movep y:(R_IO)+,y:Y_QP_DATA ; write data 
iv_irq_b2      	nop
  else
iv_irq_a       	jsr >abort1 ; external abort
iv_irq_b       	jsr >abort  ; internal abort
  endif
; iv_ssi_rcv	jsr >ssi_rcv
iv_ssi_rcv     	movep x:M_RX,y:(R_IO2)+  ; deposit input sample to input buffer
iv_ssi_rcv2	nop
iv_ssi_rcv_exc 	jsr >ssi_rcv_exc
; iv_ssi_xmt     	jsr >ssi_first_xmt
; iv_ssi_xmt2     equ iv_ssi_xmt+1
iv_ssi_xmt	movep y:(R_IO)+,x:M_TX
iv_ssi_xmt2	nop
iv_ssi_xmt_exc 	jsr >ssi_xmt_exc
iv_sci_rcv     	DEBUG_HALT
		nop
iv_sci_rcv_exc 	DEBUG_HALT
		nop
iv_sci_xmt     	DEBUG_HALT
		nop
iv_sci_idle    	DEBUG_HALT
		nop
iv_sci_timer   	jsr >sci_timer
iv_nmi	 	DEBUG_HALT
		nop
iv_host_rcv    	movep x:$FFEB,y:(R_HMS)- ; write (circular) Host Message Queue
iv_host_rcv2   	nop
;* iv_host_rcv    movep x:$FFEB,A
;* iv_host_rcv2   movep A,x:$FFEB
iv_host_xmt    	jsr >host_xmt
;* This version gets a relative symbol!: iv_host_xmt2   equ p:iv_host_xmt+1
iv_host_xmt2   	equ iv_host_xmt+1
iv_host_cmd    	jsr >hc_host_r_done  	; Terminate DMA read from host

	       	if (*!=$26) ; make sure * points to first host command vector
DOT_HC		    set *   ; This gets * into listing file
		    fail 'vectors.asm: interrupt handlers off.	*!=$26'
	       	endif

iv_xhm	       	jsr >hc_xhm    		; Execute Host Command ($26)
iv_dhwd        	jsr >hc_host_w_done  	; Terminate DMA write from host ($28)
iv_kernel_ack  	jsr >hc_kernel_ack  	; kernel acknowledge ($2A)
iv_sys_call  	jsr >hc_sys_call  	; system call ($2C)
iv_abort_hang  	jsr >hc_abort_hang	; for debugging ($2E)

		if *>DEGMON_L
		    fail 'vectors.asm: interrupt handlers run into DEGMON'
		endif

iv_wasted	set DEGMON_L-*		; available for user host commands

		dup iv_wasted
			nop
		endm

degmon_l


