#ifndef __MK__dsp_message_names_H___
#define __MK__dsp_message_names_H___
/* $Id$
 * Written by dspmsg from system symbols.

This private include file provides two string arrays useful for decoding 
DSP-message and DSP-error-message opcodes.

*/
	static int   DSPNErrorNames = 45;

	static char *DSPErrorNames[] = {
		"BREAK",
		"HMARGERR",
		"PC",
		"SSH",
		"SR",
		"LC",
		"SP",
		"TIME0",
		"TIME1",
		"TIME2",
		"STATUS0",
		"STATUS1",
		"STATUS2",
		"ILLSUB",
		"ILLHM",
		"RESET",
		"DMAWRECK",
		"DHRERR",
		"XHMILL",
		"DMQOVFL",
		"HMSOVFL",
		"HMSUFL",
		"HMSBUSY",
		"TMQFULL",
		"TMQREADY",
		"TMQMI",
		"TMQU",
		"TMQTMM",
		"TMQHMM",
		"TMQTM",
		"TMQRWPL",
		"TMQEOIF",
		"ADMPWE",
		"SCROVFL",
		"SSIWDU",
		"XMEMARG",
		"YMEMARG",
		"LMEMARG",
		"NO_PROG",
		"HF2_ON_2",
		"ABORT",
		"PLE_SYSMM",
		"WFP_BAD",
		"USER_ERR",
		"KERNEL_ACK"};


	static int DSPNMessageNames = 38;

	static char *DSPMessageNames[] = {
		"ILLDSPMSG",
		"KERNEL_ACK",
		"HOST_W_DONE",
		"HOST_R_DONE",
		"HOST_W_REQ",
		"HOST_R_REQ",
		"DM_OFF",
		"DM_ON",
		"DM_MIDI_MSG",
		"HOST_R_SET1",
		"TMQ_LWM",
		"HM_DONE",
		"MAIN_DONE",
		"PEEK0",
		"PEEK1",
		"IDLE",
		"NOT_IN_USE",
		"IAA",
		"PC",
		"SSH",
		"SR",
		"LC",
		"SP",
		"TIME0",
		"TIME1",
		"TIME2",
		"STATUS0",
		"STATUS1",
		"STATUS2",
		"HMS_ROOM",
		"TMQ_ROOM",
		"SSI_WDU",
		"HM_FIRST",
		"HM_LAST",
		"USER_MSG",
		"LONG0",
		"LONG1",
		"LONG2"};
#endif
