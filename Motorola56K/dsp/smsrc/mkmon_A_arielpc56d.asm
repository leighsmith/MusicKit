; mkmon_A_arielpc56d.asm - Create object file containing Music Kit DSP Monitor
;		 configured for 48K words of external DSP SRAM.
;		For the Ariel PC 56D in split mode. 
; *** FIXME Eventually use all 64K
; *** Must manually keep version,rev in synch with verrev.asm ***
; *** and DSP_SYS_{VER,REV}_C in dsp.h
mkmon_A_arielpc56d ident 65,41	; Music Kit DSP-resident monitor
	 define nolist 'list'	; stand back!
MEM_SIZ	  set  16384
MEM_OFF	  set  0		; or 8192?
ONE_MEM   set  0		; x,y,p are separate in external memory
SEND_KERN_ACKS set 0
ASM_SYS  set 1			; include system
	 include 'music_macros'	; need 'memmap, lc, allocsys'
	 end PLI_USR		; default start address in DSP


