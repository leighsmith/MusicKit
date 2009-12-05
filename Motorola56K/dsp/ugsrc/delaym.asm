;;  Author - David Jaffe
;;
;;  Modification history
;;  --------------------
;;  3/16/96/daj - Created from delay.asm (apparently jos once made a delaym.asm,
;; 		  but it doesn't seem to exist anymore)
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      delaym (UG macro) - sample-based delay line using modulo indexing
;;
;;  SYNOPSIS
;;      delaym pf,ic,sout,aout0,sinp,ainp0,sdel,pdel0,mod0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_delaym_\ic\_ is globally unique)
;;      sout      = output vector memory space ('x' or 'y')
;;      aout0     = initial output vector memory address
;;      sinp      = input vector memory space ('x' or 'y')
;;      ainp0     = initial input vector memory address
;;      sdel      = delay-line memory space ('x' or 'y')
;;      pdel0     = delay-line pointer
;;      mod0      = delay length - 1
;;
;;  DSP MEMORY ARGUMENTS
;;      Access         Description              Initialization
;;      ------         -----------              --------------
;;      x:(R_X)+       Output address           aout0
;;      x:(R_X)+       Delay pointer            pdel0
;;      y:(R_Y)+       delay line length -1     mod0
;;      y:(R_Y)+       Input address            ainp0
;;
;;  DESCRIPTION
;;
;;      The delaym unit-generator implements a simple delay line using 
;;      modulo storage.  
;;
;;      For best performance, the input and output signals should be in the same
;;      memory space, which should be different from the delay-line memory space.
;;      I.e., if the delay table is in x memory, both input and output should be 
;;      in y memory, or vice versa.
;;      
;;      In pseudo-C notation:
;;
;;      aout = x:(R_X)+;
;;      ainp = x:(R_X)+;
;;      pdel = x:(R_X)+;
;;      edel = y:(R_Y)+;
;;      adel = y:(R_Y)+;
;;
;;      for (n=0;n<I_NTICK;n++) {
;;           sout:aout[n] = sdel:pdel[n];
;;           sdel:pdel[n] = sinp:ainp[n];
;;           if (++pdel>=edel) pdel=adel;
;;      }
;;
;;  DSPWRAP ARGUMENT INFO
;;      delaym (prefix)pf,(instance)ic,
;;         (dspace)sout,(output)aout,
;;         (dspace)sinp,(input)ainp,
;;         (dspace)sdel,(address)pdel,mod0
;;
;;  MAXIMUM EXECUTION TIME
;;
;;  MINIMUM EXECUTION TIME
;;
;;  SOURCE
;;      delaym.asm
;;
;;  ALU REGISTER USE
;;       A = temporary register for input signal
;;       B = temporary register for output signal
;;
delaym     macro pf,ic,sout,aout0,sinp,ainp0,sdel,pdel0,mod0
        new_xarg pf\_delaym_\ic\_,aout,aout0   ; output address arg
        new_xarg pf\_delaym_\ic\_,pdel,pdel0   ; current pointer arg
        new_yarg pf\_delaym_\ic\_,mod,mod0     ; length-1 arg
        new_yarg pf\_delaym_\ic\_,ainp,ainp0   ; input address arg
		
        move x:(R_X)+,R_O        ; output address to R_O
        move x:(R_X),R_I2        ; delay pointer to R_I2, update on exit
        move y:(R_Y)+,M_I2	 ; modulo value (length-1)
        move y:(R_Y)+,R_I1       ; input address to R_I1
        do #I_NTICK,pf\_delaym_\ic\_tickloop
	   if "sdel==sinp"
		move sdel:(R_I2),B
		move sinp:(R_I1)+,A
	   else
        	move sdel:(R_I2),B sinp:(R_I1)+,A 
	   endif
	   if "sout==sdel"
		move B,sout:(R_O)+ 
		move A,sdel:(R_I2)+
	   else
		move B,sout:(R_O)+ A,sdel:(R_I2)+
	   endif
pf\_delaym_\ic\_tickloop
	move #>$FFFF,M_I2	; restore modulo modifier register
        move R_I2,x:(R_X)+      ; save delay pointer for next entry
     endm


