; music_macros.asm - standard macros for stand-alone orchestra development
;
;; Copyright 1989, NeXT Inc.
;; Author - J. O. Smith
;;
;; Included by mkmon*.asm, for example.
;;
;; 05/04/90/jos - Flushed sys_memory_map_{mk,ap} include.
;;		  If needed, they must become {mk8k,mk32k,ap8k,ap32k} etc.
;;
	page 255,255,0,1,1	   	; Width, height, topmar, botmar, lmar
	opt nomd,mex,cex,mi,xr,s	; Default assembly options
;;*	opt mu,s,cre,cc		   	; Extra assembly options to consider
	lstcol 9,6,6,9,9	   	; Label, Opcode, Operand, Xmove, Ymove
	include 'verrev.asm'		; cannot appear before ident!
	nolist		   		; Hide the following by default
	include 'config'	   	; Assembly and run-time config ctl
;	include 'include_dirs'		; Specify macro include directories
	maclib  './'		   	; current directory (this is needed!)
	if AP_MON
	  cobj 'APMON'			; comment in obj file giving asm type
	else
	  cobj 'MKMON'			; either Array Processing or Music Kit
	endif
	include 'defines'	   	; various needed definitions
	include 'misc'	   		; useful macros needed immediately
	include 'dspmsgs'   		; all dsp message and error opcodes
	include 'memmap'	   	; memory map for this configuration
	include 'beginend'	   	; Beginning and ending macros
        section SYSTEM	   	   	; dsp monitor code goes in this section
	    if ASM_SYS
		include 'allocsys' 	; Allocate and initialize system memory
	    else
		include 'sys_messages'	; Module assembly faster in this case
	    endif
        endsec
	section USER			; user code goes in this section
	     	include 'allocusr' 	; memory-allocation macros for 
	endsec				;   stand-alone AP|MK test programs

SYMOBJ_P  set 1		 		; enable long name support
	  list			   	; Increment list counter back to 0

