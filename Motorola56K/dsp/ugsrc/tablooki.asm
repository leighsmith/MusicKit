;;  A table-lookup Unit Generator for use in nonlinear distortion
;;  synthesis. Features Linear Interpolation between entries in the table.
;;
;;  Author - Eric J. Graves & David A. Jaffe
;;           (c) 1992 Eric J. Graves & Stanford University 
;;           
;;  Modification history
;;  --------------------
;;  04/06/92/ejg - initial file created
;;  04/28/92/ejg - non-interpolating version tested.
;;  04/29/92/ejg - implemented interpolation; cleaned up code for efficiency.
;;  05/19/92/ejg-daj - corrected a nasty bug that accessed un-owned memory.
;;  10-11/92/ejg - improved to avoid the rep x1 asr a construct (use mul instead)
;;  12/16/92/ejg - corrected the grittiness introduced by the mul method
;;		   when using interpolation. 
;;   9/26/93/daj - Modified to be non-circular and other revisions
;;
;;-----------------------------------------------------------------------
;;  NAME
;;	tablooki (UG macro) - UG lookup table.
;;
;;  SYNOPSIS
;;	tablooki pf,ic,sout,aout0,sinv,ainv0,stablook,atablook0,halflen0
;;
;;  MACRO ARGUMENTS
;;	pf        = global label prefix (any text unique to invoking macro)
;;	ic        = instance count (s.t. pf\_tablooki_\ic\_ is globally unique)
;;	sout      = output waveform memory space ('x' or 'y')
;;	aout0     = output vector address
;;	sinv      = the space in which the input value is received.
;;	ainv0     = the address of the input value signal
;;	stablook      = table memory space ('x' or 'y')
;;	atablook0     = table address
;;	halflen0   = half table length.
;;
;;  DSP MEMORY ARGUMENTS
;;	Arg access     Argument use             Initialization
;;	----------     --------------           --------------
;;	x:(R_X)+       Input Signal pointer     ainv0
;;	x:(R_X)+       Table base address	atablook0
;;	x:(R_X)+       const. factor for shift	halflen0
;;	y:(R_Y)+       output address           aout0
;;
;;  DESCRIPTION
;;	Generate I_NTICK lookups from the table.
;;
;;      In pseudo-C:
;;
;;      ainv = x:(R_X)+;           /* input patchpoint address      */
;;      atablook = x:(R_X)+;       /* wave table address            */
;;      halftablelen = x:(R_X)+;   /* half table length             */
;;      aout = y:(R_Y)+;           /* output patchpoint address     */
;;
;;      for (n=0;n<I_NTICK;n++) {
;; 	     phs0  = ainv0[n]		/*Get the input value*/
;;	     phs0  = phs0 * halflen + halflen;
;;	     extra = phs0 "leftovers"; /*No good C notation for 
;;					this--what it means is that 
;;				        bits that get shifted off the
;;				        right of phs0 go into extra*/
;;	     s1    = stablook:atablook[phs1];
;;	     phs1  = (phs1+1);
;;	     s2    = stablook:atablook[phs2];
;;           diff  = s2 - s1;
;;           samp  = s1;
;;	     extra = extra >> 1;	/*We don't want extra to be negative, so all the
;;					  bits down and put a 0 in the MSB*/
;;           samp  = samp + diff*(extra);
;;           sout:aout[n] = samp;	/*Store the output!*/
;;      }
;;
;;  USAGE RESTRICTIONS
;;	The wavetable length must be odd.
;;      halflen must be equal to the table length-1, divided by 2.
;;
;;  DSPWRAP ARGUMENT INFO
;;	tablooki (prefix)pf,(instance)ic,(dspace)sout,(output)aout,
;;         (dspace)sinv,(input)ainv,(dspace)stablook,
;;         (address)atablook,halflen
;;
;;  MAXIMUM EXECUTION TIME
;;      632 DSP clock cycles for one "tick" which equals 16 audio samples.
;;
;;  MINIMUM EXECUTION TIME
;;      464 DSP clock cycles for one "tick"
;;
;;  SOURCE
;;	E. Graves. Written from scratch. 
;;
;;  TEST PROGRAM
;;	None
;;
;;  SEE ALSO
;;      LeBrun (1979) and Arfib (1979) and Roads (1979) articles.
;;
;;  ALU REGISTER USE
;;      X0 = the corrected details (fractional part of address).
;;      X1 = halflen
;;	Y1 = s1 until "move y1,a"; then, 
;;	     s0 (the difference s2-s1)
;;       B = B1 = the details (p0) -- after copied out of a0
;;	 B = (temp/scratch) -- after we've put the details into X0
;;       A = input value (gets normalized) -- at start of loop.
;;	     A1 = index into table (p1 and p2) -- after normalization and shifting
;;	     A0 = the details (p0) -- after normalization and shifting. 
;;
tablooki   macro pf,ic,sout,aout0,sinv,ainv0,stablook,atablook0,halflen0

          new_yarg pf\_tablooki_\ic\_,aout,aout0
          new_xarg pf\_tablooki_\ic\_,ainv,ainv0
          new_xarg pf\_tablooki_\ic\_,atablook,atablook0
          new_xarg pf\_tablooki_\ic\_,halflen,halflen0

; Set up data alu regs from state held in memory arguments
          move y:(R_Y)+,R_O        ; Output signal pointer
          move x:(R_X)+,R_I1       ; Input signal pointer. (temporary)
	  move x:(R_X)+,R_I2	   ; Table base address.
          clr a x:(R_X)+,x1        ; get halftablelen
	  move x1,a1 	   	   ; set up pipe

;; Basic initialization is now done.

          do #I_NTICK,pf\_tablooki_\ic\_tickloop
		move sinv:(R_I1)+,y1	; get input
		mac y1,x1,a #>1,b	; a = input * halflen + halflen 
					; || put a 1 in B1 (so we can increment A later),
					;    this also clears b0 and b2
		add B,A	a1,N_I2		; increment A.
					; || store first index into table		
		move a0,b1		; move the details from a0 into b1
		move stablook:(R_I2+N_I2),y1 ; put s1 into y1.
		lsr b a1,N_I2		; shift b (b1) (the details) right by 1, 
					; blanking the negative bit, avoid false negative 
					; || store the 2nd index into the table into N_I2
		move b1,x0		; put the actual,corrected details in x0 
		move stablook:(R_I2+N_I2),b ; get s2.
		sub y1,b y1,a		; get s0 into b (=s2 [b] - s1 [y1])
			 		; || put s1 into a
		move b1,y1		; put s0 in y1.
		macr x0,y1,a		; a+=x0*y1 (corrected details*s0)
					; so now a has s1 + details*s0
		move a,sout:(R_O)+ 	; move it out.
		move x1,a1		; halflen into a1
pf\_tablooki_\ic\_tickloop
          endm
