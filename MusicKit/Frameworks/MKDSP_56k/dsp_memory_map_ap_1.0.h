#ifndef __MK_dsp_memory_map_ap_1.0_H___
#define __MK_dsp_memory_map_ap_1.0_H___
/* $Id$
Written by dspmsg from system symbols.

This include file contains definitions for Array Processing memory
addresses.  These definitions depend heavily on
/usr/local/lib/dsp/smsrc/config.asm, and they tend to change every time the
DSP system code is modified.  Use of these constants should be avoided
whenever possible in C software.  At the very least, their use should be
confined to a single interface module.

Address names are of the form 

		DSPAP_{X,Y,P,L}{L,H}{I,E}_{USR,SYS}

where {X,Y,P,L} are the possible memory spaces in the DSP, {L,H} specifies 
lower or higher memory segment boundary, {I,E} specifies internal or 
external memory, and {USR,SYS} specifies user or system memory segments. 
For example, PHE_USR specifies the maximum address available to the user 
in external program memory.  In general, the system occupies the lowest and 
highest address range in each space, with the user having all addresses in 
between.

Names of the form 'DSPAP_I_<name>' denote integer constants.
Names of the form 'DSPAP_NB_<name>' denote buffer sizes.
Names of the form 'DSPAP_N{X,Y,L,P}{I,E}_{USR,SYS}' denote memory segment sizes.

*/ 

