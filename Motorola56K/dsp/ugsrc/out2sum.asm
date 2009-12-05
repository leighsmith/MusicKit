;;  Copyright 1990 NeXT Computer, Inc.  All rights reserved.
;;  Author - J.O. Smith
;;
;;  Modification history
;;  --------------------
;;  06/27/87/jos - initial file created from outa.asm
;;  07/24/91/jos - eliminated use of fixed dispatch offset loc_x_dma_wfp.
;;		   Now the Music Kit directly pokes DSP_X_DMA_WFP into the
;;		   third word of the assembled unit generator code.  No fixed
;;		   dispatch can be used any more since we now support arbitrary
;;		   DSP memory sizes.
;;  01/23/93/daj - added skip factor for SSI support
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      out2sum (UG macro) - Sum signal vector into sound output buffer.
;;
;;  SYNOPSIS
;;      out2sum pf,ic,ispc,iadr0,sclA0,sclB0  
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_out2sum_\ic\_ is globally unique)
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
;;      The out2sum unit-generator sums a signal vector to the outgoing
;;      stereo sound stream. For efficiency, it is desirable to use as few 
;;      instances of out2sum as possible.  For example, several sources
;;      can be summed into a common signal and then passed to out2sum.
;;      Each instance of out2sum can provide a particular stereo placement.
;;
;;  DSPWRAP ARGUMENT INFO
;;      out2sum (prefix)pf,(instance)ic,(dspace)ispc,(input)iadr,sclA,sclB
;;
;;  MAXIMUM EXECUTION TIME
;;      192 DSP clock cycles for one "tick" which equals 16 audio samples.
;;
;;  MINIMUM EXECUTION TIME
;;      160 DSP clock cycles for one "tick".
;;
;;  CALLING PROGRAM TEMPLATE
;;      include 'music_macros'        ; utility macros
;;      beg_orch 'tout2sum'           ; begin orchestra main program
;;           new_yeb outvec,I_NTICK,0 ; Allocate input vector
;;           beg_orcl                 ; begin orchestra loop
;;                oscg orch,1,y,outvec,0.5,8,0,0,0,y,YLI_SIN,$FF    ; sinewave
;;                out2sum orch,1,y,outvec,0.707,0.707 ; Place it in the middle
;;           end_orcl                 ; end of orch loop (update L_TICK,etc.)
;;      end_orch 'tout2sum'           ; end of orchestra main program
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/out2sum.asm
;;
;;  SEE ALSO
;;      /usr/local/lib/dsp/ugsrc/orchloopbegin.asm - invokes macro beg_orcl
;;      /usr/local/lib/dsp/smsrc/beginend.asm(beg_orcl) - calls service_write_data
;;      /usr/local/lib/dsp/smsrc/jsrlib.asm(service_write_data) - clears output tick
;;
out2sum macro pf,ic,ispc,iadr0,sclA0,sclB0
                new_xarg pf\_out2sum_\ic\_,sclA,sclA0 ; left-channel gain
                new_yarg pf\_out2sum_\ic\_,sclB,sclB0 ; right-channel gain
                new_yarg pf\_out2sum_\ic\_,iadr,iadr0 ; input address arg
                if I_NCHANS!=2           ; Two output channels enforced
                     fail 'out2sum UG insists on 2-channel output (stereo)'
                endif
;*d*            move p:loc_x_dma_wfp,R_I2 ; hmdispatch.asm
                move x:(R_X)+,X1 y:(R_Y)+,Y1 ; (X1,Y1) = channel (0,1) gain
;;
;;	****** DO NOT CHANGE THE POSITION OF THE FOLLOWING STATEMENT *****
;;	unitgenerators/Out2sumUG.m pokes X_DMA_WFP explicitly as the
;;	third word in the DSP load image.  
;;
;;***	        move x:X_DMA_WFP,R_O     ; This symbol is no longer defined!
	        move x:>0,R_O     	 ; Current position in dma output buf
		
;;
;;	****** DO NOT CHANGE THE POSITION OF THE FOLLOWING STATEMENT *****
;;	unitgenerators/Out2sumUG.m pokes X_O_CHAN_OFFSET explicitly as the
;;	fifth word in the DSP load image.  
;;
;;***	        move x:X_O_CHAN_OFFSET,X0 ; This symbol is not defined
	        move x:>0,N_O     	 ; Move in channel offset

;; No need to set this if we assume tick doesn't straddle buffer
;;                move #(2*I_NDMA-1),M_I2  ; output is modulo ring size
;;
;;	****** DO NOT CHANGE THE POSITION OF THE FOLLOWING STATEMENT *****
;;	unitgenerators/Out2sumUG.m pokes X_O_SFRAME_W explicitly as the
;;	seventh word in the DSP load image.  
;;
;;***	        move x:X_O_SFRAME_W,X0    ; This symbol is not defined
	        move x:>0,N_I2     	 

;; No need to set this if we assume tick doesn't straddle buffer
;;		move M_I2,M_O
                move  y:(R_Y)+,R_I1      ; input address vector to R_I1
                lua (R_O)+N_O,R_I2       ; R_I2 will point to channel B below
		move N_I2,N_O
                do #I_NTICK,pf\_out2sum_\ic\_loop
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
pf\_out2sum_\ic\_loop
;; No need to set this if we assume tick doesn't straddle buffer
;;              move #-1,M_O             ; always assumed
;;              move #-1,M_I2            ; always assumed
          endm


