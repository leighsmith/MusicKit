;;  Copyright 1994 CCRMA.  All rights reserved.
;;  Author - J.O. Smith
;;
;;  Modification history
;;  --------------------
;;  10/12/94/jos - initial file created from out2sum.asm
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      out2sumbug56 (UG macro) - Sum signal vector into sound output buffer.
;;
;;  SYNOPSIS
;;      out2sumbug56 pf,ic,ispc,iadr0,sclA0,sclB0  
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_out2sumbug56_\ic\_ is globally unique)
;;      ispc      = input vector memory space ('x' or 'y')
;;      iadr0     = initial input vector memory address
;;      sclA0     = initial channel 0 gain
;;      sclB0     = initial channel 1 gain
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access     Argument use             Initialization
;;      ----------     ------------             --------------
;;      x:(R_X)+       Current channel A gain   sclA0
;;      y:(R_Y)+       Current channel B gain   sclB0
;;      y:(R_Y)+       Current input address    iadr0
;;
;;  DESCRIPTION
;;      The out2sumbug56 unit-generator sums a signal vector to the outgoing
;;      stereo sound stream. It functions identically to out2sum except that
;;	it does not rely on run-time modification of the code to install
;;      system buffer addresses.  A cleaner solution would be to make the
;;	system addresses arguments to out2sum, but this works for now.
;;
;;  DSPWRAP ARGUMENT INFO
;;      out2sumbug56 (prefix)pf,(instance)ic,(dspace)ispc,(input)iadr,sclA,sclB
;;
;;  MAXIMUM EXECUTION TIME
;;      192 DSP clock cycles for one "tick" which equals 16 audio samples.
;;
;;  MINIMUM EXECUTION TIME
;;      160 DSP clock cycles for one "tick".
;;
;;  CALLING PROGRAM TEMPLATE
;;      include 'music_macros'        ; utility macros
;;      beg_orch 'tout2sumbug56'           ; begin orchestra main program
;;           new_yeb outvec,I_NTICK,0 ; Allocate input vector
;;           beg_orcl                 ; begin orchestra loop
;;                oscg orch,1,y,outvec,0.5,8,0,0,0,y,YLI_SIN,$FF    ; sinewave
;;                out2sumbug56 orch,1,y,outvec,0.707,0.707 ; Place it in the middle
;;           end_orcl                 ; end of orch loop (update L_TICK,etc.)
;;      end_orch 'tout2sumbug56'           ; end of orchestra main program
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/out2sumbug56.asm
;;
;;  SEE ALSO
;;      /usr/local/lib/dsp/ugsrc/orchloopbegin.asm - invokes macro beg_orcl
;;      /usr/local/lib/dsp/smsrc/beginend.asm(beg_orcl) - calls service_write_data
;;      /usr/local/lib/dsp/smsrc/jsrlib.asm(service_write_data) - clears output tick
;;
out2sumbug56 macro pf,ic,ispc,iadr0,sclA0,sclB0
                new_xarg pf\_out2sumbug56_\ic\_,sclA,sclA0 ; left-channel gain
                new_yarg pf\_out2sumbug56_\ic\_,sclB,sclB0 ; right-channel gain
                new_yarg pf\_out2sumbug56_\ic\_,iadr,iadr0 ; input address arg
                if I_NCHANS!=2           ; Two output channels enforced
                     fail 'out2sumbug56 UG insists on 2-channel output (stereo)'
                endif
                move x:(R_X)+,X1 y:(R_Y)+,Y1 ; (X1,Y1) = channel (0,1) gain
	        move x:X_DMA_WFP,R_O
	        move x:X_O_CHAN_OFFSET,N_O
	        move x:X_O_SFRAME_W,N_I2    ; This symbol is not defined
                move  y:(R_Y)+,R_I1      ; input address vector to R_I1
                lua (R_O)+N_O,R_I2       ; R_I2 will point to channel B below
		move N_I2,N_O
                do #I_NTICK,pf\_out2sumbug56_\ic\_loop
                     if "ispc"=='x'
                          ; Since we must read and write y mem 
                          ; twice, any 8-cycle inner loop is optimal.
                          move x:(R_I1)+,X0 y:(R_O),A ; read input & right
                     else
                          ; Since we must read y mem 3 times and write it
                          ; twice, any 10-cycle inner loop is optimal.
                          move y:(R_I1)+,X0   ; read input
                          move y:(R_O),A      ; read left
                     endif
                     macr X0,X1,A y:(R_I2),B  ; comp left, read right
                     macr X0,Y1,B A,y:(R_O)+N_O   ; comp right, out left
                     move B,y:(R_I2)+N_I2         ; out right
pf\_out2sumbug56_\ic\_loop
          endm


