; This file may be included by unit generators
;
; Author: David A. Jaffe
; Copyright CCRMA, Stanford U. 1993.
;

;************************************************************************
;
;	EQUATES for Ariel Quint Processor
;
;************************************************************************

; Last Update 21 Feb 93   

;------------------------------------------------------------------------
;
;	EQUATES for Hub (master) DSP.  All these are in Y space.
;
;------------------------------------------------------------------------
Y_QP_CMD_A	EQU	$FFC0	; Write/read slaveA command port
Y_QP_CMD_B	EQU	$FFC1	; Write/read slaveB command port
Y_QP_CMD_C	EQU	$FFC2	; Write/read slaveC command port
Y_QP_CMD_D	EQU	$FFC3	; Write/read slaveD command port
Y_QP_DATA_A	EQU	$FFC4	; Write/read slaveA data port
Y_QP_DATA_B	EQU	$FFC5	; Write/read slaveB data port
Y_QP_DATA_C	EQU	$FFC6	; Write/read slaveC data port
Y_QP_DATA_D	EQU	$FFC7	; Write/read slaveD data port

;	$FFC8-$FFCF are unused

;	$FFD0-$FFDF are SCSI chip registers

Y_QP_CMD_ALL	EQU	$FFF0	; Write simultaneously to all cmd ports
Y_QP_DATA_ALL	EQU	$FFF1	; Write simultaneously to all data ports
Y_QP_SCSI_DMA_RESP EQU	$FFF2	; DMA response to SCSI chip

;	EQUATES for Hub (master) DSP access to GLUE chip registers 
Y_QP_SLAVE_INT_ENA EQU	$FFF8	; Write/read Slave interrupt enable register
Y_QP_MISC_INT_ENA  EQU	$FFF9	; Write/read Misc interrupt enable register
Y_QP_MASTER_CTL    EQU	$FFFA	; Write/read Master's control register
Y_QP_SLAVE_INT_STAT EQU	$FFFB	; Read slave interrupt status register
Y_QP_SCSI_INT_STAT EQU	$FFFC	; Read SCSI/DMC interrupt status register
Y_QP_SLAVE_INT_PRI EQU	$FFFD	; Read slave interrupt priority register
Y_QP_SCSI_INT_PRI EQU	$FFFE	; Read SCSI/DMC interrupt priority register
Y_QP_MISC_INT_STAT EQU	$FFFF	; Read Misc interrupt status register

; These bits are used for the slave interrupt enable register, 
; as well as the slave interrupt status register
QP_B__XMT_A 	EQU 	0
QP_B__RCV_A 	EQU 	1
QP_B__XMT_B 	EQU 	2
QP_B__RCV_B 	EQU 	3
QP_B__XMT_C 	EQU 	4
QP_B__RCV_C 	EQU 	5
QP_B__XMT_D 	EQU 	6
QP_B__RCV_D 	EQU 	7

;	EQUATES for Hub (master) Y memory ports for the DRAM controller
Y_QP_DRAM_R_ADDR       EQU $FFE0
Y_QP_DRAM_W_ADDR       EQU $FFE1
Y_QP_DRAM_R_DATA       EQU $FFE2
Y_QP_DRAM_W_DATA       EQU $FFE3
Y_QP_DRAM_R_DATA_BURST EQU $FFE4
Y_QP_DRAM_W_DATA_BURST EQU $FFE5
Y_QP_DRAM_CONFIG       EQU $FFE6

;------------------------------------------------------------------------
;
;	EQUATES for Sat (slave) DSPs
;
;------------------------------------------------------------------------

Y_QP_DATA		EQU $FFC0	; Read/write data port
Y_QP_CMD_STAT	        EQU $FFC1	; Read status port.  Read/write command port.
Y_QP_CTL		EQU $FFC2	; Write control port


;------------------------------------------------------------------------
;
;	Debug codes (values of QPSTAT)
;	These are not part of the QP spec.  They are codes used in
;	our QP monitors to aid in debugging.  QPSTAT is only maintained
;	if SYS_DEBUG is 1
;
;------------------------------------------------------------------------

; For hub, QP_B__WAITING means we are waiting for satellites to take our semaphore word,
; indicating that they have a buffer ready. 
; For satellites, this means that we are waiting for the hub to write a word
; to us so that we can take it indicating that we have a buffer ready.
QP_B__WAITING	equ $111111

; For hub, QP_B__RUNNING means that we have successfully pulled one buffer's worth
; of samples from the satellites.
QP_B__RUNNING	equ $222222

; Otherwise, for hub, value is current value of the loop counter in the sample
; pulling loop. For satellite, value is the current value of R_IO, the pointer being
; pulled by the hub.

;------------------------------------------------------------------------
;
;	DRAM macros. These are for unit generators that run on the qp hub.
;	begin_dram_access turns off refresh if it is on.
;	end_dram_access turns on refresh, but only if the global
;	flag B__DRAM_AUTOREFRESH is set in y:Y_DEVSTAT.  This provides
;	a global way to enable/disable auto-refresh for different situations.
;	For example, very low sampling rates may require auto-refresh.
;
;	Important note: these macros may only be used once per unit generator,
;	due to the labels.  If you really need to use them several times,
;	copy the macro code and change the label names.
;
;------------------------------------------------------------------------
begin_dram_access macro
	bset #B__DRAM_ACCESSING,y:DEVSTAT 	 ; signal we're in this code
	jclr #7,y:Y_QP_MASTER_CTL,bdr_no_change ; we're already not refreshing?
	bclr #7,y:Y_QP_MASTER_CTL	  	 ; turn off refresh
refoff jset #7,y:Y_QP_MASTER_CTL,refoff 	 ; wait for it to really turn off
bdr_no_change
	endm

end_dram_access macro
        jclr #B__DRAM_AUTOREFRESH,y:DEVSTAT,edr_no_change  ; doing implicit refresh?
	bset #7,y:Y_QP_MASTER_CTL		; turn on refresh
edr_no_change
	bclr #B__DRAM_ACCESSING,y:DEVSTAT	; signal we're out of this code
	endm

