; sys_memory_map.asm - written by dspmsg from system symbols.
;
; This DSP system include file contains definitions for host-message 
; opcodes as well as other system entry points needed by DSP programs which 
; are to be assembled without the DSP system code. For example, stand-alone 
; orchestra and array processing test programs need this file. 
;

;***** GLOBAL SYMBOLS *****
DE_ADMPWE		 EQU $0000a0
DE_BREAK		 EQU $000080
DE_DHRERR		 EQU $000091
DE_DMAWRECK		 EQU $000090
DE_DMA_ABORT		 EQU $0000a8
DE_DMQOVFL		 EQU $000093
DE_HF2_ON_2		 EQU $0000a7
DE_HMARGERR		 EQU $000081
DE_HMSBUSY		 EQU $000096
DE_HMSOVFL		 EQU $000094
DE_HMSUFL		 EQU $000095
DE_ILLHM		 EQU $00008e
DE_ILLSUB		 EQU $00008d
DE_LC		 EQU $000085
DE_LMEMARG		 EQU $0000a5
DE_NO_PROG		 EQU $0000a6
DE_PC		 EQU $000082
DE_PLE_SYSMM		 EQU $0000a9
DE_RESET		 EQU $00008f
DE_SCROVFL		 EQU $0000a1
DE_SP		 EQU $000086
DE_SR		 EQU $000084
DE_SSH		 EQU $000083
DE_SSIWDU		 EQU $0000a2
DE_STATUS0		 EQU $00008a
DE_STATUS1		 EQU $00008b
DE_STATUS2		 EQU $00008c
DE_TIME0		 EQU $000087
DE_TIME1		 EQU $000088
DE_TIME2		 EQU $000089
DE_TMQEOIF		 EQU $00009f
DE_TMQFULL		 EQU $000097
DE_TMQHMM		 EQU $00009c
DE_TMQMI		 EQU $000099
DE_TMQREADY		 EQU $000098
DE_TMQRWPL		 EQU $00009e
DE_TMQTM		 EQU $00009d
DE_TMQTMM		 EQU $00009b
DE_TMQU		 EQU $00009a
DE_USER_ERR		 EQU $0000ab
DE_WFP_BAD		 EQU $0000aa
DE_XHMILL		 EQU $000092
DE_XMEMARG		 EQU $0000a3
DE_YMEMARG		 EQU $0000a4
DM_DM_MIDI_MSG		 EQU $000008
DM_DM_OFF		 EQU $000006
DM_DM_ON		 EQU $000007
DM_HMS_ROOM		 EQU $00001d
DM_HM_DONE		 EQU $00000b
DM_HM_FIRST		 EQU $000020
DM_HM_LAST		 EQU $000021
DM_HOST_R_DONE		 EQU $000003
DM_HOST_R_REQ		 EQU $000005
DM_HOST_R_SET1		 EQU $000009
DM_HOST_W_DONE		 EQU $000002
DM_HOST_W_REQ		 EQU $000004
DM_IAA		 EQU $000011
DM_IDLE		 EQU $00000f
DM_ILLDSPMSG		 EQU $000000
DM_KERNEL_ACK		 EQU $000001
DM_LC		 EQU $000015
DM_MAIN_DONE		 EQU $00000c
DM_NOT_IN_USE		 EQU $000010
DM_PC		 EQU $000012
DM_PEEK0		 EQU $00000d
DM_PEEK1		 EQU $00000e
DM_SP		 EQU $000016
DM_SR		 EQU $000014
DM_SSH		 EQU $000013
DM_SSI_WDU		 EQU $00001f
DM_STATUS0		 EQU $00001a
DM_STATUS1		 EQU $00001b
DM_STATUS2		 EQU $00001c
DM_TIME0		 EQU $000017
DM_TIME1		 EQU $000018
DM_TIME2		 EQU $000019
DM_TMQ_LWM		 EQU $00000a
DM_TMQ_ROOM		 EQU $00001e
DM_USER_MSG		 EQU $000022

;***** PH SYMBOLS (DISPATCH ADDRESSES) *****
		xdef hm_abort
hm_abort	 equ $003fec

		xdef hm_adc_loop
hm_adc_loop	 equ $003fc0

		xdef hm_block_off
hm_block_off	 equ $003f96

		xdef hm_block_on
hm_block_on	 equ $003f94

		xdef hm_block_tmq_lwm
hm_block_tmq_lwm	 equ $003fc6

		xdef hm_blt_p
hm_blt_p	 equ $003f72

		xdef hm_blt_x
hm_blt_x	 equ $003f6e

		xdef hm_blt_y
hm_blt_y	 equ $003f70

		xdef hm_clear_break
hm_clear_break	 equ $003f86

		xdef hm_clear_dma_hm
hm_clear_dma_hm	 equ $003f38

		xdef hm_close_paren
hm_close_paren	 equ $003fc4

		xdef hm_dm_off
hm_dm_off	 equ $003f3a

		xdef hm_dm_on
hm_dm_on	 equ $003f3c

		xdef hm_dma_rd_ssi_off
hm_dma_rd_ssi_off	 equ $003f4e

		xdef hm_dma_rd_ssi_on
hm_dma_rd_ssi_on	 equ $003f4c

		xdef hm_dma_wd_ssi_off
