;;  Copyright 1993 CCRMA, Stanford University.  All rights reserved.
;;  Author - D.A. Jaffe
;;
;;  Modification history
;;  --------------------
;;  01/23/93/daj - initial file created from out1a.asm
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      in1a (UG macro) - Write signal vector from channel 0 of ssi read data buffer
;;
;;  SYNOPSIS
;;      in1a pf,ic,ispc,iadr0,sclA0  
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count
;;      ospc      = output vector memory space ('x' or 'y')
;;      oadr0     = initial output vector memory address
;;      sclA0     = initial channel 0 gain
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access     Argument use             Initialization
;;      ----------     ------------             --------------
;;      x:(R_X)+       Current channel A gain   sclA0
;;      y:(R_Y)+       Current output address    oadr0
;;
;;  DESCRIPTION
;;      The in1a unit-generator reads a signal vector from channel 0 of the incoming
;;      stereo sound stream
;;
;;  RESTRICTIONS
;;
;;  DSPWRAP ARGUMENT INFO
;;      in1a (prefix)pf,(instance)ic,(dspace)ospc,(output)oadr,sclA
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
;;      /usr/local/lib/dsp/ugsrc/in1a.asm
;;
;;
in1a macro pf,ic,ospc,oadr0,sclA0
                new_xarg pf\_in1a_\ic\_,sclA,sclA0 ; left-channel gain
                new_yarg pf\_in1a_\ic\_,oadr,oadr0 ; output address arg
                move x:(R_X)+,X1           ; X1 = channel 0 gain
;;
;;	****** DO NOT CHANGE THE POSITION OF THE FOLLOWING STATEMENT *****
;;	unitgenerators/Out1aUG.m pokes X_SSI_REP explicitly as the
;;	third word in the DSP load image.  
;;
;;	        move x:X_SSI_REP,R_I1     ; This symbol is no longer defined!
	        move x:>0,R_I1     	  ; Current position in read data input buffer

;;
;;	****** DO NOT CHANGE THE POSITION OF THE FOLLOWING STATEMENT *****
;;	unitgenerators/Out1aUG.m pokes X_I_SFRAME_R explicitly as the
;;	fifth word in the DSP load image.  
;;
;;***	        move x:X_I_SFRAME_R,X0       ; This symbol is not defined
	        move x:>0,N_I1     	  ; Move in skip amount

;; No need to set this if we assume tick doesn't straddle buffer
;;                move #(2*I_NDMA-1),M_I1   ; input is modulo ring size
                move  y:(R_Y)+,R_O        ; output address vector to R_O
                move y:(R_I1)+N_I1,X0     ; read sample
                do #I_NTICK,pf\_in1a_\ic\_loop
                     mpyr X0,X1,A  y:(R_I1)+N_I1,X0      ; scale, get next input
		     move A,ospc:(R_O)+ 
pf\_in1a_\ic\_loop
;; No need to set this if we assume tick doesn't straddle buffer
;;                move #-1,M_I1             ; always assumed
          endm


