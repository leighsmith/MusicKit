#ifndef __MK_dsp_messages_1.0_H___
#define __MK_dsp_messages_1.0_H___
/* dsp_messages.h - written by dspmsg from system symbols.

This include file contains definitions for "host-message" and 
"DSP message" opcodes used by the Music Kit (MK) and Array Processing (AP)
libraries.  These definitions do not change as the DSP system software is 
upgraded, except that new definitions may be added.

"Host messages" are mnemonics for DSP system subroutine entry points. 
They are called by the host for communication purposes via the
DSPCall() or DSPHostMessage() functions in libdsp.  Each host message 
opcode has the prefix "DSP_HM".

"DSP messages" are one-word (24 bit) messages which flow from the 
DSP to the host.  DSP messages use the prefix "DSP_DM".

A DSP message consists of one byte of opcode and two bytes of data.
Opcodes from 128 to 255 are, by MK/AP convention, error messages, and
their prefix is "DSP_DE" rather than "DSP_DM".

*/ 

/***** GLOBAL SYMBOLS *****/
#define DSP_DE_ABORT	 0x0000a8
#define DSP_DE_ADMPWE	 0x0000a0
#define DSP_DE_BREAK	 0x000080
#define DSP_DE_DHRERR	 0x000091
#define DSP_DE_DMAWRECK	 0x000090
#define DSP_DE_DMQOVFL	 0x000093
#define DSP_DE_HF2_ON_2	 0x0000a7
#define DSP_DE_HMARGERR	 0x000081
#define DSP_DE_HMSBUSY	 0x000096
#define DSP_DE_HMSOVFL	 0x000094
#define DSP_DE_HMSUFL	 0x000095
#define DSP_DE_ILLHM	 0x00008e
#define DSP_DE_ILLSUB	 0x00008d
#define DSP_DE_LC	 0x000085
#define DSP_DE_LMEMARG	 0x0000a5
#define DSP_DE_NO_PROG	 0x0000a6
#define DSP_DE_PC	 0x000082
#define DSP_DE_PLE_SYSMM	 0x0000a9
#define DSP_DE_RESET	 0x00008f
#define DSP_DE_SCROVFL	 0x0000a1
#define DSP_DE_SP	 0x000086
#define DSP_DE_SR	 0x000084
#define DSP_DE_SSH	 0x000083
#define DSP_DE_SSIWDU	 0x0000a2
#define DSP_DE_STATUS0	 0x00008a
#define DSP_DE_STATUS1	 0x00008b
#define DSP_DE_STATUS2	 0x00008c
#define DSP_DE_TIME0	 0x000087
#define DSP_DE_TIME1	 0x000088
#define DSP_DE_TIME2	 0x000089
#define DSP_DE_TMQEOIF	 0x00009f
#define DSP_DE_TMQFULL	 0x000097
#define DSP_DE_TMQHMM	 0x00009c
#define DSP_DE_TMQMI	 0x000099
#define DSP_DE_TMQREADY	 0x000098
#define DSP_DE_TMQRWPL	 0x00009e
#define DSP_DE_TMQTM	 0x00009d
#define DSP_DE_TMQTMM	 0x00009b
#define DSP_DE_TMQU	 0x00009a
#define DSP_DE_USER_ERR	 0x0000ab
#define DSP_DE_WFP_BAD	 0x0000aa
#define DSP_DE_XHMILL	 0x000092
#define DSP_DE_XMEMARG	 0x0000a3
#define DSP_DE_YMEMARG	 0x0000a4
#define DSP_DM_DM_MIDI_MSG	 0x000008
#define DSP_DM_DM_OFF	 0x000006
#define DSP_DM_DM_ON	 0x000007
#define DSP_DM_HMS_ROOM	 0x00001d
#define DSP_DM_HM_DONE	 0x00000b
#define DSP_DM_HM_FIRST	 0x000020
#define DSP_DM_HM_LAST	 0x000021
#define DSP_DM_HOST_R_DONE	 0x000003
#define DSP_DM_HOST_R_REQ	 0x000005
#define DSP_DM_HOST_R_SET1	 0x000009
#define DSP_DM_HOST_W_DONE	 0x000002
#define DSP_DM_HOST_W_REQ	 0x000004
#define DSP_DM_IAA	 0x000011
#define DSP_DM_IDLE	 0x00000f
#define DSP_DM_ILLDSPMSG	 0x000000
#define DSP_DM_KERNEL_ACK	 0x000001
#define DSP_DM_LC	 0x000015
#define DSP_DM_MAIN_DONE	 0x00000c
#define DSP_DM_NOT_IN_USE	 0x000010
#define DSP_DM_PC	 0x000012
#define DSP_DM_PEEK0	 0x00000d
#define DSP_DM_PEEK1	 0x00000e
#define DSP_DM_SP	 0x000016
#define DSP_DM_SR	 0x000014
#define DSP_DM_SSH	 0x000013
#define DSP_DM_SSI_WDU	 0x00001f
#define DSP_DM_STATUS0	 0x00001a
#define DSP_DM_STATUS1	 0x00001b
#define DSP_DM_STATUS2	 0x00001c
#define DSP_DM_TIME0	 0x000017
#define DSP_DM_TIME1	 0x000018
#define DSP_DM_TIME2	 0x000019
#define DSP_DM_TMQ_LWM	 0x00000a
#define DSP_DM_TMQ_ROOM	 0x00001e
#define DSP_DM_USER_MSG	 0x000022

