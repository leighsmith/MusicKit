;;  Copyright 1990 NeXT Computer, Inc.  All rights reserved.
;;  Author - Julius Smith
;;
;;  Modification history
;;  --------------------
;;  06/13/89/mm - initial file created from add3.asm
;;  08/14/95/stilti - fixed saturation bug 
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      interp (UG macro) - dynamically interpolate between two signals
;;
;;  SYNOPSIS
;;      interp pf,ic,sout,aout0,i1spc,i1adr0,i2spc,i2adr0,i3spc,i3adr0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_interp_\ic\_ is globally unique)
;;      sout      = output memory space ('x' or 'y')
;;      aout0     = initial output address in memory sout
;;      i1spc     = input 1 memory space ('x' or 'y')
;;      i1adr0    = initial input address in memory i1spc
;;      i2spc     = input 2 memory space ('x' or 'y')
;;      i2adr0    = initial input address in memory i2spc
;;      i3spc     = interpolation input memory space ('x' or 'y')
;;      i3adr0    = initial input address in memory i3spc
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access      Argument use                 Initialization
;;      ----------      --------------               --------------
;;      x:(R_X)+        address of input 1 signal    i1adr0
;;      y:(R_Y)+        address of input 2 signal    i2adr0
;;      x:(R_X)+        address of interp signal     i3adr0
;;      y:(R_Y)+        address of output signal     aout0
;;
;;  DESCRIPTION
;;      The interp unit-generator interpolates between two signals.  The
;;      output is the first signal plus the difference signal times the 
;;      interpolation signal.
;;      The output vector can be the same as an input vector.
;;      The inner loop is three instructions if the memory spaces
;;      for in1 and in2 are x and y, respectively, otherwise it is four
;;      instructions.
;;
;;      the UG implements: out = in1 + x2*x3 - x1*x3
;;         
;;  DSPWRAP ARGUMENT INFO
;;      interp (prefix)pf,(instance)ic,(dspace)sout,(output)aout,
;;              (dspace)i1spc,(input)i1adr,(dspace)i2spc,(input)i2adr,
;;              (dspace)i3spc,(input)i3adr
;;
;;  MAXIMUM EXECUTION TIME
;;      156 DSP clock cycles for one "tick" which equals 16 audio samples.
;;
;;  MINIMUM EXECUTION TIME
;;      122 DSP clock cycles for one "tick".
;;
;;  CALLING PROGRAM TEMPLATE
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/interp.asm
;;
        define interp_pfx "pf\_interp_\ic\_"    ; pf = <name>_pfx of invoker
        define interp_pfxm """interp_pfx"""
interp macro pf,ic,sout,aout0,i1spc,i1adr0,i2spc,i2adr0,i3spc,i3adr0
        new_xarg interp_pfxm,i1adr,i1adr0       ; allocate x memory argument
        new_yarg interp_pfxm,i2adr,i2adr0       ; allocate y memory argument
        new_xarg interp_pfxm,i3adr,i3adr0       ; allocate x memory argument
        new_yarg interp_pfxm,aout,aout0         ; allocate y memory argument
        move x:(R_X)+,R_I1                      ; input 1 address to R_I1
        move y:(R_Y)+,R_I2                      ; input 2 address to R_I2
        move x:(R_X)+,N0                        ; n0 = interp address
        move y:(R_Y)+,R_O                       ; output address to R_O

        move R_X,N1                           ; save R_X in N1
        move N0,R_X                                ; R_X = interp address
        move i1spc:(R_I1)+,A  
   if "sout"=='y'&&"i3spc"=='x'
        move i3spc:(R_X)+,X0             
   else
        move i3spc:(R_X)+,Y1             
   endif
        move A,Y0

        do #I_NTICK,interp_pfx\tickloop         ; enter do loop
   if "sout"=='y'&&"i3spc"=='x'
          mac -Y0,X0,A      i2spc:(R_I2)+,X1
          mac X1,X0,A       i1spc:(R_I1)+,Y0
   else
          mac -Y1,Y0,A      i2spc:(R_I2)+,X1
          mac Y1,X1,A       i1spc:(R_I1)+,Y0
   endif

		  if "sout"=='x'&&"i3spc"=='y'
            tfr Y0,A      A,sout:(R_O)+    i3spc:(R_X)+,Y1
		  else 
		   if "sout"=='y'&&"i3spc"=='x'
            tfr Y0,A      i3spc:(R_X)+,X0  A,sout:(R_O)+
           else
            tfr Y0,A      A,sout:(R_O)+
		    move i3spc:(R_X)+,Y1
		   endif
          endif

interp_pfx\tickloop

        move N1,R_X                             ; restore R_X
        nop                                     ; for safety
        endm