/***** GLOBAL SYMBOLS *****/
#define DSPAP_DEGMON_FLAG	 0x000035
#define DSPAP_DEGMON_FLAG2	 0x000037
#define DSPAP_DEGMON_H	 0x00007f
#define DSPAP_DEGMON_HCR	 0x00003b
#define DSPAP_DEGMON_HPD2	 0x000036
#define DSPAP_DEGMON_IPR	 0x00003a
#define DSPAP_DEGMON_L	 0x000034
#define DSPAP_DEGMON_N	 0x00004c
#define DSPAP_DEGMON_PC	 0x000039
#define DSPAP_DEGMON_RUN_LOC	 0x000047
#define DSPAP_DEGMON_SR	 0x000038
#define DSPAP_DEGMON_SR2	 0x00003c
#define DSPAP_DEGMON_TRACER_LOC	 0x000059
#define DSPAP_HE_USR	 0x003b15
#define DSPAP_I_0DBU16	 0x003187
#define DSPAP_I_0DBU24	 0x031999
#define DSPAP_I_DEFIPR	 0x00243c
#define DSPAP_I_DEFOMR	 0x000006
#define DSPAP_I_EPS	 0x000001
#define DSPAP_I_M12DBU16	 0x000c66
#define DSPAP_I_M12DBU24	 0x0c6666
#define DSPAP_I_MAXPOS	 0x7fffff
#define DSPAP_I_MINPOS	 0x000001
#define DSPAP_I_ONEHALF	 0x400000
#define DSPAP_I_OUTY	 0x00ffff
#define DSPAP_LE_USR	 0x002000
#define DSPAP_LHE_SEG	 0x00afff
#define DSPAP_LHE_SYS	 0x003f37
#define DSPAP_LHE_USG	 0x00ab15
#define DSPAP_LHE_USR	 0x003b15
#define DSPAP_LHI_SYS	 0x000001
#define DSPAP_LHI_USR	 0x0000ff
#define DSPAP_LLE_SEG	 0x00a000
#define DSPAP_LLE_SYS	 0x003f38
#define DSPAP_LLE_USG	 0x00a000
#define DSPAP_LLE_USR	 0x003b16
#define DSPAP_LLI_SYS	 0x000000
#define DSPAP_LLI_USR	 0x0000f6
#define DSPAP_NAE_SYS	 0x0004ea
#define DSPAP_NB_DMA	 0x000000
#define DSPAP_NB_DMA_R	 0x000000
#define DSPAP_NB_DMA_W	 0x000000
#define DSPAP_NB_DMQ	 0x000020
#define DSPAP_NB_HMS	 0x000040
#define DSPAP_NB_TMQ	 0x000038
#define DSPAP_NE_USR	 0x001b16
#define DSPAP_NLE_SEG	 0x001000
#define DSPAP_NLE_SYS	 0x000000
#define DSPAP_NLE_USG	 0x000b16
#define DSPAP_NLE_USR	 0x000000
#define DSPAP_NLI_SYS	 0x000002
#define DSPAP_NLI_USR	 0x00000a
#define DSPAP_NPE_SEG	 0x002000
#define DSPAP_NPE_SYS	 0x000352
#define DSPAP_NPE_SYSEP	 0x0000c8
#define DSPAP_NPE_USG	 0x000000
#define DSPAP_NPE_USR	 0x000000
#define DSPAP_NPI_RAM	 0x000200
#define DSPAP_NPI_ROM	 0x000000
#define DSPAP_NPI_SYS	 0x000000
#define DSPAP_NPI_USR	 0x000180
#define DSPAP_NXE_SEG	 0x001000
#define DSPAP_NXE_SYS	 0x000038
#define DSPAP_NXE_USG	 0x000b16
#define DSPAP_NXE_USR	 0x001b16
#define DSPAP_NXI_RAM	 0x000100
#define DSPAP_NXI_ROM	 0x000100
#define DSPAP_NXI_SYS	 0x000000
#define DSPAP_NXI_USR	 0x0000f4
#define DSPAP_NYE_SEG	 0x001000
#define DSPAP_NYE_SYS	 0x000098
#define DSPAP_NYE_USG	 0x001000
#define DSPAP_NYE_USR	 0x000000
#define DSPAP_NYI_RAM	 0x000100
#define DSPAP_NYI_ROM	 0x000100
#define DSPAP_NYI_SYS	 0x000000
#define DSPAP_NYI_USR	 0x0000f4
#define DSPAP_PHE_RAM	 0x003fff
#define DSPAP_PHE_SEG	 0x00bfff
#define DSPAP_PHE_SYS	 0x003e67
#define DSPAP_PHE_SYSEP	 0x003fff
#define DSPAP_PHE_USG	 0x009fff
#define DSPAP_PHE_USR	 0x001fff
#define DSPAP_PHI_RAM	 0x0001ff
#define DSPAP_PHI_ROM	 0x0001ff
#define DSPAP_PHI_SYS	 0x00007f
#define DSPAP_PHI_USR	 0x0001ff
#define DSPAP_PLE_RAM	 0x002000
#define DSPAP_PLE_SEG	 0x00a000
#define DSPAP_PLE_SYS	 0x003b16
#define DSPAP_PLE_SYSEP	 0x003f38
#define DSPAP_PLE_USG	 0x00a000
#define DSPAP_PLE_USR	 0x002000
#define DSPAP_PLI_RAM	 0x000000
#define DSPAP_PLI_ROM	 0x000200
#define DSPAP_PLI_SYS	 0x000080
#define DSPAP_PLI_USR	 0x000080
#define DSPAP_XHE_RAM	 0x003fff
#define DSPAP_XHE_SEG	 0x00afff
#define DSPAP_XHE_SYS	 0x003e9f
#define DSPAP_XHE_USG	 0x00ab15
#define DSPAP_XHE_USR	 0x003b15
#define DSPAP_XHI_RAM	 0x0000ff
#define DSPAP_XHI_ROM	 0x0001ff
#define DSPAP_XHI_SYS	 0x000001
#define DSPAP_XHI_USR	 0x0000f5
#define DSPAP_XLE_RAM	 0x002000
#define DSPAP_XLE_SEG	 0x00a000
#define DSPAP_XLE_SYS	 0x003e68
#define DSPAP_XLE_USG	 0x00a000
#define DSPAP_XLE_USR	 0x002000
#define DSPAP_XLI_RAM	 0x000000
#define DSPAP_XLI_ROM	 0x000100
#define DSPAP_XLI_SYS	 0x000000
#define DSPAP_XLI_USR	 0x000002
#define DSPAP_YHE_RAM	 0x003fff
#define DSPAP_YHE_SEG	 0x00afff
#define DSPAP_YHE_SYS	 0x003f37
#define DSPAP_YHE_USG	 0x00afff
#define DSPAP_YHE_USR	 0x003b15
#define DSPAP_YHI_RAM	 0x0000ff
#define DSPAP_YHI_ROM	 0x0001ff
#define DSPAP_YHI_SYS	 0x000001
#define DSPAP_YHI_USR	 0x0000f5
#define DSPAP_YLE_RAM	 0x002000
#define DSPAP_YLE_SEG	 0x00a000
#define DSPAP_YLE_SYS	 0x003ea0
#define DSPAP_YLE_USG	 0x00a000
#define DSPAP_YLE_USR	 0x003b16
#define DSPAP_YLI_RAM	 0x000000
#define DSPAP_YLI_ROM	 0x000100
#define DSPAP_YLI_SYS	 0x000000
#define DSPAP_YLI_USR	 0x000002
#define DSPAP_NPE_SYSEP_FREE	 0x0001a8
#define DSPAP_SYS_REV	 0x000011
#define DSPAP_SYS_VER	 0x000001

