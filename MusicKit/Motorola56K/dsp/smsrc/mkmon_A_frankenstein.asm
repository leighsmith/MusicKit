; mkmon_A_frankenstein.asm - Create object file containing Music Kit DSP Monitor
;		configured for 32K words of external DSP SRAM for use with
;		Motorola evaluation module boards

; *** Must manually keep version,rev in synch with verrev.asm ***
; *** and DSP_SYS_{VER,REV}_C in dsp.h
mkmon_A_frankenstein ident 65,41 ; Music Kit DSP-resident monitor
	 define nolist 'list'	; stand back!
MEM_SIZ	  set  32768		
MEM_OFF	  set  0		; Note that 0-0x200 is inaccessible
ONE_MEM   set  1		; x,y,p are overlaid in external memory
SEND_KERN_ACKS set 0
MOTO_EVM EQU 1			; Motorola evaluation module 
O_PADDING_POSSIBLE EQU 1	; Output padding needed for codec
DSP56002 EQU 1			; We've got a 56002
ASM_SYS  set 1			; include system
	 include 'music_macros'	; need 'memmap, lc, allocsys'
	 end PLI_USR		; default start address in DSP


