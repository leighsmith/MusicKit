;;  Author - David Jaffe and Michael McNabb
;;
;;  Modification history
;;  --------------------
;;  11/11/93/daj - original dsp code created
;;  11/17/93/mmm - initial asm file created
;;   8/09/94/gps - fixed rectification bug
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      envFollow (UG macro) - produce a value based on the peaks of the
;;								  input signal
;;
;;  SYNOPSIS
;;      envFollow pf,ic,sout,aout0,sinp,ainp0,s0,rel0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (pf\_scale_\ic\_ globally unique)
;;      sout      = output memory space ('x' or 'y')
;;      aout0     = initial output address in memory sout
;;      sinp      = input memory space ('x' or 'y')
;;      ainp0     = initial input address in memory sinp
;;		s0		  = current level state variable
;;      rel0      = initial release factor [-1.0 to 1.0-2^(-23)]
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access      Argument use                 Initialization
;;      ----------      --------------               --------------
;;      x:(R_X)+        address of input signal      ainp0
;;      y:(R_Y)+        address of output signal     aout0
;;      x:(R_X)+        state variable		         s0
;;      y:(R_Y)+        release factor               rel0
;;
;;  DESCRIPTION
;;      The envFollow unit-generator simply produces a value based on the
;;		peaks of the input signals.
;;         
;;  DSPWRAP ARGUMENT INFO
;;      envFollow (prefix)pf,(instance)ic,(dspace)sout,(output)aout,
;;          	  (dspace)sinp,(input)ainp,s0,rel0
;;
;;  MAXIMUM EXECUTION TIME
;;
;;  MINIMUM EXECUTION TIME
;;
;;  CALLING PROGRAM TEMPLATE
;;      include 'music_macros'        ; utility macros
;;      beg_orch 'tscale'             ; begin orchestra main program
;;           new_yeb invec,I_NTICK,0  ; Allocate input vector
;;           new_yeb outvec,I_NTICK,0 ; Allocate output vector
;;           beg_orcl                 ; begin orchestra loop
;;                ...                 ; put something in input vector
;;                envFollow orch,1,y,outvec,y,invec,0,0.99 ; invocation
;;                ...                 ; do something with output vector
;;           end_orcl                 ; end of orchestra loop
;;      end_orch 'tscale'             ; end of orchestra main program
;;
;;  SOURCE
;;    
;;
;;  ALU REGISTER USE
;;
envFollow macro pf,ic,sout,aout0,sinp,ainp0,s0,rel0
        new_xarg pf\_scale_\ic\_,ainp,ainp0
        new_yarg pf\_scale_\ic\_,aout,aout0
        new_xarg pf\_scale_\ic\_,s,s0
        new_yarg pf\_scale_\ic\_,rel,rel0

    if "sout"=='x'
        define s 'Y0'
    else
        define s 'X0'
    endif

        move x:(R_X)+,R_I1      ; input address to R_I1
        move y:(R_Y)+,R_O       ; output address to R_O
        move x:(R_X),s      	; state variable (increment R_X at end)
        move y:(R_Y)+,Y1        ; release factor

        do #I_NTICK,pf\_envFollow_\ic\_tickloop
		mpyr s,Y1,A  sinp:(R_I1)+,B     ; precompute. get in
		abs B				; take absolute value of input
		cmp  A,B			; form (in - curLevel)
		tlt  A,B		; if in<curLevel,curLev=curLev*rel
		move B,s B,sout:(R_O)+	; prepare next mpy input, ship output
pf\_envFollow_\ic\_tickloop

	  move B,x:(R_X)+                         ; store filter state
      endm


