;;  Copyright 1993 Stanford University.
;;  Author - David Jaffe
;;
;;  Modification history
;;  --------------------
;;  30/01/93/daj - Created from asymp.
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      line (UG macro) - One segment of a linear (ADSR type) envelope
;;
;;  SYNOPSIS
;;      line orch,1,sout,aout0,scl0,off0,rate0,amp0    ; linear segment
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_line_\ic\_ is globally unique)
;;      sout      = output waveform memory space ('x' or 'y')
;;      aout0     = output vector address
;;      scl0      = (final_value-start_value)/2
;;      off0      = (final_value+start_value)/2
;;	rate0	  = 2/duration_in_samples
;;      amp0h     = amplitude, high-order word
;;      amp0l     = amplitude,  low-order word
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access     Argument use        Initialization
;;      ----------     --------------      --------------
;;      x:(R_X+)       output address      aout0
;;      y:(R_Y+)       scale	           scl0
;;      x:(R_X+)       offset              off0
;;      y:(R_Y+)       rate                rate0
;;      x:(R_X+)       envelope state      amp0
;;
;;  DESCRIPTION
;;      Generate I_NTICK samples of a linear segment. In pseudo-C:
;;
;;      aout = x:(R_X)+; /* Output address */
;;      off  = x:(R_X)+; 
;;      scl  = y:(R_Y)+; 
;;      rate = y:(R_Y)+; 
;;      amp  = l:(LARGS)P_L; /* Load initial envelope amplitude */
;;      for (n=0;n<I_NTICK;n++) { /* Compute a tick's worth */
;;           amp += rate;	  
;;           sout:aout[n] = amp * scl + off;
;;      }
;;
;;	The idea here is to use saturation arithmetic to make sure we
;;	don't over/undershoot.  Here's how it works:  
;;
;;	Let F = final line segment value, S = start line segment value
;;	
;;	The UG implements x * scl + off, where x is between -1.0 and 1.0.
;;	We want to make it act as if x were limited between 0.0 and 1.0.
;;	So we set scl = (F-S)/2, off = (F+S)/2.  
;;
;;	This gives us:
;;
;;	x * scl + off   = x * (F-S)/2 + (F+S)/2 
;;			= x * (F-S)/2 + (F-S)/2 + S
;;			= (x+1) * (F-S)/2 + S
;;			= (x+1)/2 * (F-S) + S
;;
;;	which does the desired 0-1 limiting.
;;
;;
;;
;;  DSPWRAP ARGUMENT INFO
;;      line (prefix)pf,(instance)ic,(dspace)sout,(output)aout,
;;              scl,off,rate,amph,ampl
;;
;;  MAXIMUM EXECUTION TIME
;;
;;  MINIMUM EXECUTION TIME
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/line.asm
;;
;;  ALU REGISTER USE
;;      A  = amplitude envelope value amp
;;      X1 = amplitude copied from a
;;      X0 = target trg
;;      Y1 = rate rate
;;
line     macro pf,ic,sout,aout0,scl0,off0,rate0,amp0
; Allocate arguments for this instance
          new_xarg pf\_line_\ic\_,aout,aout0
          new_yarg pf\_line_\ic\_,scl,scl0 
          new_xarg pf\_line_\ic\_,off,off0     
          new_yarg pf\_line_\ic\_,rate,rate0      ; 1/samps
          new_xarg pf\_line_\ic\_,amp,amp0 	  ; current value

	if "sout"=='x'
	  define OFF 'X0'
	  define HI_AMP 'Y0'
        else
	  define OFF 'Y0'
	  define HI_AMP 'X0'
	endif

          move x:(R_X)+,R_O             ; Current output pointer
	  move y:(R_Y)+,Y1		; Y1 = scl

        if "sout"=='x'
          move x:(R_X)+,OFF y:(R_Y)+,Y1  ; OFF = off, Y1 = rate
        else
          move x:(R_X)+,OFF 		; OFF = off
	  move y:(R_Y)+,Y1  		; Y1 = rate
        endif

          move x:(R_X),A                ; load current (long) amplitude to A
          ; We want *aout++ = (amp+=rate) * scl + off;
	  add Y1,A OFF,B 		; amp += rate, offset to B
	  move A,HI_AMP			; amp high bits to Y0
	  macr HI_AMP,X1,B 		; B = new_amp * scale + off
	  do #I_NTICK-1,pf\_line_\ic\_l1
 		  add Y1,A OFF,B B,sout:(R_O)+	; amp += rate, offset to B
		  move A,HI_AMP		; amp high bits to Y0
		  macr HI_AMP,X1,B	; B = new_amp * scale + off
pf\_line_\ic\_l1
	  move B,sout:(R_O)+		; ship last output
	  move A,x:(R_X)+	        ; save last amplitude for next 
          endm


