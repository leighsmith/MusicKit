; config.asm - specify assembly and run-time configuration
;
;; Copyright 1989, NeXT Inc.
;; Author - J.O. Smith
;;
;; 11/29/92/jos - Removed DEGMON_RUN_LOC and DEGMON_TRACER_LOC 
;;		  which were never used.  
;; 11/29/92/jos - Changed DEGMON_N to make enough room so that Bug56's
;;		  degmon will not overlap standalone DSP assemblies
;;		  (used for unit generator and ap macro development).
;; 11/29/92/jos - Removed RELEASE_1 support which was off anyway.
;; 02/06/94/jos - Simplified memory configuration support.
;;		  Removed obsolete API support.
;; 08/06/94/daj - Made TMQ bigger for big memory
;; 09/12/95/daj - Added default values for MOTO_EVM (motorola evaluation module)
;;	          and for DSP56002

     if !@def(QP_HUB)
QP_HUB	EQU 0		
     endif

     if !@def(QP_SAT)
QP_SAT	EQU 0
     endif

     if !@def(MSOUND)
MSOUND	EQU 0
     endif

     if !@def(PINNACLE)
PINNACLE EQU 0
     endif

     if !@def(PARTIAL_OVERLAY)
PARTIAL_OVERLAY EQU 0
     endif

;; In case we ever need this
     if !@def(ILINKI56)
ILINKI56 EQU 0
     endif

    if !@def(DSP56002)
DSP56002  EQU 0
    endif

     if !@def(MOTO_EVM)
MOTO_EVM EQU 0		
     endif

     if !@def(O_PADDING_POSSIBLE)
O_PADDING_POSSIBLE EQU 0		
     endif

; *** Control of debug info ***

     if !@def(TMQU_MSGS)
TMQU_MSGS set 0		      	; Set nonzero to obtain "TMQ underrun" messages
     endif

     if !@def(FAST_AND_LOOSE)
FAST_AND_LOOSE 	set 1	      ; 1 => skip various safety checks (when debugged)
			      ; e.g. inhibits run-time UG arg pointer checking
			      ; It also inhibits clip-count maintenance.
			      ; Inhibits error checking in handlers:jsr_hm.
     endif

     if !@def(SYS_DEBUG)
SYS_DEBUG set 1		      	; Set nonzero to emit runtime debugging code
     endif			; enables HMS health check in handlers(xhm)
				; enables TMQ underrun messages
				; enables reserving bottom 2 stack locations

     if !@def(UG_DEBUG)
UG_DEBUG set 0	      		; Set nonzero to emit runtime UG debugging code
     endif

     if UG_DEBUG
SYS_DEBUG set 1	      		; UG_DEBUG implies SYS_DEBUG
	msg 'UG_DEBUG is on => extra run-time code in unit generators'
     endif

     if SYS_DEBUG
	msg 'SYS_DEBUG is on => extra debug run-time code in DSP system'
     else
      if FAST_AND_LOOSE
	warn 'BoinkOut hangs if SYS_DEBUG is off and FAST_AND_LOOSE on'
      endif
     endif

     if !@def(MSG_REMINDERS)
MSG_REMINDERS set  0	      ; Set nonzero to emit assembly-time reminders
     endif

     if MSG_REMINDERS
	  define remember 'msg'
     else
	  define remember ';'
     endif

     if !@def(NO_MESSAGES)
NO_MESSAGES set  1	      ; Zero means print configuration info
     endif

     if !@def(NO_WARNINGS)
NO_WARNINGS set  0	      ; Zero means print warnings
     endif

     if NO_WARNINGS
	opt now
     endif

     if NO_MESSAGES
;*	  opt now
	  define message ';'
     else
	  define message 'msg'
     endif

; *** Mnemonics for selecting a case ***
; Set one of the following in the source file which includes this one 
; to get that case.

     if !@def(SIMULATING)  ; Pure simulator (for fast ap,ug development)
