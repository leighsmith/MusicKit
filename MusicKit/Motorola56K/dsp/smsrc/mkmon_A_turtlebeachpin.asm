; mkmon_A_turtlebeachpin.asm - Create Music Kit DSP Monitor
;		 configured for 32K words of external DSP SRAM.

; *** Must manually keep version,rev in synch with verrev.asm ***
; *** and DSP_SYS_{VER,REV}_C in dsp.h
mkmon_A_turtlebeachpin ident 65,41		; Music Kit DSP-resident monitor
	 define nolist 'list'	; stand back!
MEM_SIZ	  set  16384
MEM_OFF	  set  16384		; 
ONE_MEM   set  0		; x,y,p are not overlaid in external memory
PARTIAL_OVERLAY set 1           ; however, x/p are overlaid
PINNACLE  set  1
SEND_KERN_ACKS set 0
DSP56002  equ  1
ASM_SYS  set 1			; include system
	 include 'music_macros'	; need 'memmap, lc, allocsys'
	 end PLI_USR		; default start address in DSP

