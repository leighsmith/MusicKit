;; Copyright 1990 NeXT Computer, Inc.  All rights reserved.
;; Author - David Jaffe
;;
;; Modification history
;; --------------------
;; 05/10/88/daj - initial file created from /usr/local/lib/dsp/ugsrc/onepole.asm
;; 05/20/88/daj - passed test ttwopole.asm for YX case
;; 05/23/88/daj - added other memory space combos (not tested!)
;; 11/30/92/daj - fixed several assembly bugs.
;; 1/9/94/daj - rewrote to fix some memory space combos
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      twopole (UG macro) - two-pole digital filter section
;;
;;  SYNOPSIS
;;      twopole pf,ic,sout,aout0,sinp,ainp0,s10,s20,bb00,aa10,aa20
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_twopole_\ic\_ is globally unique)
;;      sout      = output vector memory space ('x' or 'y')
;;      aout0     = initial output vector memory address
;;      sinp      = input vector memory space ('x' or 'y')
;;      ainp0     = initial input vector memory address
;;      bb00      = initial coefficient of undelayed input
;;      aa10      = initial coefficient of negated, once-delayed output
;;      aa20      = initial coefficient of negated, twice-delayed output
;;      s1        = state variable = once-delayed output
;;      s2        = state variable = twice-delayed output
;;
;;  DSP MEMORY ARGUMENTS
;;      The following is for the YX case: (y is output, x is input)
;;      Access         Description              Initialization
;;      ------         -----------              --------------
;;      x:(R_X)+       aa1 coefficient          aa10
;;      x:(R_X)+       aa2 coefficient          aa20
;;      x:(R_X)+       bb0 coefficient          bb00
;;      y:(R_Y)+       Current output address   aout0
;;      y:(R_Y)+       Current input address    ainp0
;;      y:(R_Y)+       s2 state variable         s20
;;      y:(R_Y)+       s1 state variable         s10
;;
;;  DESCRIPTION
;;      The twopole unit-generator implements a two-pole
;;      filter section in direct form. In pseudo-C notation:
;;
;;      ainp = x:(R_X)+;
;;      aout = x:(R_X)+;
;;      s2 = y:(R_Y)+;
;;      s1 = y:(R_Y)+;
;;      aa1 = x:(R_X)+;
;;      aa2 = x:(R_X)+;
;;      bb0 = x:(R_X)+;
;;
;;      for (n=0;n<I_NTICK;n++) {
;;           sout:aout[n] = bb0*sinp:ainp[n] - aa1*s1 - aa2*s2;
;;           s2 = s1            
;;           s1 = sout:aout[n]
;;      }
;;        
;;  DSPWRAP ARGUMENT INFO
;;      twopole (prefix)pf,(instance)ic,
;;         (dspace)sout,(output)aout,
;;         (dspace)sinp,(input)ainp,s1,s2,bb0,aa1,aa2
;;
;;  MAXIMUM EXECUTION TIME
;;	220 * (DSP_CLOCK_PERIOD / DSPMK_I_NTICK))
;;
;;  MINIMUM EXECUTION TIME
;;	YX case: 	306 * (DSP_CLOCK_PERIOD / DSPMK_I_NTICK))
;;	Other cases:	336 * (DSP_CLOCK_PERIOD / DSPMK_I_NTICK))
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/twopole.asm
;;
;;  SEE ALSO
;;      /usr/local/lib/dsp/ugsrc/biquad.asm  - two-pole, two-zero filter section
;;      /usr/local/lib/dsp/ugsrc/onezero.asm - one-zero filter section
;;      /usr/local/lib/dsp/ugsrc/onepole.asm - one-pole filter section
;;      /usr/local/lib/dsp/ugsrc/twopole.asm - two-pole filter section
;; 
;;  ALU REGISTER USE
;;      X0 = coefficients
;;	if sinp==x, 
;;      	X1 = input sample
;;      	Y1 = s1 = once delayed output
;;	else 
;;      	Y1 = input sample
;;      	X1 = s1 = once delayed output
;;      Y0 = s2 = twice delayed output
;;      A = multiply-add accumulator
;;
twopole macro pf,ic,sout,aout0,sinp,ainp0,s10,s20,bb00,aa10,aa20
             new_xarg pf\_twopole_\ic\_,aa1,aa10   ; once-delayed input coeff
             new_xarg pf\_twopole_\ic\_,aa2,aa20   ; twice-delayed input coeff
             new_xarg pf\_twopole_\ic\_,bb0,bb00   ; undelayed input coeff
             new_yarg pf\_twopole_\ic\_,aout,aout0 ; output address arg
             new_yarg pf\_twopole_\ic\_,ainp,ainp0 ; input address arg
             new_yarg pf\_twopole_\ic\_,s2,s20     ; twice delayed input samp
             new_yarg pf\_twopole_\ic\_,s1,s10     ; once delayed input samp

	if "sinp"=='y'
	  define INP 'Y1'
	  define ST1 'X1'
	else 
	  define INP 'X1'
	  define ST1 'Y1'
	endif

	  define A1COEFF 'B1'			; aa1
	  define A2COEFF 'B0'			; aa2
	
             move y:(R_Y)+,R_I2          	; output address to R_I2
             move y:(R_Y)+,R_I1                 ; input address to R_I1
	     move y:(R_Y)+,Y0     		; s2 to Y0
             move y:(R_Y)-,ST1      		; s1 to ST1
	     move x:(R_X)+,A1COEFF		; aa1
	     move x:(R_X)+,A2COEFF		; aa2
             move x:(R_X),X0 			; bb0 (x:(R_X)) to X0 
             move sinp:(R_I1)+,INP              ; first input
                                                ; compute the first sample
             mpy INP,X0,A A1COEFF,X0    	; bb0 * in, get aa1
             mac -ST1,X0,A A2COEFF,X0	    	; aa1 * s1, get aa2
             macr -Y0,X0,A ST1,Y0          	; aa2 * s2, s1 to s2
             move x:(R_X),X0 			; get bb0
	     move A,ST1 sinp:(R_I1)+,INP	; y(n) to s1

             do #I_NTICK-1,pf\_twopole_\ic\_tickloop
              if "sout"=='y'&&"sinp"=='x'
                ; input * bb0, fetch next input and deposit previous output
                mpy     INP,X0,A   sinp:(R_I1)+,INP  A,sout:(R_I2)+       
                move    A1COEFF,X0   			; aa1 to X0
		mac     -ST1,X0,A       A2COEFF,X0     	; y(n-1) * aa1, aa2 to X0
                macr    -Y0,X0,A        ST1,Y0          ; y(n-2) * aa2, s2 = s1
                move    x:(R_X),X0 A,ST1            	; get bb0, y(n) to s1
	      else
                mpy     INP,X0,A      A,sout:(R_I2)+    ; input * bb0, ship output
		move 	A1COEFF,X0   			; aa1 to X0
		mac     -ST1,X0,A       A2COEFF,X0     	; y(n-1) * aa1, aa2 to X0
                macr    -Y0,X0,A        ST1,Y0          ; y(n-2) * aa2, s2 = s1
                move    x:(R_X),X0 			; get bb0
		move 	A,ST1 sinp:(R_I1)+,INP 		; y(n) to s1, get input
	      endif

pf\_twopole_\ic\_tickloop    

	     move A,sout:(R_I2)			; ship last output
             move x:(R_X)+,X0 Y0,y:(R_Y)+       ; save s2, increment R_X
	     move ST1,y:(R_Y)+    		; save s1
     endm
