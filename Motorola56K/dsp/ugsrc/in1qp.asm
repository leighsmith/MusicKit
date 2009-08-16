;;  Copyright 1993 CCRMA, Stanford University.  All rights reserved.
;;  Author - D.A. Jaffe
;;
;;  Modification history
;;  --------------------
;;  02/23/93/daj - initial file created from out1n.asm and in1a.asm
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      in1qp (UG macro) - Write signal vector from specified channel of slave dsp
;;
;;  SYNOPSIS
;;	in1qp pf,ic,ospc,oadr0,scl0,chan0,dspptr0,skip0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count
;;      ospc      = output vector memory space ('x' or 'y')
;;      oadr0     = output vector memory address
;;      scl0      = channel gain
;;      chan0     = channel offset (0-based)
;;      dspptr0   = pointer to slave DSP's input buffer pointer
;;      skip0     = sample frame (this should be the OUTPUT sample frame, since
;;			it must match the output parameters of the slave DSP)
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access     Argument use             Initialization
;;      ----------     ------------             --------------
;;      x:(R_X)+       channel 	         	chan0
;;      x:(R_X)+       channel gain      	scl0
;;      x:(R_X)+       Sample frame skip        skip0
;;      y:(R_Y)+       dsp ptr           	dspptr0
;;      y:(R_Y)+       output address    	oadr0
;;
;;  DESCRIPTION
;;      The in1qp unit-generator reads a signal vector from channel chan of the 
;; 	sound stream coming from DSP N.  You specify the DSP by setting dspptr.
;;	You specify the frame skip (increment to get to the next sample of this
;;	channel) in skip.  Note that both skip and dspptr are pointers to pointers.
;;	They are dereferenced by in1qp.  Chan is 0-based; 0 is the first channel,
;;	X_O_CHAN_OFFSET * 1 is the second channel, X_O_CHAN_OFFSET * 2 is the 
;;	third channel, etc.
;;
;;  RESTRICTIONS
;;
;;  DSPWRAP ARGUMENT INFO
;;      in1qp (prefix)pf,(instance)ic,(dspace)ospc,(output)oadr,scl,chan,(address)dspptr, (address)skip
;;
;;  MAXIMUM EXECUTION TIME
;;	(see dspwrap-generated code)
;;
;;  MINIMUM EXECUTION TIME
;;	(see dspwrap-generated code)
;;
;;  CALLING PROGRAM TEMPLATE
;;      (not done)
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/in1qp.asm
;;
;;
in1qp macro pf,ic,ospc,oadr0,scl0,chan0,dspptr0,skip0
                new_xarg pf\_in1qp_\ic\_,chan,chan0     ; channel offset
                new_xarg pf\_in1qp_\ic\_,scl,scl0       ; channel gain
                new_xarg pf\_in1qp_\ic\_,skip,skip0     ; sample frame 
                new_yarg pf\_in1qp_\ic\_,dspptr,dspptr0 ; ptr to input buff ptr
                new_yarg pf\_in1qp_\ic\_,oadr,oadr0     ; output address arg
	        move y:(R_Y)+,R_I2     ; dspptr--Ptr to current read pos in in buf
	        move x:(R_X)+,N_I1     ; chan--Channel offset 
	        move x:(R_I2),R_I1     ; Dereference dspptr
                move x:(R_X)+,X1       ; scl--channel gain
	        move x:(R_X)+,R_I2     ; skip--ptr to X_O_SFRAME_W
		move y:(R_I1)+N_I1,Y1  ; dummy read of channel 
		move x:(R_I2),N_I1     ; dereference X_O_SFRAME_W
                move  y:(R_Y)+,R_O     ; oadr--output address vector to R_O
                move y:(R_I1)+N_I1,X0  ; read sample
                do #I_NTICK,pf\_in1qp_\ic\_loop
                     mpyr X0,X1,A  y:(R_I1)+N_I1,X0      ; scale, get next input
		     move A,ospc:(R_O)+ 
pf\_in1qp_\ic\_loop
          endm


