; To be included when vectors.asm is not

iv_reset_ 	equ	$00
iv_stk_err 	equ	$02
iv_trace_ 	equ	$04
iv_swi_ 	equ	$06
iv_irq_a 	equ	$08
iv_irq_b 	equ	$0A
iv_ssi_rcv 	equ	$0C
iv_ssi_rcv_exc 	equ	$0E
iv_ssi_xmt 	equ	$10
iv_ssi_xmt_exc 	equ	$12
iv_sci_rcv 	equ	$14
iv_sci_rcv_exc 	equ	$16
iv_sci_xmt 	equ	$18
iv_sci_idle 	equ	$1A
iv_sci_timer 	equ	$1C
iv_nmi 		equ	$1E
iv_host_rcv 	equ	$20
iv_host_rcv2 	equ	$21
iv_host_xmt 	equ	$22
iv_host_xmt2 	equ	$23
iv_host_cmd 	equ	$24
iv_xhm 		equ	$26
iv_dhwd 	equ	$28
iv_kernel_ack 	equ	$2A

