;;  Copyright 1996 Stanford University, CCRMA, all rights reserved
;;  Author - David Jaffe
;;
;;  Modification history
;;      03/30/96/daj - created, based on asymp and Julius' slpdur
;;-----------------------------------------------------------------------------
;;  NAME
;;      asympenv (UG macro) - Asymptotic envelope with tables of breakpoints
;;
;;  SYNOPSIS
;;      asympenv pf,ic,sout,aout0,val0h,val0l,trg0,x,antrg0,dur0,y,andur0,
;;		rate0,y,anrate0
;;
;;  MACRO ARGUMENTS
;;      pf    = global label prefix (any text unique to invoking macro)
;;      ic    = instance count (such that pf\_asympenv_\ic\_ is globally unique)
;;      sout  = output envelope memory space ('x' or 'y')
;;      aout0 = initial output address in memory sout (0 to $FFFF)
;;      val0h,val0l  = Initial envelope value
;;      trg0  = Target 1 value
;;      antrg0 = Address of next target value
;;      dur0  = Dur 1 value
;;      andur0 = Address of next dur value
;;      rate0  = Rate 1 value
;;      anrate0 = Address of next rate value
;;
;;  DSP MEMORY ARGUMENTS
;;      Arg access     Argument use
;;      ----------     ------------
;;      x:LARGS P_L    Current value
;;      x:(R_X)+       Current output
;;      x:(R_X)+       Current target
;;      x:(R_X)+       Address of next target
;;      x:(R_X)+       Current rate
;;      x:(R_Y)+       Current dur
;;      y:(R_Y)+       Address of next dur
;;      y:(R_Y)+       Address of next rate
;;
;;  DESCRIPTION
;;      The asympenv unit-generator computes piecewise-linear envelope
;;      functions specified by target/duration/rate tables in dsp memory.
;;      The envelope and its specifications are single precision values 
;;	(24 bits).  The target list must be in x memory
;;      and the duration and rate lists must be in y memory. 
;;      
;;	See asymp for explanation of rate and target.
;;
;;      The "duration" of each segment is the number of ticks (not samples) the
;;      current segment is computed.
;;      When the duration is counted down to zero, the 
;;      next target/duration/rate triple is selected from the envelope 
;;      tables.
;;      
;;      A value of -1 ($FFFFFF) means "stick". In this case, the current
;;	value is output.
;;      
;;	To halt asympenv, simply set dur to -1. To resume it, set dur to 0,
;;	which will cause it to immediately get the next triple from its tables.
;;  
;;  DSPWRAP ARGUMENT INFO
;;      asympenv  (prefix)pf,(instance)ic,(dspace)sout,(output)aout,valh,vall,
;;		trg,(literal)x,(address)antrg,dur,(literal)y,(address)andur,rate,(literal)y,(address)anrate
;;
;;  MINIMUM EXECUTION TIME
;;      Typical execution time occurs within a asymp segment. See asymp.
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/asympenv.asm
;;
;;  ALU REGISTER USE
;;
; Allocate arguments for this instance
asympenv    macro pf,ic,sout,aout0,val0h,val0l,trg0,strg,antrg0,dur0,sdur,andur0,rate0,srate,anrate0
        new_larg pf\_asympenv_\ic\_,val,val0h,val0l     ; Envelope State

        new_xarg pf\_asympenv_\ic\_,aout,aout0          ; Output location
        new_xarg pf\_asympenv_\ic\_,trg,trg0            ; Current target
        new_xarg pf\_asympenv_\ic\_,antrg,antrg0        ; Next-target pointer
        new_xarg pf\_asympenv_\ic\_,rate,rate0          ; Current rate

        new_yarg pf\_asympenv_\ic\_,dur,dur0            ; Current dur count
        new_yarg pf\_asympenv_\ic\_,andur,andur0        ; Next-duration pointer
        new_yarg pf\_asympenv_\ic\_,anrate,anrate0      ; Next-rate pointer
        
        move x:(R_X)+,R_O          	; output pointer
        move x:(R_X)+,X0 y:(R_Y),B 	; trg and dur 
        tst B x:LARGS,R_I1	   	; Get L arg ptr
        move #>1,X1                   	; load duration decrement ($000001)
	jsle pf\_asympenv_\ic\_subr	; Jump to subr only on abnormal case
	sub X1,B l:(R_I1),A		; Decrement, load cur val

	; Here, R_X is antrg, R_Y is dur
	move B,y:(R_Y)+			; store new dur
					; now R_Y is andur
        move (R_X)+			; advance R_X to rate
	move (R_Y)+			; now R_Y is anrate
	move x:(R_X)+,Y1 		; get rate
					; R_X to next ug's args
; At this point, A = val(long), X0 = target, Y1 = rate
; First envelope sample
        mac  X0,Y1,A  A,X1            	; A=A+t*r = val+r*trg
        mac  -X1,Y1,A (R_Y)+          	; A=A-r*val = val*(1-r)+r*trg
					; now R_Y is at next ug's args
; Remaining I_NTICK-1 envelope samples:
        do #I_NTICK-1,pf\_asympenv_\ic\_l1
             mac X0,Y1,A A,X1         	; X1 = sample1 val, A=A+f*r
             mac -X1,Y1,A X1,sout:(R_O)+ ; X1 out, A = sample2 val
pf\_asympenv_\ic\_l1
	move A,l:(R_I1)+              	; save last val for next 
					; (A10?) & increment arg pointer
        move A,sout:(R_O)+            	; write out last result
	move R_I1,x:LARGS		; restore LARGS
  
  beg_subr
pf\_asympenv_\ic\_subr
        jeq pf\_asympenv_\ic\_next 	; 0 duration => advance to next segment
pf\_asympenv_\ic\_neg_dur          	; negative duration => special mode
        move x:(R_I1),X0           	; slam target to high order part of val
        jmp pf\_asympenv_\ic\_cont 
pf\_asympenv_\ic\_next  	   	; advance to next segment
	move (R_Y)+
        move x:(R_X)-,R_I1         	; load antrg, R_X to trg
        move y:(R_Y)-,R_I2         	; load andur, R_Y to dur
	nop
        move x:(R_I1)+,A y:(R_I2)+,B	; new trg and dur
					; trg assumed in X space!
					; dur assumed in Y space!
        move A,x:(R_X)+ B,y:(R_Y)+    	; new trg and dur to arg blk
        move R_I1,x:(R_X)+            	; new antrg to arg blk, R_X to rate
	move (R_Y)+
	move y:(R_Y)-,R_I1		; load anrate
        move R_I2,y:(R_Y)+            	; new andur to arg blk, R_Y to anrate
	move y:(R_I1)+,X1		; new rate
					; rate assumed in Y space!
	move X1,x:(R_X)-		; new rate to arg blk, R_X to antrg
	move R_I1,y:(R_Y)-		; new anrate to arg blk,R_Y to andur
	move (R_Y)-			; R_Y to dur
        tst B x:LARGS,R_I1            	; check new duration, get LARGS
        jlt pf\_asympenv_\ic\_neg_dur 	; if dur negative, we're at the end
        jeq pf\_asympenv_\ic\_cont    	; if zero, don't decrement duration:
	move #>1,X1			; decrement amount
	rts
pf\_asympenv_\ic\_cont     
	move #0,X1			; decrement amount
	rts
  end_subr



     endm