SIMULATING set 0
     endif

     if !@def(ASM_SYS)
ASM_SYS	set  0 ; no DSP monitor by default (used by dspwrap assemblies)
     endif

     define HAVE_SYSTEM '(ASM_SYS||SIMULATING==0)'

     if !@def(ASM_BUG56_LOADABLE)
ASM_BUG56_LOADABLE set 0 ; 1 inhibits conflicts with Bug56 degmon monitor
     endif

; *** Choose whether to support relocatable addresses within a 
;	single-word instruction. (As of 4/18/88, NeXT loader
;	software does not --- each relocatable address must 
;	occupy an entire word.)

	if !@def(ANY_FIXUPS)
ANY_FIXUPS set  0	     ; 0 => force long-mode addressing if relocatable
	endif

;; --------------------------------------------------------------------------
;;
; *** Choose memory configuration (see memmap.asm) ***
;;
     if !@DEF(MEM_SIZ)
MEM_SIZ	  set  8192
     endif

     if !@DEF(MEM_OFF)
MEM_OFF	  set  8192 ; external memory address offset
     endif

	if !@def(ONE_MEM)
ONE_MEM	set  1    ; 1 => Shared external memory (x, y, and p)
	endif

 	if !@DEF(XY_SPLIT)
XY_SPLIT set  0 ; When true, xe/ye split down the middle. Else all xe.
	endif

SEG_OFF   set 32768+MEM_OFF ; where x and y are separate banks overlaying  p

; --------------------------------------------------------------------------

	if !@DEF(CONTINUOUS_INFILE)
CONTINUOUS_INFILE set 0	; beginend.asm(beg_orch) and jsrlib.asm(service_infile)
	endif

     if !@def(READ_DATA)
READ_DATA  set  0	        ; Set nonzero to allocate read-data buffers
     endif			; Some day, all buffers will allocate on fly

      if READ_DATA
	message 'READ DATA enabled'
	cobj 'READ DATA enabled'
      else
	message 'READ DATA disabled'
	cobj 'READ DATA disabled'
      endif

     if QP_SAT
DMA_SOUND_OUT  set  0
     else
DMA_SOUND_OUT  set  1
     endif

     if !@def(SSI_READ_DATA)
SSI_READ_DATA  set  1	        ; Set nonzero to allocate SSI_READ-data buffers
     endif			; Some day, all buffers will allocate on fly

      if SSI_READ_DATA
	message 'SSI_READ DATA enabled'
	cobj 'SSI_READ DATA enabled'
      else
	message 'SSI_READ DATA disabled'
	cobj 'SSI_READ DATA disabled'
      endif

     if !@def(AP_MON)
AP_MON  set  0		        ; Set nonzero to assemble array proc monitor
     endif

      if AP_MON
	message 'AP MONITOR enabled'
	cobj 'AP MONITOR enabled'
      else
	message 'AP MONITOR disabled'
	cobj 'AP MONITOR disabled'
      endif

     if !@def(WRITE_DATA_16_BITS)
WRITE_DATA_16_BITS  set  1	; 16-bit right-just. or 24-bit sound out format
     endif

     if !@def(SEND_KERN_ACKS)
SEND_KERN_ACKS  set  0
     endif

; =============================================================================
cant_have macro cond	; fatal error if cond is true
	if (cond)
		fail " cond is TRUE!"
	endif
	endm
; =============================================================================
must_have macro cond	; fatal error if cond is false
	if !(cond)
		fail " cond is FALSE!"
	endif
	endm

; ******************* System external y memory buffer sizes ******************

I_NDMQ	set 32	      		; Size of DSP Message Queue (power of 2)

  if (MEM_SIZ>8192)
I_NHMS	set 128	      		; Host Message Stack length (power of 2)
  else
