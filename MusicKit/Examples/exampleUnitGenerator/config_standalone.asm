; config_standalone -included by unit-generator and array-processing-macro
; 		     test programs.  Sets things up so that assembly
;		     includes system monitor, no degmon, and no reset code.
;		     This makes the assembly loadable into a running Bug56.
;
;		     In other words, all code needed to run a Music Kit
;		     orchestra or array processing program is included except
;		     low p memory where Bug56's "degenerate monitor" lives.
;		     Bug56 refuses to load a .lod file which tries to write
;		     in its monitor area, so we have to inhibit vector 
;		     assembly and start user code after the Bug56 monitor.

ASM_SYS	   		set 1 	; want mk or ap dsp monitor code
ASM_BUG56_LOADABLE  	set 1	; inhibit low p memory assembly (degmon)

; override normal runtime halt action by one convenient with Bug56
	define DEBUG_HALT 'SWI' ; SINGLE WORD (--->abort)
DEBUG_HALT_OVERRIDDEN set 1

