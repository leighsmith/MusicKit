; x system environment variables
;
;; Copyright 1989, NeXT Inc.
;; Author - J.O. Smith
;;
;; This file is 'included' by /usr/local/lib/dsp/smsrc/allocsys.asm
;; The allocation is in /usr/local/lib/dsp/smsrc/config.asm (I_NXE_SYS)
;;
;; *** TO ADD AN XE MEMORY VALUE ***
;;
;;    (1) Add it's DC statement
;;    (2) Add init code in reset_boot.asm(reset_soft) if it matters.
;;    (3) Increase I_NXE_SYS in config.asm for BOTH AP AND MK CASES!
;;
;; If the name begins with "X_", it will be found in the output
;; symbol table by dspmsg and written to <dsp/dsp_memory_map.h>.
;;

; *** DATA ***

X_START   dc $80	 	; Current user start address
X_HMSRP	  dc YBTOP_HMS-1      	; Host Message Stack Read Pointer
X_HMSWP	  dc YBTOP_HMS-1      	; Host Message Stack Write Pointer

X_DSPMSG_X1		dc 0
X_DSPMSG_X0		dc 0
X_DSPMSG_B2		dc 0
X_DSPMSG_B1		dc 0
X_DSPMSG_B0		dc 0
X_DSPMSG_A1		dc 0
X_DSPMSG_R_O		dc 0
X_DSPMSG_M_O		dc 0

X_XHM_R_I1		dc 0	; used by hc_xhm handler

;
; Channel 0 DMA descriptors ("chan data" for user-initiated DMA transfers)
;
X_DMA_R_S		dc 0	; Memory space (xylp=1234) of DMA read
X_DMA_R_R		dc 0	; R register used by DMA reads
X_DMA_R_N		dc 0	; N register used by DMA reads
X_DMA_R_M		dc -1	; M register used by DMA reads

X_DMA_W_S		dc 0	; Memory space (xylp=1234) of DMA write
X_DMA_W_R		dc 0	; R register used by DMA writes
X_DMA_W_N		dc 0	; N register used by DMA writes
X_DMA_W_M		dc -1	; M register used by DMA writes

;
; DSP-initiated DMA descriptors.  Up to 16 of these can be set up
;
X_DMA1_R_S		dc 0	; Memory space (xylp=1234) of DMA read
X_DMA1_R_R		dc 0	; R register used by DMA reads
X_DMA1_R_N		dc 0	; N register used by DMA reads
X_DMA1_R_M		dc -1	; M register used by DMA reads 

	if READ_DATA
X_DMA1_W_S		dc 0	; Memory space (xylp=1234) of DMA write
X_DMA1_W_R		dc 0	; R register used by DMA writes
X_DMA1_W_N		dc 0	; N register used by DMA writes
X_DMA1_W_M		dc -1	; M register used by DMA writes
	endif

; *** SAVED REGISTERS (written/restored by host command interrupt handlers) ***
; For interrupt handlers at priorities other than that of host commands, 
; the name segment "SAVED" should be replaced by "FOO_SAVED" where FOO
; is the name of the different priority level. Thus, "X_SAVED..." is short
; for "X_HOST_SAVED...".
; 
X_SAVED_REGISTERS

X_SAVED_R_I1		dc 0      ; etc
X_SAVED_R_I2		dc 0
X_SAVED_R_O		dc 0
X_SAVED_N_I1		dc 0
X_SAVED_N_I2		dc 0
X_SAVED_N_O		dc 0
X_SAVED_M_I1		dc 0
X_SAVED_M_I2		dc 0
X_SAVED_M_O		dc 0
X_SAVED_X1		dc 0
X_SAVED_X0		dc 0
X_SAVED_Y1		dc 0
X_SAVED_Y0		dc 0

X_SAVED_A2		dc 0
X_SAVED_A1		dc 0
X_SAVED_A0		dc 0

X_SAVED_B2		dc 0
X_SAVED_B1		dc 0
X_SAVED_B0		dc 0

X_SAVED_HOST_RCV1	dc 0      ; Saved host_rcv interrupt vector, word 1
X_SAVED_HOST_RCV2	dc 0      ; Saved host_rcv interrupt vector, word 2
X_SAVED_HOST_XMT1	dc 0      ; Saved host_xmt interrupt vector, word 1
X_SAVED_HOST_XMT2	dc 0      ; Saved host_xmt interrupt vector, word 2

X_SAVED_R_HMS		dc 0      ; Saved HMS-buffer index register
X_SAVED_N_HMS		dc 0      ; Saved HMS-buffer increment register
X_SAVED_M_HMS		dc 0      ; Saved HMS-buffer modulo register

X_DMQRP	  dc YB_DMQ	      ; DSP Message Queue Read Pointer
X_DMQWP	  dc YB_DMQ	      ; DSP Message Queue Write Pointer

X_SCRATCH1		dc $0	; scratch memory for USER LEVEL ONLY
X_SCRATCH2		dc $0

X_SYS_CALL_ARG		dc 0	; int argument to hc_sys_call host command

	if SYS_DEBUG
