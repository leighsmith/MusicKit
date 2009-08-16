;;  Copyright 1990 NeXT Computer, Inc.  All rights reserved.
;;  Author - Julius Smith
;;
;;  Modification history
;;  --------------------
;;  08/01/87/jos - changed delay.asm to delayticks.asm so delay could be arb.
;;  30/01/93/daj - Changed to not use obsolete R_L -- David Jaffe
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      delayticks (UG macro) - tick-based delay line using non-modulo indexing
;;
;;  SYNOPSIS
;;      delayticks pf,ic,sout,aout0,sinp,ainp0,sdel,adel0,pdel0,edel0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (such that pf\_delayticks_\ic\_ is unique)
;;      sout      = output vector memory space ('x' or 'y')
;;      aout0     = initial output vector memory address
;;      sinp      = input vector memory space ('x' or 'y')
;;      ainp0     = initial input vector memory address
;;      sdel      = delay-line memory space ('x' or 'y')
;;      adel0     = initial delay-line start address
;;      pdel0     = initial delay-line pointer
;;      edel0     = initial address of first sample beyond delay line
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
;;      The delayticks unit-generator implements a simple delay line using a
;;      circular buffer (not modulo storage) which is a multiple of the tick size
;;      in length.  It is less efficient than the delaym unit generator but more
;;      efficient than the delay unit generator: The address boundaries of the
;;      delay line memory are arbitrary (though their difference must be an
;;      integer multiple of the tick size I_NTICK).
;;      
;;      For best performance, the input and output signals should be in the same
;;      memory space, which should be different from the delay-line memory space.
;;      I.e., if the delay table is in x memory, both input and output should be in
;;      y memory, or vice versa.
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
;;      }
;;      pdel+=I_NTICK;
;;      if (pdel>=edel) pdel=adel;   /* Bounds check NOT in inner loop */
;;
;;  DSPWRAP ARGUMENT INFO
;;      delayticks (prefix)pf,(instance)ic,
;;         (dspace)sout,(output)aout,(dspace)sinp,(input)ainp,
;;         (dspace)sdel,(address)adel,(address)pdel,(address)edel
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/delayticks.asm
;;
;;  ALU REGISTER USE
;;      Y1 = start address of delay line
;;      Y0 = last address of delay line
;;       A = temporary register for input signal
;;       B = temporary register for output signal
;;
delayticks macro pf,ic,sout,aout0,sinp,ainp0,sdel,adel0,pdel0,edel0
               new_xarg pf\_delayticks_\ic\_,aout,aout0   ; output address arg
               new_xarg pf\_delayticks_\ic\_,ainp,ainp0   ; input address arg
               new_xarg pf\_delayticks_\ic\_,pdel,pdel0   ; current pointer arg
               new_yarg pf\_delayticks_\ic\_,edel,edel0   ; last-address+1 arg
               new_yarg pf\_delayticks_\ic\_,adel,adel0   ; start-address arg

ndel0          set edel0-adel0                    ; initial delay-line length
               if I_NTICK*(ndel0/I_NTICK)!=ndel0  ; must be multiple of a tick
                    fail 'delayticks: delay line not a multiple of tick size'
               endif

               move x:(R_X)+,R_O        ; output address to R_O
               move x:(R_X)+,R_I1       ; input address to R_I1
               move x:(R_X),R_I2        ; delay pointer to R_I2, update on exit

               if "sout"!="sdel"        ; use R_X instead of R_I2 for dly ptr
                    move R_Y,N_Y        ; save R_Y in an unused place
		    move R_X,N_X	; same for R_X
		    move R_O,R_X	; Use R_X instead of R_O so we can get
					; parallel move in inner loop.
               endif

               do #I_NTICK,pf\_delayticks_\ic\_tickloop
                    ; load current input to A, current delay value to B
                    if "sinp"=="sdel"
                         move sinp:(R_I1)+,A
                         if "sout"=="sdel"
                              move sdel:(R_I2),B  ; no post-increment is right
                         else
                              move sdel:(R_I2)+,B ; post-inc since R_L used
                         endif
                    else
                         if "sout"=="sdel"
                              move sinp:(R_I1)+,A sdel:(R_I2),B
                         else
                              move sinp:(R_I1)+,A sdel:(R_I2)+,B
                         endif
                    endif

                    ; output current delay-line value, overwrite with input
                    if "sout"=="sdel"
                         move A,sdel:(R_I2)+
                         move B,sout:(R_O)+
                    else
                         move A,sdel:(R_Y)+ B,sout:(R_X)+
                    endif
pf\_delayticks_\ic\_tickloop    
               if "sout"!="sdel"
                    move N_X,R_X       ; restore R_X
                    move N_Y,R_Y       ; restore R_Y
               endif
               move R_I2,A              ; delay pointer for next entry
               move y:(R_Y)+,Y0         ; delay pointer when out of bounds
               cmp Y0,A  y:(R_Y)+,Y1    ; check boundary, start adr to Y1 
               tge Y1,A                 ; wrap around if necessary
;               If the end address is accidentally passed instead of end+1, 
;               the end-test still works (unless the tick size is only 1).
               if UG_DEBUG
                    jlt _sign_ok
                    DEBUG_HALT
_sign_ok
               endif
               move A,x:(R_X)+          ; save delay pointer for next entry
     endm


