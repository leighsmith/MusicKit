; mkmon_A_qp_hub_8k.asm - Create object file containing Music Kit DSP Monitor
;		 configured for 8K words of external DSP SRAM and Ariel Quint
;		Processor hub DSP with 256K DRAM

; *** Must manually keep version,rev in synch with verrev.asm ***
; *** and DSP_SYS_{VER,REV}_C in dsp.h
mkmon_A_qp_hub_8k ident 65,40		; Music Kit DSP-resident monitor
	 define nolist 'list'	; stand back!
QP_HUB	EQU 16
; MEM_SIZ	  set  8192-512
; MEM_OFF	  set  512
MEM_SIZ	  set  8192
MEM_OFF	  set  8192
; MEM_OFF	  set  0
ONE_MEM   set  1		; x,y,p are overlaid in external memory
SEND_KERN_ACKS set 0
ASM_SYS  set 1			; include system
	 include 'music_macros'	; need 'memmap, lc, allocsys'
	 end PLI_USR		; default start address in DSP