/***** X SYMBOLS *****/
#define DSPAP_X_ABORT_A1	 0x003e97
#define DSPAP_X_ABORT_DMASTAT	 0x003e95
#define DSPAP_X_ABORT_HCR	 0x003e9a
#define DSPAP_X_ABORT_HSR	 0x003e9b
#define DSPAP_X_ABORT_M_IO	 0x003e9f
#define DSPAP_X_ABORT_RUNSTAT	 0x003e94
#define DSPAP_X_ABORT_R_HMS	 0x003e9c
#define DSPAP_X_ABORT_R_I1	 0x003e9d
#define DSPAP_X_ABORT_R_IO	 0x003e9e
#define DSPAP_X_ABORT_SP	 0x003e98
#define DSPAP_X_ABORT_SR	 0x003e99
#define DSPAP_X_ABORT_X0	 0x003e96
#define DSPAP_X_DMASTAT	 0x000001
#define DSPAP_X_DMA_R_M	 0x003e74
#define DSPAP_X_DMA_W_M	 0x003e75
#define DSPAP_X_DMQRP	 0x003e90
#define DSPAP_X_DMQWP	 0x003e91
#define DSPAP_X_DSPMSG_A1	 0x003e70
#define DSPAP_X_DSPMSG_B0	 0x003e6f
#define DSPAP_X_DSPMSG_B1	 0x003e6e
#define DSPAP_X_DSPMSG_B2	 0x003e6d
#define DSPAP_X_DSPMSG_M_O	 0x003e72
#define DSPAP_X_DSPMSG_R_O	 0x003e71
#define DSPAP_X_DSPMSG_X0	 0x003e6c
#define DSPAP_X_DSPMSG_X1	 0x003e6b
#define DSPAP_X_HMSRP	 0x003e69
#define DSPAP_X_HMSWP	 0x003e6a
#define DSPAP_X_SAVED_A0	 0x003e85
#define DSPAP_X_SAVED_A1	 0x003e84
#define DSPAP_X_SAVED_A2	 0x003e83
#define DSPAP_X_SAVED_B0	 0x003e88
#define DSPAP_X_SAVED_B1	 0x003e87
#define DSPAP_X_SAVED_B2	 0x003e86
#define DSPAP_X_SAVED_HOST_RCV1	 0x003e89
#define DSPAP_X_SAVED_HOST_RCV2	 0x003e8a
#define DSPAP_X_SAVED_HOST_XMT1	 0x003e8b
#define DSPAP_X_SAVED_HOST_XMT2	 0x003e8c
#define DSPAP_X_SAVED_M_HMS	 0x003e8f
#define DSPAP_X_SAVED_M_I1	 0x003e7c
#define DSPAP_X_SAVED_M_I2	 0x003e7d
#define DSPAP_X_SAVED_M_O	 0x003e7e
#define DSPAP_X_SAVED_N_HMS	 0x003e8e
#define DSPAP_X_SAVED_N_I1	 0x003e79
#define DSPAP_X_SAVED_N_I2	 0x003e7a
#define DSPAP_X_SAVED_N_O	 0x003e7b
#define DSPAP_X_SAVED_REGISTERS	 0x003e76
#define DSPAP_X_SAVED_R_HMS	 0x003e8d
#define DSPAP_X_SAVED_R_I1	 0x003e76
#define DSPAP_X_SAVED_R_I2	 0x003e77
#define DSPAP_X_SAVED_R_O	 0x003e78
#define DSPAP_X_SAVED_X0	 0x003e80
#define DSPAP_X_SAVED_X1	 0x003e7f
#define DSPAP_X_SAVED_Y0	 0x003e82
#define DSPAP_X_SAVED_Y1	 0x003e81
#define DSPAP_X_SCRATCH1	 0x003e92
#define DSPAP_X_SCRATCH2	 0x003e93
#define DSPAP_X_START	 0x003e68
#define DSPAP_X_XHM_R_I1	 0x003e73
#define DSPAP_X_ZERO	 0x000000

/***** Y SYMBOLS *****/
#define DSPAP_YB_DMA_W	 0x003f00
#define DSPAP_YB_DMA_W0	 0x003f00
#define DSPAP_YB_DMA_W2	 0x003f00
#define DSPAP_YB_DMQ	 0x003ea0
#define DSPAP_YB_DMQ0	 0x003ea0
#define DSPAP_YB_HMS	 0x003ec0
#define DSPAP_YB_HMS0	 0x003ec0
#define DSPAP_YB_TMQ	 0x003f00
#define DSPAP_YB_TMQ0	 0x003f00
#define DSPAP_YB_TMQ2	 0x003f1c
#define DSPAP_Y_RUNSTAT	 0x000001
#define DSPAP_Y_ZERO	 0x000000

/***** L SYMBOLS *****/
#define DSPAP_L_STATUS	 0x000001
#define DSPAP_L_ZERO	 0x000000

#endif