I_NHMS	set 64	      		; Host Message Stack length (power of 2)
  endif
	if AP_MON

	if READ_DATA
		fail 'cannot use read-data with AP monitor'
	endif

I_NTMQ  set 0    	; Size of Timed Message Q (power of 2)
I_NDMA	set 0		; Samples per DMA transfer (2 of these total)
I_NYE_SYS set I_NHMS+I_NDMQ+I_NTMQ+I_NDMA*2 ; Total external y memory use
I_NLI_SYS set  2 ; No. internal words reserved for system l constants
I_NXI_SYS set  0 ; No. internal words reserved for system x constants
I_NYI_SYS set  0 ; No. internal words reserved for system y constants
I_NPI_SYS set  0 ; No. internal words reserved for system p programs

	if SYS_DEBUG
I_NPE_SYS set  990 	; AP System external p DEBUG [frm 982]
	else
I_NPE_SYS set  840 	; AP System external p
	endif

	if SYS_DEBUG
I_NXE_SYS set  67 	; AP System external x vars DEBUG (exact 7/16/91)
	else		; not SYS_DEBUG:
I_NXE_SYS set  55 	; AP System external x vars (exact)
	endif		; SYS_DEBUG

I_NPE_USR set 0		; No. off-chip words reserved for user code

	else		; not AP_MON => DSP music monitor

        remember 'We rely on driver asking for available space => no overrun'
	if (MEM_SIZ>8192)
I_NTMQ  set 2048	; Size of Timed Message Q
	else
I_NTMQ  set 1024        ; Size of Timed Message Q (power of 2)
	endif
        if SSI_READ_DATA
I_NDMA  set 256                 ; Samples per DMA transfer (4 of these total)
I_WD_TYPE set 0                 ; DMA type (0,1,2,3) => (256,512,1K,2K) buf siz
I_RD_TYPE set 0                 ; DMA type (0,1,2,3) => (256,512,1K,2K) buf siz
        else
I_NDMA  set 512                 ; Samples per DMA transfer (2 of these total)
I_WD_TYPE set 1                 ; DMA type (0,1,2,3) => (256,512,1K,2K) buf siz
I_RD_TYPE set 1                 ; DMA type (0,1,2,3) => (256,512,1K,2K) buf siz
        endif
  
I_WD_CHAN set 1                 ; DMA channel code for write data (0 to 63)
I_RD_CHAN set 1                 ; DMA channel code for read data (0 to 63)
  
	must_have (I_WD_TYPE==I_RD_TYPE) ; because I_NDMA sets both sizes

	must_have ((I_WD_TYPE==0&&I_NDMA==256)||(I_WD_TYPE==1&&I_NDMA==512)||(I_WD_TYPE==2&&I_NDMA==1024)||(I_WD_TYPE==3&&I_NDMA==2048))

	if SSI_READ_DATA                    ; Was READ_DATA
I_NYE_SYS set I_NHMS+I_NDMQ+I_NTMQ+I_NDMA*4 ; Total external y memory use
	else
I_NYE_SYS set I_NHMS+I_NDMQ+I_NTMQ+I_NDMA*2 ; Total external y memory use
	endif

I_NPE_USR set 512	      ; No. off-chip words reserved for user code (min)

; *** Music system assembly constants ***

I_NSIGS	  set 8		      ; Number of signal vectors in xi, yi each
I_NCHANS  set 2		      ; Number of audio channels assumed in output
;*I_NTICK  set 8	      ; Samples/tick (must be even and divide NB_DMA)
I_NTICK   equ 16 	      ; Needed for TMQ addr exprs (asm bug texpr.asm)
     if I_NTICK%2!=0
	  fail 'defines.asm: I_NTICK must be even'
;	  also, DO #I_NTICK-1 means 65K iterations if I_NTICK==1.
     endif

