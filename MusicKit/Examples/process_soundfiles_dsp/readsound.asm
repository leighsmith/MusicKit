;;  Copyright 1989 by NeXT Inc.
;;  Author - Julius Smith
;;
;;  Modification history
;;  --------------------
;;  08/30/89/jos - created from delayticks.asm
;;  08/31/89/daj - passed "read data" test using timed sends from Music Kit
;;  11/23/92/daj - changed to do left shift so libdsp short arrays can be used
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      readsound (UG macro) - read mono, tick-based, non-modulo memory buffer
;;
;;  SYNOPSIS
;;      readsound pf,ic,sout,aout0,sbuf,abuf0,pbuf0,ebuf0
;;
;;  MACRO ARGUMENTS
;;      pf        = global label prefix (any text unique to invoking macro)
;;      ic        = instance count (such that pf\_readsound_\ic\_ is unique)
;;      sout      = output vector memory space ('x' or 'y')
;;      aout0     = initial output vector memory address
;;      sbuf      = input buffer memory space ('x' or 'y')
;;      abuf0     = initial input buffer start address
;;      pbuf0     = initial input buffer pointer
;;      ebuf0     = initial address of first sample beyond input buffer
;;
;;  DSP MEMORY ARGUMENTS
;;      Access         Description              Initialization
;;      ------         -----------              --------------
;;      x:(R_X)+       Output address           aout0
;;      x:(R_X)+       Read pointer             pbuf0
;;      y:(R_Y)+       Last address + 1         ebuf0
;;      y:(R_Y)+       Start address            abuf0   
;;
;;  DESCRIPTION
;;      
;;      The readsound unit-generator writes its output signal from a 
;;	single-channel input memory buffer which can be any multiple
;;	of the tick size in length.  The readsound UG is typically used to
;;	feed a host-written buffer to a unit-generator patch.
;;      The address boundaries of the input buffer are arbitrary, except
;;	that their difference must be an integer multiple of the tick size.
;;      
;;      For best performance, the input buffer and the output signal should 
;;	be in different memory spaces.
;;
;;      Note that the input buffer is assumed to be right-justified.
;;
;;      In pseudo-C notation:
;;
;;      aout = x:(R_X)+;
;;      pbuf = x:(R_X)+;
;;      ebuf = y:(R_Y)+;
;;      abuf = y:(R_Y)+;
;;
;;      for (n=0;n<I_NTICK;n++)
;;           sout:aout[n] = sbuf:pbuf[n] << 8;
;;      pbuf+=I_NTICK;
;;      if (pbuf>=ebuf) pbuf=abuf;   /* Bounds check NOT in inner loop */
;;
;;  DSPWRAP ARGUMENT INFO
;;      readsound (prefix)pf,(instance)ic,
;;         (dspace)sout,(address)aout,
;;         (dspace)sbuf,(address)abuf,(address)pbuf,(address)ebuf
;;
;;  TEST PROGRAM
;;      none
;;
;;  SOURCE
;;      /LocalDeveloper/Examples/MusicKit/process_sounds_dsp/readsound.asm
;;
;;  ALU REGISTER USE
;;      Y1 = start address of input buffer
;;      Y0 = last address of input buffer
;;       B = temporary register for output signal, read pointer
;;
          beg_def 'readsound'
readsound macro pf,ic,sout,aout0,sbuf,abuf0,pbuf0,ebuf0
          beg_mac 'readsound'
               new_xarg pf\_readsound_\ic\_,aout,aout0   ; output address arg
               new_xarg pf\_readsound_\ic\_,pbuf,pbuf0   ; current pointer arg
               new_yarg pf\_readsound_\ic\_,ebuf,ebuf0   ; last-address+1 arg
               new_yarg pf\_readsound_\ic\_,abuf,abuf0   ; start-address arg

nbuf0          set ebuf0-abuf0                   ; initial input buffer length
               if I_NTICK*(nbuf0/I_NTICK)!=nbuf0 ; must be multiple of a tick
                    fail 'readsound: input buffer not a multiple of tick size'
               endif

               move x:(R_X)+,R_O        ; output address to R_O
               move x:(R_X),R_I1        ; read pointer to R_I1, update on exit
  	       move #>@pow(2,-16),Y0    ; one-byte left shift = two-byte right-shift
 	       move sbuf:(R_I1)+,Y1	; rev up pipe
               do #I_NTICK-1,pf\_readsound_\ic\_tickloop
		 mpy Y0,Y1,B 		; not mpyr which rounds B1, clearing B0
                 if "sout"=="sbuf"
                   move B0,sout:(R_O)+
 		   move sbuf:(R_I1)+,Y1
                 else
 		   move sbuf:(R_I1)+,Y1 B0,sout:(R_O)+
                 endif
pf\_readsound_\ic\_tickloop    
	       mpy Y0,Y1,B 		; not mpyr which rounds B1, clearing B0
               move B0,sout:(R_O)+	; last output
               move R_I1,B              ; read pointer for next entry
               move y:(R_Y)+,Y0         ; read pointer when out of bounds
               cmp Y0,B  y:(R_Y)+,Y1    ; check boundary, start adr to Y1 
               tge Y1,B                 ; wrap around if necessary
               move B,x:(R_X)+          ; save read pointer for next entry
; Check:
;   If the end address is accidentally passed instead of end+1, 
;   the end-test still works (unless the tick size is only 1).
               if UG_DEBUG
                    jlt _sign_ok
                    DEBUG_HALT
_sign_ok
               endif
          end_mac 'readsound'
     endm
     end_def 'readsound'

