; test.asm - Test program for unit generator macro oscw
;
; Usage:
;	asm56000 -A -B -L -OS,SO -I/usr/local/lib/dsp/smsrc/ test
;	open /LocalDeveloper/Apps/Bug56.app
;	<load and erase symbols> test.lod
;	<SSTEP on main control panel>
;	<STEP on single-step panel>
;	 ...
;	<or RUN on main control panel - a breakpoint is provided below>
;
; At the label TICK_LOOP, you may wish to step over the subroutine call which
; carries out "system updates".  This can be done by adding 2 to the address
; in the main Bug56 control panel, or you can type <command>R and write two
; NOPs in place of the subroutine call.
;	
; If you do run the system updates, after a number of TICK_LOOP executions,
; you can view the sound waveform in the sound output buffers of the system.
; A breakpoint is set below to go off after 256 samples are generated, so you
; can hit the "Run" button on the main Bug56 control panel to generate
; 256 samples of output.  This exactly fills both DMA output buffers in the 
; DSP system.  The buffers each contain 256 samples in stereo.
; Note that every other sample is zero because the output buffer
; is stereo, and we are only sending data to channel A.
;
; When Bug56 halts at the breakpoint, open a Y memory viewer and set the 
; lower limit to y:YB_DMA_W.  The other buffer follows right after it
; and has its own label YB_DMA_W2. You should see samples of the oscw 
; output waveform, right-shifted 8 bits.  (The 16-bit samples must be
; right-justified in the DMA buffers.)
;
test  ident 0,0		; version, revision (arbitrary)
        include 'sys_xdefs.asm' 
	include 'config_standalone'    ; on this directory
;*	define nolist 'list'	; get absolutely everything into listing file
	include 'music_macros'	; utility macros

nsamps	set 256			; number of samples to compute
srate	equ 22050.0		; samples per second
cosArg	equ 0.999*@cos(2*3.141592653*440.0/srate)
sinArg	equ 0.999*@sin(2*3.141592653*440.0/srate)
state1  equ 0.0                 ; Initial values for state variables
state2  equ 1.0

	beg_orch 'test'	; standard startup for orchestras

	new_xib xsig,I_NTICK,0		; allocate waveform vector

	beg_orcl
		nop_sep 3	; nop's to help find boundary
;     oscw      macro pf,ic,sout,aout0,c0,s0,u0,v0
		oscw orch,1,x,xsig,cosArg,sinArg,state1,state2
		nop_sep 3	   	; nop's to help find boundary
		out2sumbug56 orch,1,x,xsig,1.0,0 ; Output signal to DAC channel A
		nop_sep 3	   	; nop's to help find boundary
		break_on_sample nsamps	; stop after nsamps samples (misc.asm)
	end_orcl
finish	end_orch 'test'
