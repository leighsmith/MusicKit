;;  Copyright 1993 CCRMA, Stanford University.  All rights reserved.
;;  Author - David Jaffe
;;
;;  Modification history
;;  --------------------
;;  3/08/93/daj - Created.
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      delayqp (UG macro) - sample-based delay for dram using non-modulo indexing
;;
;;  SYNOPSIS
;;      delayqp pf,ic,sout,aout0,sinp,ainp0,adel0,pdel0,edel0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (s.t. pf\_delayqp_\ic\_ is globally unique)
;;      sout      = output vector memory space ('x' or 'y')
;;      aout0     = initial output vector memory address
;;      sinp      = input vector memory space ('x' or 'y')
;;      ainp0     = initial input vector memory address
;;      adel0     = delay-line start address (in dram space)
;;      pdel0     = delay-line pointer (in dram space)
;;      edel0     = address of first sample beyond delay line (in dram space)
;;
;;  DSP MEMORY ARGUMENTS
;;      Access         Description              Initialization
;;      ------         -----------              --------------
;;      x:(R_X)+       Output address           aout0
;;      x:(R_X)+       Input address            ainp0
;;      x:(R_X)+       Delay pointer            pdel0
;;      y:(R_Y)+       Last address + 1         edel0
;;      y:(R_Y)+       Start address            adel0   
;;
;;  DESCRIPTION
;;
;;      The delayqp unit-generator implements a simple delay line using a circular
;;      buffer (not modulo storage), in dram space.  
;;
;;      For best performance, the input and output signals should be in the same
;;      memory space.
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
;;           sout:aout[n] = pdel[n];
;;           pdel[n] = sinp:ainp[n];
;;           if (++pdel>=edel) pdel=adel;
;;      }
;;
;;  DSPWRAP ARGUMENT INFO
;;      delayqp (prefix)pf,(instance)ic,
;;         (dspace)sout,(output)aout,
;;         (dspace)sinp,(input)ainp,
;;         adel,pdel,edel
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/delayqp.asm
;;
;;  ALU REGISTER USE
;;      Y1 = start address of delay line
;;      Y0 = last address of delay line
;;      X1 = input sample 
;;	 B = output (delayed) sample
;;      X0 = holds a 1 for address increment
;;       A = delay address
;;
  include 'qp.asm'

delayqp     macro pf,ic,sout,aout0,sinp,ainp0,adel0,pdel0,edel0
               new_xarg pf\_delayqp_\ic\_,aout,aout0   ; output address arg
               new_xarg pf\_delayqp_\ic\_,ainp,ainp0   ; input address arg
               new_xarg pf\_delayqp_\ic\_,pdel,pdel0   ; current pointer arg
               new_yarg pf\_delayqp_\ic\_,edel,edel0   ; last-address+1 arg
               new_yarg pf\_delayqp_\ic\_,adel,adel0   ; start-address arg

	       begin_dram_access
               move x:(R_X)+,R_O        ; output address to R_O
               move x:(R_X)+,R_I1       ; input address to R_I1
               move x:(R_X),A           ; delay pointer to A, update on exit
               move y:(R_Y)+,Y0         ; delay pointer when out of bounds
               move y:(R_Y)+,Y1         ; start adr to Y1 
	       move #>1,X0		; for incrementing address
               do #I_NTICK,pf\_delayqp_\ic\_tickloop
                    cmp Y0,A            ; check against last address + 1
                    tge Y1,A            ; wrap around if necessary
		    move sinp:(R_I1)+,X1 ; load input to X1
    		    ; get current delay read value
		    movep A,y:Y_QP_DRAM_R_ADDR  ; first set read address
		    movep y:Y_QP_DRAM_R_DATA,B ; get data & put it in B
		    move B,sout:(R_O)+ ; ship old delay-line value
                    ; overwrite with input
		    movep A,y:Y_QP_DRAM_W_ADDR  ; first set write address
		    movep X1,y:Y_QP_DRAM_W_DATA ; put data from X1
		    ; increment address
		    add X0,A 
pf\_delayqp_\ic\_tickloop    
	       end_dram_access
	       move A,x:(R_X)+          ; save dram pointer for next entry
     endm


