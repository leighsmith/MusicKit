; allocsys.asm - system memory allocation and initialization
;
;; Copyright 1989, NeXT Inc.
;; Author - J.O. Smith
;;
;; Included by /usr/local/lib/dsp/smsrc/music_macros.asm
;;
;; System memory should be allocated and initialized before the user
;; starts allocating. This file should be included before allocusr.asm
;; or not at all if no system code or symbols desired. 
;;
; SYSTEM DATA MEMORY INITIALIZATION (allocation done in /usr/local/lib/dsp/smsrc/memmap.asm)

     org p_i:0		; point to beginning of internal p memory
     org x_i:XLI_SYS	; point to beginning of internal system x data
     org y_i:YLI_SYS	; point to beginning of internal system y data
     org l_i:LLI_SYS	; point to beginning of internal system l data
     org p_e:PLE_SYS	; point to beginning of external system p code
     org x_e:XLE_SYS	; point to beginning of external system x data
     org y_e:YLE_SYS	; point to beginning of external system y data

; Internal system storage
; -----------------------

	  org l_i:	      ; point to beginning of internal system l data
	  include 'sys_li'    ; Declare and init l internal system vars
	  if (*-LLI_SYS)!=NLI_SYS
		if DBL_BUG&&((*-LLI_SYS)!=2*NLI_SYS)
		   fail 'sys_.asm: memmap.asm/NLI_SYS disagrees with sys_li.asm'
		endif
	  endif

	  org x_i:	      ; Point to beginning of internal system x data
	  if NXI_SYS>0
	     include 'sys_xi'    ; Declare and init x internal system vars
	     symobj NXI_LOST
NXI_LOST     set *-1-XHI_SYS     ; No. of internal words overflow
nxi_free_sys equ -NXI_LOST    ; how much wasted space in partition
	     if NXI_LOST>0
	       fail 'sys_.asm: xi overflow. Increase memmap.asm/NXI_SYS'
	       msg 'Find NXI_LOST above or in symbol table'
	     endif
	  endif

	  org y_i:	      ; point to beginning of internal system y data
	  if NYI_SYS>0
 	     include 'sys_yi'  ; Declare and init y internal system vars
	     symobj NYI_LOST
NYI_LOST     set *-1-YHI_SYS     ; No. of internal words overflow
nyi_free_sys equ -NYI_LOST    ; how much wasted space in partition
	     if NYI_LOST>0
	       fail 'sys_.asm: yi overflow. Increase memmap.asm/NYI_SYS'
	       msg 'Find NYI_LOST in symbol table or above'
	     endif
	  endif

; *** CONSTRAINT: The following segments must form a single contiguous
;	on-chip p segment.
;
	if !ASM_BUG56_LOADABLE
	  org p_i:0			; switch to internal program memory
	  include 'vectors.asm'		; load interrupt vectors

	  dup DEGMON_END_BUG56-*
	    nop
	  endm
DEGMON_END EQU	*			;end of Bug56's monitor+1

; ******* NOTE ******
; dsp.h contains a hardwired macro DSP_PLI_USR_C which must change
; if DEGMON_END changes.  dspwrap uses this constant.
;
;*	  ORG	P:DEGMON_END	; user program begins here
;
	else			; Assembly doesn't touch degmon area
	  include 'iv_decl'	; declare interrupt vector offsets
		; install vectors that DEGMON will not mind loading:
		org p_i:iv_irq_a
  if QP_SAT
;iv_irq_a       	
	jsr >irq_a
;iv_irq_b       	
	movep y:(R_IO)+,y:Y_QP_DATA ; write data 
	nop
  else
;iv_irq_a
	       	jsr >abort1 ; external abort
;iv_irq_b       	
		jsr >abort  ; internal abort
  endif
;iv_ssi_rcv     	
	     	movep x:M_RX,y:(R_IO2)+  ; deposit input sample to input buffer
		nop
;		jsr >ssi_rcv
;iv_ssi_rcv_exc 	
		jsr >ssi_rcv_exc
;iv_ssi_xmt     	
		movep y:(R_IO)+,x:M_TX
		nop
;iv_ssi_xmt_exc 	
		jsr >ssi_xmt_exc
;iv_sci_rcv 
	    	DEBUG_HALT
		nop
;iv_sci_rcv_exc 
		DEBUG_HALT
		nop
;iv_sci_xmt
	     	DEBUG_HALT
		nop
;iv_sci_idle
	    	DEBUG_HALT
		nop
;iv_sci_timer   	
		jsr >sci_timer

; iv_nmi	JSR >DEGMON_TRACER ;TRACE intrpt handler (NMI) - used by BUG56

		org p_i:iv_host_rcv
;iv_host_rcv 
	   	movep x:$FFEB,y:(R_HMS)- ; write (circular) Host Message Queue
;iv_host_rcv2   	
		nop
;iv_host_xmt    	
		jsr >host_xmt
