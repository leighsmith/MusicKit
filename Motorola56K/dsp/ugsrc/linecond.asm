;;  Copyright 1993 Stanford University.  All rights reserved.
;;
;;  Modification history
;;  --------------------
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      line (UG macro) - One segment of a linear (ADSR type) envelope
;;
;;  SYNOPSIS
;;      line orch,1,sout,aout0,targ0,inc0h,inc0l,amp0h,amp0l    ; linear segment
;;
;;  MACRO ARGUMENTS
;;
;;  DSP MEMORY ARGUMENTS
;;
;;  DESCRIPTION
;;
;;	if (amp == target) 
;;		for (i=0; i<NTICK; i++) 
;;			sout[i] = target;
;;	else {
;;		for (i=0; i<NTICK; i++)
;;			sout[i] = (amp += inc);
;;		if (inc < 0) {	/* Check for clipping */
;;			if (amp < target) {
;;				amp = target;
;;				for (i=NTICK; i>0; i--)
;;					if (sout[i] < target)
;;						sout[i] = target;
;;			}
;;		} else {
;;			if (amp > target)
;;				amp = target;
;;				for (i=NTICK; i>0; i--)
;;					if (sout[i] > target)
;;						sout[i] = target;
;;			}
;;		}
;;	}
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
;;
;;  ALU REGISTER USE
;;
line     macro pf,ic,sout,aout0,targ0,inc0h,inc0l,amp0h,amp0l
; Allocate arguments for this instance
        new_xarg pf\_line_\ic\_,aout,aout0      ; output loc
        new_yarg pf\_line_\ic\_,targ,targ0      ; destination
        new_larg pf\_line_\ic\_,inc,inc0h,inc0l ; increment 
        new_larg pf\_line_\ic\_,amp,amp0h,amp0l ; current value
        move x:LARGS,R_I1		; Get L arg pointer
        move x:(R_X)+,R_O             	; Current output pointer
	move y:(R_Y)+,Y1		; Y1 = target
        move l:(R_I1)+,A              	; load (long) increment to A
        move l:(R_I1),B               	; load (long) amplitude to B
	cmp Y1,B			; target reached?
	jne pf\_line_\ic\_ramp 		; jump if not at target
					; At target
	do #I_NTICK,pf\_line_\ic\_l1	; just ship constant
		move B,sout:(R_O)+
pf\_line_\ic\_l1
	jmp pf\_line_\ic\_end		; jump to end

pf\_line_\ic\_ramp 			; not at target.  Compute line
	add A,B				; compute first sample
	do #I_NTICK,pf\_line_\ic\_l2
		add A,B B,sout:(R_O)+
pf\_line_\ic\_l2
	move B,sout:(R_O)		; ship last output
	tst A				; see if we're going up or down
	jge pf\_line_\ic\_up		; jump if we're going up
					; Going down
	cmp Y1,B			; are we there?				 
	jge pf\_line_\ic\_end		; jmp if not there or exactly there
	do #I_NTICK,pf\_line_\ic\_l3	; clip 
		move sout:(R_O),A
		cmp Y1,A
		tlt Y1,A
		move A,sout:(R_O)-
pf\_line_\ic\_l3
	move Y1,B			; set amp to target
	jmp pf\_line_\ic\_end			
	
pf\_line_\ic\_up			; Going up
	cmp Y1,B			; are we there?				 
	jle pf\_line_\ic\_end		; jmp if not there or exactly there
	do #I_NTICK,pf\_line_\ic\_l4	; clip
		move sout:(R_O),A
		cmp Y1,A
		tgt Y1,A
		move A,sout:(R_O)-
pf\_line_\ic\_l4
	move Y1,B			; set amp to target
	jmp pf\_line_\ic\_end			

pf\_line_\ic\_end	 		
	move A,l:(R_I1)P_L              ; save last amplitude for next 
	move R_I1,x:LARGS               ; save arg pointer
        endm


