; apmon_8k.asm - Array Processing DSP Monitor for 8K static memory

; *** Must manually keep version,rev in synch with verrev.asm ***
; *** and DSP_SYS_{VER,REV}_C in dsp.h
apmon_8k ident 65,40		; Array Processing DSP-resident monitor
	 define nolist 'list'	; stand back!
NEXT_8K  set 1		   	; Assemble for NeXT hardware, 8K memory
ASM_SYS  set 1			; include system
	 include 'ap_macros'	; need 'memmap, lc, allocsys'
	 end PLI_USR		; default start address in DSP