I_NLI_SYS set  5 ; No. internal words reserved for system l constants
I_NXI_SYS set  0 ; No. internal words reserved for system x constants
I_NYI_SYS set  0 ; No. internal words reserved for system y constants
I_NPI_SYS set  0 ; No. internal words reserved for system p programs

   if QP_SAT
	if SYS_DEBUG
I_NPE_SYS set  1890 	; MK DEBUG system external p handlers and utilities 
	else		; not SYS_DEBUG:
I_NPE_SYS set  1696 	; MK system external p handlers etc
	endif		; SYS_DEBUG
   else 
     if QP_HUB
	if SYS_DEBUG
I_NPE_SYS set  2200 	; MK DEBUG system external p handlers and utilities 
	else		; not SYS_DEBUG:
I_NPE_SYS set  1696 	; MK system external p handlers etc 
	endif		; SYS_DEBUG
   else
     if MOTO_EVM
	if SYS_DEBUG
I_NPE_SYS set  1950 	; Exact 12/28/95/daj
	else		; not SYS_DEBUG:
I_NPE_SYS set  1696 	; MK system external p handlers etc 
	endif		; SYS_DEBUG
     else
	if (SEND_KERN_ACKS)
	  if SYS_DEBUG
I_NPE_SYS set  1894 	; MK DEBUG system external p handlers and utilities 
			; (exact 2/15/93)
	  else		; not SYS_DEBUG:
I_NPE_SYS set  1712 	; MK system external p handlers etc (exact 7/16/91)
	  endif		; SYS_DEBUG
	else 
	  if SYS_DEBUG
I_NPE_SYS set  1880 	; MK DEBUG system external p handlers and utilities 
			; (exact 2/15/93)
	  else		; not SYS_DEBUG:
I_NPE_SYS set  1698 	; MK system external p handlers etc (exact 7/16/91)
	  endif		; SYS_DEBUG
	endif
     endif
   endif
  endif
	
   if QP_SAT
	if SYS_DEBUG
I_NXE_SYS set  105 	; System external x vars (exact 3/6/93 - daj)
	else		; not SYS_DEBUG:
I_NXE_SYS set  85 	; System external x vars (exact if WRITE_DATA_16_BITS)
	endif		; SYS_DEBUG
   else 		; not QP_SAT
     if QP_HUB
	if SYS_DEBUG
I_NXE_SYS set  130 	; System external x vars (exact 2/24/93 - daj)
	else		; not SYS_DEBUG:
I_NXE_SYS set  85 	; System external x vars (exact if WRITE_DATA_16_BITS)
	endif		; SYS_DEBUG
     else		; not QP_HUB
	if MOTO_EVM
	  if SYS_DEBUG
I_NXE_SYS set 107	; (exact 12/28/95 - daj)
	else
I_NXE_SYS set 85
	endif
      else
	  if SYS_DEBUG
I_NXE_SYS set  103 	; System external x vars (exact 2/24/95 - daj)
	  else		; not SYS_DEBUG:
I_NXE_SYS set  86 	; System external x vars (exact if WRITE_DATA_16_BITS)
	  endif		; SYS_DEBUG
     endif
   endif
  endif

MAX_ONCHIP_PATCHPOINTS  EQU 8 ; no. onchip patchpoints allocated by music kit

	  if I_NCHANS*I_NTICK>I_NDMA
	       fail 'I_NCHANS*I_NTICK cannot exceed I_NDMA'
	  endif

	  if I_NDMA%(I_NCHANS*I_NTICK)!=0
	       fail 'I_NCHANS*I_NTICK must divide I_NDMA'
	  endif

 	endif ; AP_MON

; ******************************* Misc. controls ******************************

I_DEGMON_L set $34 ; Start of MK degmon - MUST BE INTERNAL P MEMORY
DEGMON_END_BUG56 equ $96 ; First user address in Bug56 version
DEGMON_N equ DEGMON_END_BUG56-I_DEGMON_L
		