hm_dma_wd_ssi_off	 equ $003f52

		xdef hm_dma_wd_ssi_on
hm_dma_wd_ssi_on	 equ $003f50

		xdef hm_done_int
hm_done_int	 equ $003f98

		xdef hm_done_noint
hm_done_noint	 equ $003f9a

		xdef hm_echo
hm_echo	 equ $003f76

		xdef hm_execute
hm_execute	 equ $003fa0

		xdef hm_execute_hm
hm_execute_hm	 equ $003fa2

		xdef hm_fill_p
hm_fill_p	 equ $003f6c

		xdef hm_fill_x
hm_fill_x	 equ $003f68

		xdef hm_fill_y
hm_fill_y	 equ $003f6a

		xdef hm_first
hm_first	 equ $003f38

		xdef hm_get_time
hm_get_time	 equ $003f7e

		xdef hm_go
hm_go	 equ $003f8a

		xdef hm_halt
hm_halt	 equ $003fb8

		xdef hm_high_srate
hm_high_srate	 equ $003fb0

		xdef hm_hm_first
hm_hm_first	 equ $003faa

		xdef hm_hm_last
hm_hm_last	 equ $003fac

		xdef hm_hms_room
hm_hms_room	 equ $003f92

		xdef hm_host_r
hm_host_r	 equ $003f3e

		xdef hm_host_r_done
hm_host_r_done	 equ $003f40

		xdef hm_host_rd_done
hm_host_rd_done	 equ $003fb6

		xdef hm_host_rd_off
hm_host_rd_off	 equ $003f46

		xdef hm_host_rd_on
hm_host_rd_on	 equ $003f44

		xdef hm_host_w
hm_host_w	 equ $003f42

		xdef hm_host_w_dt
hm_host_w_dt	 equ $003fbc

		xdef hm_host_w_swfix
hm_host_w_swfix	 equ $003fbe

		xdef hm_host_wd_done
hm_host_wd_done	 equ $003fb4

		xdef hm_host_wd_off
hm_host_wd_off	 equ $003f4a

		xdef hm_host_wd_on
hm_host_wd_on	 equ $003f48

		xdef hm_idle
hm_idle	 equ $003f78

		xdef hm_jsr
hm_jsr	 equ $003fa4

		xdef hm_last
hm_last	 equ $003fce

		xdef hm_load_state
hm_load_state	 equ $003fa8

		xdef hm_low_srate
hm_low_srate	 equ $003fb2

		xdef hm_main_done
hm_main_done	 equ $003ff4

		xdef hm_midi_msg
hm_midi_msg	 equ $003fae

		xdef hm_open_paren
hm_open_paren	 equ $003fc2

		xdef hm_peek_n
hm_peek_n	 equ $003f5c

		xdef hm_peek_p
hm_peek_p	 equ $003f58

		xdef hm_peek_r
hm_peek_r	 equ $003f5a

		xdef hm_peek_x
hm_peek_x	 equ $003f54

		xdef hm_peek_y
hm_peek_y	 equ $003f56

		xdef hm_poke_n
hm_poke_n	 equ $003f66

		xdef hm_poke_p
hm_poke_p	 equ $003f62

		xdef hm_poke_r
hm_poke_r	 equ $003f64

		xdef hm_poke_x
hm_poke_x	 equ $003f5e

		xdef hm_poke_y
hm_poke_y	 equ $003f60

		xdef hm_reset_ap
hm_reset_ap	 equ $003ff6

		xdef hm_reset_ipr
hm_reset_ipr	 equ $003f7c

		xdef hm_reset_soft
hm_reset_soft	 equ $003f7a

		xdef hm_save_state
hm_save_state	 equ $003fa6

		xdef hm_say_something
hm_say_something	 equ $003f74

		xdef hm_service_tmq
hm_service_tmq	 equ $003ff0

		xdef hm_service_write_data
hm_service_write_data	 equ $003ff8

		xdef hm_set_break
hm_set_break	 equ $003f84

		xdef hm_set_dma_r_m
hm_set_dma_r_m	 equ $003fca

		xdef hm_set_dma_w_m
hm_set_dma_w_m	 equ $003fcc

		xdef hm_set_start
hm_set_start	 equ $003f88

		xdef hm_set_time
hm_set_time	 equ $003f80

		xdef hm_set_tinc
hm_set_tinc	 equ $003f82

		xdef hm_sine_test
hm_sine_test	 equ $003fba

		xdef hm_step
hm_step	 equ $003f8c

		xdef hm_tmq_lwm_me
hm_tmq_lwm_me	 equ $003f90

		xdef hm_tmq_room
hm_tmq_room	 equ $003f8e

		xdef hm_trace_off
hm_trace_off	 equ $003f9e

		xdef hm_trace_on
hm_trace_on	 equ $003f9c

		xdef hm_unblock_tmq_lwm
hm_unblock_tmq_lwm	 equ $003fc8

		xdef hm_was_reset_soft
hm_was_reset_soft	 equ $003fee

		xdef hm_write_data_switch
hm_write_data_switch	 equ $003ff2

		xdef loc_x_dma_wfp
loc_x_dma_wfp	 equ $003fea

		xdef main_done
main_done	 equ $003ff4

