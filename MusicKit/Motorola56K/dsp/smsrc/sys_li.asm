; l system environment variables
;
; This file is 'included' by allocsys.asm.
; The space allocation is specified in memmap.asm (NLI_SYS).
;

	  org l_i:	; l internal memory
L_ZERO	  dc 0		; double-precision zero
L_STATUS  dc 0		; DMA state,,run status
	if !AP_MON
L_TICK	  dc 0		; current "tick" count
L_TINC	  dc 0		; size of a tick in samples (for incrementing L_TICK)
L_LARGS_DEVSTAT dc 0	; See below
	endif

; re-allocate l memory x and y overlays to avoid "type" mismatch

	  org x_i:	 ; x internal memory
X_ZERO	  ds 1		 ; x version gives zero in x memory
X_DMASTAT ds 1		 ; DMA state (see sys_xe.asm for bit definitions)
	if !AP_MON
X_TICK	  ds 1		 ; current "tick" count, hi order word
	  ds 1		 ; no name for hi order word of L_TINC
X_LARGS	  ds 1		 ; L memory argument pointer
	endif

	  org y_i:	 ; y internal memory
Y_ZERO	  ds 1		 ; y version gives zero in y memory
Y_RUNSTAT ds 1		 ; Run status (everything not associated with DMA)
	if !AP_MON
Y_TICK	  ds 1		 ; current "tick" count, lo order word
Y_TINC	  ds 1		 ; y version serves as single-precision epsilon
Y_DEVSTAT ds 1		 ; (see sys_xe.asm for bit definitions)
	endif

	  org l_i:	 ; in case includer checks up on us

;; In the early days of the assembler, l:memory had to be initialized by
;; two DC statements, the first for the x: part and the 2nd for the y: part.
;; The l: location counter would advance 2 for every l: memory location (which
;; was an assembler bug).
;;
;; As of version 2.03 of asm56000, DC (et al.) statements initialize TWO words
;; of l memory.  Thus, 'org l:0; dc 0' expands to '_DATA L 0000; 000000 000000'.
;; However, '_BLOCKDATA L' does not exist. It is instead expanded into
;; '_BLOCKDATA X addr count valueHi; _BLOCKDATA Y addr count valueLo'.