SYMOBJ_P      	set 1	      ; 0 => no SYMOBJ in allocusr. 1 => do it
I_NTMQ_LWM     	set I_NTMQ/4  ; Send DM_TMQ_LWM when TMQ is only this full
I_NTMQ_ROOM_HWM set I_NTMQ-I_NTMQ_LWM ; this is what we actually use
I_NPE_SCR set  	1 ; Size of scratch area = maximum length of prog in HMS or TMQ


; Special address constants
I_OUTY	  EQU  $FFFF	      ; Y location mapped to output file for simulator

; Special datum constants
  if QP_SAT
I_DEFIPR  EQU  $2400	      ; Default interrupt priority register (p. 8-10)
			      ; irqa=off,sci=2,hif=1,irqb=off, ssi=3, -level (for both)
  else
I_DEFIPR  EQU  $243C	      ; Default interrupt priority register (p. 8-10)
			      ; irqa=off,sci=2,hif=1,irqb=2, ssi=3, -edge
  endif

  if QP_HUB
I_DEFOMR  EQU  $0086	      ; Default operating mode register (p. 9-1)
			      ; normal exp. mode (2) + onchip ROM enabled (4)
			      ; plus external memory access Wait/Bus Strobe for SCSI
			      ; control port
I_DEFBCR  EQU  $0001	      ; Port A bus control register. 1 I/O wait state
  else
    if MSOUND
I_DEFOMR  EQU  6	      ; Default operating mode register (p. 9-1)
			      ; normal exp. mode (2) + onchip ROM enabled (4)
I_DEFBCR  EQU  $3330	      ; Port A bus control register. 3 mem wait states
    else
I_DEFOMR  EQU  6	      ; Default operating mode register (p. 9-1)
			      ; normal exp. mode (2) + onchip ROM enabled (4)
I_DEFBCR  EQU  $0000	      ; Port A bus control register. 0 I/O wait state
    endif
  endif

  if PINNACLE
I_DEFPLL  EQU $150003	      ; (3+(1<<16)+(1<<18)+(1<<20))
  else
I_DEFPLL  EQU $260012          ; This is from Motorola's EVM codec.asm.  
                              ; Changed from 261009 to 260012 to change the EVM clk
                              ; from 20Mhz to 76Mhz. clkSpeed = 4Mhz*(MF+1)/(2^^DF) 
                              ; MF : bits 0-11, DF : bits 12-15 
  endif

; ******************************* Config messages *****************************

     cobj 'Copyright 1989, Next Inc., 1992-95 Stanford University'

     if SIMULATING
	  message 'Assembling for SIMULATOR'
	  cobj 'Assembled for SIMULATOR'
     endif

     if ASM_SYS
	  message 'Including DSP SYSTEM CODE in assembly'
     else
	  message 'Assembling USER ONLY.  Loading system data but not code'
	  cobj 'USER ONLY'
     endif

     if MEM_SIZ==8192
          message 'External 8K memory'
          cobj 'External 8K memory'
     endif

 	if ONE_MEM
	  message 'Default memory map = OVERLAY (ONE_MEM=1)'
	  cobj 'Default memory map = OVERLAY (ONE_MEM=1)'
	else
	  message 'External memory map = NOT OVERLAID (ONE_MEM=0)'
	  cobj 'Default memory map = NOT OVERLAID (ONE_MEM=0)'
	endif

 	if XY_SPLIT
	  message 'XY_SPLIT: X and Y memory divided into equal segments'
	  cobj 'XY_SPLIT: X and Y memory divided into equal segments'
	else
	  message '!XY_SPLIT: All external memory is X'
	  cobj '!XY_SPLIT: All external memory is X'
	endif

pi_active set 1		; initially assume assembly in internal p
			; this goes away when you can tell what lc
			; (eg p,ph,pl) is in use. See beg_orcl,
			; end_??b in allocusr.

     if I_NTMQ<0
	  fail 'config.asm: dispatch table size must be less than TMQ length'
     endif