;iv_host_cmd    	
		jsr >hc_host_r_done  	; Terminate DMA read from host

		  org p_i:PLI_SYS
	endif

	  if *!=PLI_SYS
	     warn 'sys_.asm: Inferred DEGMON_H is not equal to PLI_SYS-1'
	  endif
	  if NPI_SYS>0
	    include 'sys_pi'		; Declare and init p internal code
	  endif

;	  Load temporary internal sys prog memory (boot loader, mem tests)
;	  Note that a user module will overwrite bootstrap and memory test code

	  if *!=PLI_USR
	     warn 'sys_.asm: Inferred PHI_SYS is not equal to PLI_USR-1'
	     org p_i:PLI_USR		; beginning of onchip user memory
	  endif

	  if !ASM_BUG56_LOADABLE
   	    include 'reset_boot'	; Boot code for off-chip load
	  endif

	  symobj NPI_BOOT_LOST
NPI_BOOT_LOST  set *-1-PHI_RAM		; No. of internal words overflow
	  if NPI_BOOT_LOST>0		; We spilled off chip
	     fail 'sys_.asm: pi boot overflow. Tighten reset_boot.asm or shift'
	     msg 'Find NPI_BOOT_LOST in symbol table or above'
	  endif

;; ============================================================================
; External system storage
; -----------------------
;; 
;; Include DSP system code, loading it into external p memory.  Next,
;; install external system constants followed by modulo buffers in order
;; of increasing size.	In general, the address of each modulo buffer
;; must be a multiple of the smallest power of 2 equal to or larger than
;; the buffer length.  Here we assume all modulo buffer lengths are a
;; power of 2 by convention. This makes it easy to allocate them as
;; follows:
;; 
;; The first non-existent memory location is a power of 2, and, in
;; general, subtracting a power of 2 from a larger power of 2 leaves a
;; multiple of the smaller power of 2. Therefore, the buffer
;; start-address constraint is satisfied automatically when all buffer
;; lengths are a power of 2 and they are allocated backward from the top
;; of memory in order of decreasing size.
;; 
;; When ONE_MEM is true (shared external memory), external memory contains
;; external system code, "x" external variables, "y" external variables,
;; and the modulo storage buffers, in that order.
;
; we allocate y data before x because it contains IO buffer addresses which
; are used to initialize certain x system variables (DMA initial pointers)

	  org y_e:	      ; point to beginning of ext y data
	  include 'sys_ye'    ; Declare and init ye runtime environment vars
	  symobj NYE_LOST
	  if *!=0	      ; counter wraps around to 0 after 64k
NYE_LOST  set *-1-YHE_SYS ; No. of ext words overflow by system
nye_free_sys equ -NYE_LOST    ; how much wasted space in partition
	  if NYE_LOST!=0
	     fail 'sys_.asm: y use must exactly = memmap.asm/NYE_SYS'
	     msg 'Find NYE_LOST in symbol table or above'
	  endif
	  endif

	  org x_e:	      ; point to beginning of ext x data
	  include 'sys_xe'    ; Declare and init xe runtime environment vars
	  symobj NXE_LOST
NXE_LOST  set *-1-XHE_SYS     ; No. of ext words overflow by system
nxe_free_sys equ -NXE_LOST    ; how much wasted space in partition
	  if NXE_LOST>0
	     fail 'sys_.asm: xe overflow. Increase memmap.asm/NXE_SYS'
	     msg 'Find NXE_LOST in symbol table or above'
	  endif

	  org p_e:PLE_SYS     	; point to beginning of external system p code
	  include 'jsrlib'    	; Declare and init system utility subroutines
	  include 'handlers'  	; Long ntrpt, host cmd, & host msg handlers 

hm_first  ;  set *		; Address of first legal place to jump
	  include 'hmlib'     	; Declare and init host message handlers
hm_last   ; set *		; Address of last place to jump in 3.0+

	  symobj NPE_LOST
NPE_LOST  set *-1-PHE_SYS      	; No. of external words overflow by system
npe_free_sys equ -NPE_LOST     	; how much wasted space in partition
	  if NPE_LOST>0
	     fail 'allocsys.asm: pe overflow. Increase memmap.asm/NPE_SYS'
	     msg 'Find NPE_LOST in symbol table or above'
	  endif

; SOUND KIT BOOTSTRAP PROGRAM LOCATIONS (6 WORDS)
; -----------------------------------------------
;
; The following gets loaded by the sound library (C functions with prefix
; "SND") into external memory before feeding a "DSP core" .snd file to the
; DSP. This bootstrap loaded then loads booter.asm (in sound library) which
; in turn loads general user DSP code. It assumes r0 is set to zero and x0 has 
; the count on entry
;
	  org p_e:PHE_SYS-6  	; System partition at top of external memory
sound_booter_p_mem_loop
        dc      $06c400
        dc      $003ffe
        dc      $0aa980
        dc      $003ffc
        dc      $08586b
        dc      $0c0000
;
;Which really is:
;
;       org     p:XRAMHI-6
;p_mem_loop
;       do      x0,_done
;_get
;       jclr    #HRDF,x:HSR,_get
;       movep   x:HRX,p:(r0)+
;_done
;       jmp     reset

; This is the highest location in external memory.
pe_mem_last
