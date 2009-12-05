;;  Copyright 1990 NeXT Computer, Inc.  All rights reserved.
;;  Author - D.A. Jaffe
;;
;;  Modification history
;;  --------------------
;;  02/13/93/daj - Created from out1b.
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      out1n (UG macro) - Sum signal vector into channel N of sound output buffer
;;
;;  SYNOPSIS
;;      out1n pf,ic,ispc,iadr0,sclN0  
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_out1n_\ic\_ is globally unique)
;;      ispc      = input vector memory space ('x' or 'y')
;;      iadr0     = initial input vector memory address
;;      sclN0     = initial gain
;;      chanoff0  = channel offset.  0=chan a, 1=chan b, etc.
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access     Argument use             Initialization
;;      ----------     ------------             --------------
;;      x:(R_X)+       Current channel gain     sclN0
;;      y:(R_Y)+       Current input address    iadr0
;;
;;  DESCRIPTION
;;      The out1n unit-generator sums a signal vector to channel 1 of the outgoing
;;      stereo sound stream, or into the mono stream if in mono mode.
;;
;;  RESTRICTIONS
;;
;;  DSPWRAP ARGUMENT INFO
;;      out1n (prefix)pf,(instance)ic,(dspace)ispc,(input)iadr,sclN,chanoff
;;
;;  MAXIMUM EXECUTION TIME
;;
;;  MINIMUM EXECUTION TIME
;;
;;  CALLING PROGRAM TEMPLATE
;;	(not done)	
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/out1n.asm
;;
;;  SEE ALSO
;;      /usr/local/lib/dsp/ugsrc/orchloopbegin.asm - invokes macro beg_orcl
;;      /usr/local/lib/dsp/smsrc/beginend.asm(beg_orcl) - calls service_write_data
;;      /usr/local/lib/dsp/smsrc/jsrlib.asm(service_write_data) - clears output tick
;;
out1n macro pf,ic,ispc,iadr0,sclN0,chanoff0
                new_xarg pf\_out1n_\ic\_,sclN,sclN0 ; channel gain
                new_xarg pf\_out1n_\ic\_,chanoff,chanoff0 ; channel offset
                new_yarg pf\_out1n_\ic\_,iadr,iadr0 ; input address arg
                move x:(R_X)+,X1           ; X1 = channel gain
;;
;;	****** DO NOT CHANGE THE POSITION OF THE FOLLOWING STATEMENT *****
;;	unitgenerators/Out1nUG.m pokes X_DMA_WFP explicitly as the
;;	third word (offset 2) in the DSP load image.  
;;
;;	        move x:X_DMA_WFP,R_O       ; This symbol is defined at run-time
	        move x:>0,R_O     	   ; Current position in dma output buf

	        move x:(R_X)+,N_O     	   ; Channel offset
		nop			
		move y:(R_O)+N_O,Y1        ; dummy read of channel.
					   ; We just do this once, then
					   ; we bump R_O by X_O_SFRAME_W

;;
;;	****** DO NOT CHANGE THE POSITION OF THE FOLLOWING STATEMENT *****
;;	unitgenerators/Out1nUG.m pokes X_O_SFRAME_W explicitly as the
;;	8th word (offset 7) in the DSP load image.  
;;
;;***	        move x:X_O_SFRAME_W,X0    ; This symbol is defined at run-time
	        move x:>0,N_O     	  

                move  y:(R_Y)+,R_I1       ; input address vector to R_I1
		nop
                if "ispc"=='x'
                  move ispc:(R_I1)+,X0 y:(R_O),A ; read input & sample
                else 
                  move ispc:(R_I1)+,X0     ; read input
                  move y:(R_O),A           ; read sample
                endif

                do #I_NTICK,pf\_out1n_\ic\_loop
                     macr X0,X1,A  y:(R_O+N_O),Y1 ; scale & sum, get next output
                     if "ispc"=='x'
                       tfr  Y1,A  ispc:(R_I1)+,X0  A,y:(R_O)+N_O
                     else
                       tfr  Y1,A  A,y:(R_O)+N_O  ; next buffer samp to A, ship output
                       move ispc:(R_I1)+,X0  ; get next input sample
                     endif
pf\_out1n_\ic\_loop
          endm


