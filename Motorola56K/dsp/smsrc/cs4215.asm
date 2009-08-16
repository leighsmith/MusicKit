;****************************************************************************
;	CS4215.ASM
;	Initialization program for EVM56002 to communicate with CS4215
;  	input connected to Mic inputs
;
;	Copywrite (c) MOTOROLA 1994
;		      Semiconductor Products Sector 
;		      Digital Signal Processing Division
;
; 	7/12/95 - Modified by DAJ for Music Kit
;
;
;****************************************************************************
;
;      portc usage:
;     	bit8: SSI TX (from DSP to Codec)
;	bit7:
;	bit6:
;	bit5:
;	bit4: codec reset (from DSP to Codec)
;	bit3:
;     	bit2: data/control bar
;             0=control
;             1=data
;
;
;  PROGRAM OUTLINE:
;
;1 program fsync and sclk == output
;2 write pc0 = 0 (control mode)
;3 send 64 bit frame x times, with dcb bit = 0, keep doing until read back as 0
;4 send 64 bit frame x times, with dcb bit = 1, keep doing until read back as 1
;5 re-program fsync and sclk == input
;6 write pc0 = 1 (data mode)
; 
;****************************************************************************

HEADPHONE_EN    equ     $800000
LINEOUT_EN      equ     $400000
LEFT_ATTN       equ     $010000 ;63*LEFT_ATTN   = -94.5 dB, 1.5 dB steps
SPEAKER_EN      equ     $004000
RIGHT_ATTN      equ     $000100 ;63*RIGHT_ATTN  = -94.5 dB, 1.5 dB steps
MIC_IN_SELECT   equ     $100000
LEFT_GAIN       equ     $010000 ;15*LEFT_GAIN    = 22.5 dB, 1.5 dB steps
MONITOR_ATTN    equ     $001000 ;15*MONITOR_ATTN = mute,    6   dB steps
RIGHT_GAIN      equ     $000100 ;15*RIGHT_GAIN   = 22.5 dB, 1.5 dB steps
OUTPUT_SET      equ     HEADPHONE_EN+LINEOUT_EN+(LEFT_ATTN*4)
INPUT_SET       equ     MIC_IN_SELECT+(15*MONITOR_ATTN)+(RIGHT_ATTN*4)

;---DSP56002 on-chip peripheral addresses
PCD             equ     $FFE5
PCDDR           equ     $FFE3
PCC             equ     $FFE1
PBC             equ     $FFE0
CRA             equ     $FFEC
CRB             equ     $FFED
IPR             equ     $FFFF
SSISR           equ     $FFEE

;***************************************************************************
;***** 			initialize the CS4215 codec                    *****
;***************************************************************************
; headphones and line out, and set up for no gain or attenuation, and no 
; monitor feedback.
;***************************************************************************
;***************************************************************************
;
;      initialize ssi -- fsync and sclk ==> outputs
;

; These are SSI interrupt vectors that we install temporarily, and then 
; remove again.

; This is the entry point to this file:

init_codec
	move    #YB_DMA_W,R_IO	; 
	movep   #$0000,x:PCC    ;  turn off ssi port 
	movep   #$4303,x:CRA    ;  40MHz/16 = 2.5MHz SCLK, WL=16 bits, 4W/F
	movep   #$0B30,x:CRB    ; NTWK, SYN, FSR/RSR->bit
	movep   #$14,x:PCDDR    ; setup pc2 and pc4 as outputs
	movep   #$0,x:PCD       ; D/C~ and RESET~ = 0 ==> control mode
				;----reset delay for codec ----
	do      #500,_delay_loop
	rep     #2000           ; 100 us delay
	nop
_delay_loop
	bset    #4,x:PCD        ; RESET~ = 1
;	movep	x:IPR,Y0	; Old interrupt priority level	
;	movep   #$3000,x:IPR    ; set interrupt priority level
	move    #3,M_IO         ; Modulus 4 buffer.

	move    x:X_CODEC_CTL1,x0
	move            x0,y:YB_DMA_W
	move    x:X_CODEC_CTL2,x0
	clr     A x0,y:YB_DMA_W+1
	move    A,y:YB_DMA_W+2
	move    A,y:YB_DMA_W+3

;	andi    #$FC,mr         ; enable interrupts
	movep   #$01E8,x:PCC    ; Turn on ssi port

;
; CLB == 0	; Control latch bit
;

	movep y:(R_IO)+,x:M_TX		; ship it
	bset   #12,x:CRB    		; set TE (force transit on next frame synch)
      do #19,_fiveTimes			; 5 times, 4 words each time
	jclr    #6,x:SSISR,*            ; wait until TDE
	movep y:(R_IO)+,x:M_TX		; ship it
_fiveTimes
;
; CLB == 1
;
	bset    #18,y:YB_DMA_W      	;set CLB
       do      #12,_init_loopB		; Send "at least two more frames"
	jclr    #6,x:SSISR,*            ; wait until TDE
	movep y:(R_IO)+,x:M_TX		; ship it
_init_loopB

	movep   #0,x:PCC                ;disable, reset SSI

;*****************************************************************************
;    now CLB should be 1 -- re-program fsync and sclk direction (i/p)
;
	movep   #$4303,x:CRA    ; 16bits,4 word/frame, /2/4/2=2.5 MHz
	movep   #$0B00,x:CRB    ; netwk,syn,sclk==i/p,msb 1st
	movep   #$14,x:PCD      ; D/C~ pin = 1  ==> data mode
	movep   #$01E8,x:PCC    ;  turn on ssi port

;	movep	Y0,x:IPR	; Reset to old interrupt priority level	
	move    #$FFFF,M_IO     ; No modulus
	; It's ok to leave R_IO in a random state because it's set later.

	; Now set up buffer with run-time status.  We have 2 data/2 status
set_codec_runstate		; We may want to make this a hm someday
	move    #YB_DMA_W+2,R_Y
	move	#3,N_Y
	move 	x:X_CODEC_STAT1,X0
	move 	x:X_CODEC_STAT2,X1
	do 	#NB_DMA/4,_prepBuff	; 4 words per sample frame
	  move X0,y:(R_Y)+
	  move X1,y:(R_Y)+N_Y
_prepBuff
	rts