/***** PH SYMBOLS (DISPATCH ADDRESSES) *****/
#define DSP_HM_ABORT	 0x003fec
#define DSP_HM_ADC_LOOP	 0x003fc0
#define DSP_HM_BLOCK_OFF	 0x003f96
#define DSP_HM_BLOCK_ON	 0x003f94
#define DSP_HM_BLOCK_TMQ_LWM	 0x003fc6
#define DSP_HM_BLT_P	 0x003f72
#define DSP_HM_BLT_X	 0x003f6e
#define DSP_HM_BLT_Y	 0x003f70
#define DSP_HM_CLEAR_BREAK	 0x003f86
#define DSP_HM_CLEAR_DMA_HM	 0x003f38
#define DSP_HM_CLOSE_PAREN	 0x003fc4
#define DSP_HM_DM_OFF	 0x003f3a
#define DSP_HM_DM_ON	 0x003f3c
#define DSP_HM_DMA_RD_SSI_OFF	 0x003f4e
#define DSP_HM_DMA_RD_SSI_ON	 0x003f4c
#define DSP_HM_DMA_WD_SSI_OFF	 0x003f52
#define DSP_HM_DMA_WD_SSI_ON	 0x003f50
#define DSP_HM_DONE_INT	 0x003f98
#define DSP_HM_DONE_NOINT	 0x003f9a
#define DSP_HM_ECHO	 0x003f76
#define DSP_HM_EXECUTE	 0x003fa0
#define DSP_HM_EXECUTE_HM	 0x003fa2
#define DSP_HM_FILL_P	 0x003f6c
#define DSP_HM_FILL_X	 0x003f68
#define DSP_HM_FILL_Y	 0x003f6a
#define DSP_HM_FIRST	 0x003f38
#define DSP_HM_GET_TIME	 0x003f7e
#define DSP_HM_GO	 0x003f8a
#define DSP_HM_HALT	 0x003fb8
#define DSP_HM_HIGH_SRATE	 0x003fb0
#define DSP_HM_HM_FIRST	 0x003faa
#define DSP_HM_HM_LAST	 0x003fac
#define DSP_HM_HMS_ROOM	 0x003f92
#define DSP_HM_HOST_R	 0x003f3e
#define DSP_HM_HOST_R_DONE	 0x003f40
#define DSP_HM_HOST_RD_DONE	 0x003fb6
#define DSP_HM_HOST_RD_OFF	 0x003f46
#define DSP_HM_HOST_RD_ON	 0x003f44
#define DSP_HM_HOST_W	 0x003f42
#define DSP_HM_HOST_W_DT	 0x003fbc
#define DSP_HM_HOST_W_SWFIX	 0x003fbe
#define DSP_HM_HOST_WD_DONE	 0x003fb4
#define DSP_HM_HOST_WD_OFF	 0x003f4a
#define DSP_HM_HOST_WD_ON	 0x003f48
#define DSP_HM_IDLE	 0x003f78
#define DSP_HM_JSR	 0x003fa4
#define DSP_HM_LAST	 0x003fce
#define DSP_HM_LOAD_STATE	 0x003fa8
#define DSP_HM_LOW_SRATE	 0x003fb2
#define DSP_HM_MAIN_DONE	 0x003ff4
#define DSP_HM_MIDI_MSG	 0x003fae
#define DSP_HM_OPEN_PAREN	 0x003fc2
#define DSP_HM_PEEK_N	 0x003f5c
#define DSP_HM_PEEK_P	 0x003f58
#define DSP_HM_PEEK_R	 0x003f5a
#define DSP_HM_PEEK_X	 0x003f54
#define DSP_HM_PEEK_Y	 0x003f56
#define DSP_HM_POKE_N	 0x003f66
#define DSP_HM_POKE_P	 0x003f62
#define DSP_HM_POKE_R	 0x003f64
#define DSP_HM_POKE_X	 0x003f5e
#define DSP_HM_POKE_Y	 0x003f60
#define DSP_HM_RESET_AP	 0x003ff6
#define DSP_HM_RESET_IPR	 0x003f7c
#define DSP_HM_RESET_SOFT	 0x003f7a
#define DSP_HM_SAVE_STATE	 0x003fa6
#define DSP_HM_SAY_SOMETHING	 0x003f74
#define DSP_HM_SERVICE_TMQ	 0x003ff0
#define DSP_HM_SERVICE_WRITE_DATA	 0x003ff8
#define DSP_HM_SET_BREAK	 0x003f84
#define DSP_HM_SET_DMA_R_M	 0x003fca
#define DSP_HM_SET_DMA_W_M	 0x003fcc
#define DSP_HM_SET_START	 0x003f88
#define DSP_HM_SET_TIME	 0x003f80
#define DSP_HM_SET_TINC	 0x003f82
#define DSP_HM_SINE_TEST	 0x003fba
#define DSP_HM_STDERR	 0x003fee
#define DSP_HM_STEP	 0x003f8c
#define DSP_HM_TMQ_LWM_ME	 0x003f90
#define DSP_HM_TMQ_ROOM	 0x003f8e
#define DSP_HM_TRACE_OFF	 0x003f9e
#define DSP_HM_TRACE_ON	 0x003f9c
#define DSP_HM_UNBLOCK_TMQ_LWM	 0x003fc8
#define DSP_HM_WRITE_DATA_SWITCH	 0x003ff2
#define DSP_LOC_SOUND_PAR_1	 0x003fe4
#define DSP_LOC_SOUND_PAR_2	 0x003fe5
#define DSP_LOC_SOUND_PAR_3	 0x003fe6
#define DSP_LOC_SOUND_PAR_4	 0x003fe7
#define DSP_LOC_UNUSED	 0x003feb
#define DSP_LOC_X_DMA_WFP	 0x003fea
#define DSP_LOC_XHMTA_RETURN_FOR_TZM	 0x003fe8
#define DSP_MAIN_DONE1	 0x003b5f

#endif