X_ABORT_RUNSTAT		dc 0
X_ABORT_DMASTAT		dc 0
X_ABORT_X0		dc 0	; changed in hmlib.asm: host_r_done0
X_ABORT_A1		dc 0	; multiple changes
X_ABORT_SP		dc 0	; 
X_ABORT_SR		dc 0
X_ABORT_HCR		dc 0
X_ABORT_HSR		dc 0
X_ABORT_R_HMS		dc 0
X_ABORT_R_I1		dc 0
X_ABORT_R_IO		dc 0	; what use are these? (can't resume DMA)
X_ABORT_M_IO		dc 0	; they are clobbered in host_r_done0
	endif

	if !AP_MON		; AP_MON only needs those above. MK needs rest:

; more saved registers
X_SAVED_SR		dc 0      ; Saved status register
X_SAVED_R_I1_HMLIB	dc 0      ; Saved HMS arg ptr when jsr'ing out of hmlib

   if QP_HUB
     if SYS_DEBUG
X_QPSTAT dc 0
X_QPSTAT2 dc 0
     endif
X_SAT1_RFB dc 0
X_SAT1_REB dc 0
X_SAT1_REP dc 0
X_SAT2_RFB dc 0
X_SAT2_REB dc 0
X_SAT2_REP dc 0
X_SAT3_RFB dc 0
X_SAT3_REB dc 0
X_SAT3_REP dc 0
X_SAT4_RFB dc 0
X_SAT4_REB dc 0
X_SAT4_REP dc 0

X_SAT_R_INCR dc I_NTICK*2	; Will be set to correct value in system
   endif

X_NCHANS  	dc I_NCHANS	; No. of audio channels computed
X_NCLIP   	dc $0		; No. times limit bit set at end of orch loop
X_SCI_COUNT	dc 0		; timer interrupt count (cf. sci_timer handler)

X_TMQRP	  dc YB_TMQ	      ; Timed Message Queue Read Pointer (see end_orcl)
X_TMQWP	  dc YB_TMQ	      ; Timed Message Queue Write Pointer (see xhmta)

  if QP_SAT
X_QPSTAT dc 0			
  endif

X_O_SFRAME_W dc 2			; Output sample frame write increment
X_O_SFRAME_R dc 2			; Output sample frame read increment
X_O_CHAN_COUNT dc 2			; Output channels
X_O_TICK_SAMPS dc I_NTICK*2		; Output samples per tick

X_I_SFRAME_W dc 2			; Input sample frame write increment
X_I_SFRAME_R dc 2			; Input sample frame read increment

X_O_CHAN_OFFSET dc 1			; Output channel B offset
X_I_CHAN_OFFSET dc 1			; Input channel B offset

X_O_PADDING dc 0			; Output channel padding
					; This is the number of extra samples
					;    	between the last output channel
					; 	and the next sample frame.

;;  if (SEND_KERN_ACKS)
X_ALIVE dc 0				; Place for previous masked sample count
					; Used for sending "I am alive" msg
;;  endif

X_IN_INITIAL_SKIP dc 0				; Input samples to receive before data
X_OUT_INITIAL_SKIP dc 0				; Output samples to send before data

   if SSI_READ_DATA
X_IN_INCR dc I_NTICK*2		; Used internally by system
   endif

X_SSI_SAVED_1		dc 0      ; etc
X_SSI_SAVED_2		dc 0      ; etc

; For DSP-to-host DMA ("write-data"):
; The "filling buffer" and "emptying buffer" addresses exchange on every "fill"
X_DMA_WFB dc YB_DMA_W	 ; Current "write-filling" buffer start address
X_DMA_WFP dc YB_DMA_W	 ; Current "write-filling" pointer
X_DMA_WFN dc YB_DMA_W	 ; Next "write-filling" pointer
X_DMA_WEB dc YB_DMA_W2	 ; Current "write-emptying" buffer start address

; For host-to-DSP DMA ("read-data"):
; The "filling buffer" and "emptying buffer" addresses exchange on every "empty"
X_DMA_RFB dc YB_DMA_R	 ; Current start address of "read-filling" buffer
X_DMA_REB dc YB_DMA_R2	 ; Corresponding "read-emptying" buffer
X_DMA_REN dc YB_DMA_R2	 ; Next "read-emptying" pointer
X_DMA_REP dc YB_DMA_R2	 ; Current "read-emptying" pointer

X_SSI_RFB dc YB_DMA_R	 ; Current start address of "read-filling" buffer
X_SSI_REP dc YB_DMA_R	 ; SSI "read-filling" pointer
X_SSI_REN dc YB_DMA_R	 ; Next SSI "read-filling" pointer 
X_SSI_REB dc YB_DMA_R2	 ; Corresponding "read-emptying" buffer

X_SSI_SBUFS dc 0	 ; Current count of bufs before SSI start-up
X_SSI_SBUFS_GOAL dc 51	 ; Number of bufs that SSI in waits before start-up

  if MOTO_EVM
X_CODEC_CTL1 dc $309400	 ; See DSPSerialPortDevice.m and cs4215.asm
X_CODEC_CTL2 dc $a20000  ; All these values are reset by the Music Kit
X_CODEC_STAT1 dc $c60600
X_CODEC_STAT2 dc $10f000
  endif

; *** CHECKS ***

TEMP	  set @CVF(I_NDMA)/@CVF(I_NCHANS)
	  if TEMP!=@FLR(TEMP)
	       fail 'Number of channels must divide DMA buffer length'
	  endif

; Taken care of elsewhere:
; X_ZERO  dc 0		 ; Zero (actually h.o.w. of l:L_ZERO. See sys_li)

; Maybe some day:
; X_NDEC  dc I_NDEC	 ; Envelope decimation factor for digital audio


	endif ; !AP_MON






