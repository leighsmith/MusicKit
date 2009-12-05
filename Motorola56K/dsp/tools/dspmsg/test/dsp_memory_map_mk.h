#ifndef __MK_dsp_memory_map_mk_H___
#define __MK_dsp_memory_map_mk_H___
/* dsp_memory_map_mk.h - written by dspmsg from system symbols.

This include file contains definitions for Music Kit memory addresses.
These definitions depend heavily on /usr/lib/dsp/smsrc/config.asm, and they
tend to change every time the DSP system code is modified.  Use of
these constants should be avoided whenever possible in C software.  At the 
very least, their use should be confined to a single interface module.

Address names are of the form 

		DSPMK_{X,Y,P,L}{L,H}{I,E}_{USR,SYS}

where {X,Y,P,L} are the possible memory spaces in the DSP, {L,H} specifies 
lower or higher memory segment boundary, {I,E} specifies internal or 
external memory, and {USR,SYS} specifies user or system memory segments. 
For example, PHE_USR specifies the maximum address available to the user 
in external program memory.  In general, the system occupies the lowest and 
highest address range in each space, with the user having all addresses in 
between.

Names of the form 'DSPMK_I_<name>' denote integer constants.
Names of the form 'DSPMK_NB_<name>' denote buffer sizes.
Names of the form 'DSPMK_N{X,Y,L,P}{I,E}_{USR,SYS}' denote memory segment sizes.

*/ 

/***** GLOBAL SYMBOLS *****/
#define DSPMK_HE_USR	 0x00310b
#define DSPMK_I_0DBU16	 0x003187
#define DSPMK_I_0DBU24	 0x031999
#define DSPMK_I_DEFIPR	 0x00243c
#define DSPMK_I_DEFOMR	 0x000006
#define DSPMK_I_EPS	 0x000001
#define DSPMK_I_M12DBU16	 0x000c66
#define DSPMK_I_M12DBU24	 0x0c6666
#define DSPMK_I_MAXPOS	 0x7fffff
#define DSPMK_I_MINPOS	 0x000001
#define DSPMK_I_NTICK	 0x000010
#define DSPMK_I_ONEHALF	 0x400000
#define DSPMK_I_OUTY	 0x00ffff
#define DSPMK_LE_USR	 0x002000
#define DSPMK_LHE_SEG	 0x00afff
#define DSPMK_LHE_SYS	 0x003f37
#define DSPMK_LHE_USG	 0x00a10b
#define DSPMK_LHE_USR	 0x00310b
#define DSPMK_LHI_SYS	 0x000003
#define DSPMK_LHI_USR	 0x0000ff
#define DSPMK_LLE_SEG	 0x00a000
#define DSPMK_LLE_SYS	 0x003f38
#define DSPMK_LLE_USG	 0x00a000
#define DSPMK_LLE_USR	 0x00310c
#define DSPMK_LLI_SYS	 0x000000
#define DSPMK_LLI_USR	 0x0000f6
#define DSPMK_NAE_SYS	 0x000ef4
#define DSPMK_NB_DMA	 0x000400
#define DSPMK_NB_DMA_R	 0x000000
#define DSPMK_NB_DMA_W	 0x000400
#define DSPMK_NB_DMQ	 0x000020
#define DSPMK_NB_HMS	 0x000040
#define DSPMK_NB_TMQ	 0x000338
#define DSPMK_NE_USR	 0x00110c
#define DSPMK_NLE_SEG	 0x001000
#define DSPMK_NLE_SYS	 0x000000
#define DSPMK_NLE_USG	 0x00010c
#define DSPMK_NLE_USR	 0x000000
#define DSPMK_NLI_SYS	 0x000004
#define DSPMK_NLI_USR	 0x00000a
#define DSPMK_NPE_SEG	 0x002000
#define DSPMK_NPE_SYS	 0x000640
#define DSPMK_NPE_SYSEP	 0x0000c8
#define DSPMK_NPE_USG	 0x000200
#define DSPMK_NPE_USR	 0x000200
#define DSPMK_NPI_RAM	 0x000200
#define DSPMK_NPI_ROM	 0x000000
#define DSPMK_NPI_SYS	 0x000000
#define DSPMK_NPI_USR	 0x000180
#define DSPMK_NXE_SEG	 0x001000
#define DSPMK_NXE_SYS	 0x000054
#define DSPMK_NXE_USG	 0x00010c
#define DSPMK_NXE_USR	 0x000f0c
#define DSPMK_NXI_RAM	 0x000100
#define DSPMK_NXI_ROM	 0x000100
#define DSPMK_NXI_SYS	 0x000000
#define DSPMK_NXI_USR	 0x0000f2
#define DSPMK_NYE_SEG	 0x001000
#define DSPMK_NYE_SYS	 0x000798
#define DSPMK_NYE_USG	 0x001000
#define DSPMK_NYE_USR	 0x000000
#define DSPMK_NYI_RAM	 0x000100
#define DSPMK_NYI_ROM	 0x000100
#define DSPMK_NYI_SYS	 0x000000
#define DSPMK_NYI_USR	 0x0000f2
#define DSPMK_PHE_RAM	 0x003fff
#define DSPMK_PHE_SEG	 0x00bfff
#define DSPMK_PHE_SYS	 0x00374b
#define DSPMK_PHE_SYSEP	 0x003fff
#define DSPMK_PHE_USG	 0x00a1ff
#define DSPMK_PHE_USR	 0x0021ff
#define DSPMK_PHI_RAM	 0x0001ff
#define DSPMK_PHI_ROM	 0x0001ff
#define DSPMK_PHI_SYS	 0x00007f
#define DSPMK_PHI_USR	 0x0001ff
#define DSPMK_PLE_RAM	 0x002000
#define DSPMK_PLE_SEG	 0x00a000
#define DSPMK_PLE_SYS	 0x00310c
#define DSPMK_PLE_SYSEP	 0x003f38
#define DSPMK_PLE_USG	 0x00a000
#define DSPMK_PLE_USR	 0x002000
#define DSPMK_PLI_RAM	 0x000000
#define DSPMK_PLI_ROM	 0x000200
#define DSPMK_PLI_SYS	 0x000080
#define DSPMK_PLI_USR	 0x000080
#define DSPMK_XHE_RAM	 0x003fff
#define DSPMK_XHE_SEG	 0x00afff
#define DSPMK_XHE_SYS	 0x00379f
#define DSPMK_XHE_USG	 0x00a10b
#define DSPMK_XHE_USR	 0x00310b
#define DSPMK_XHI_RAM	 0x0000ff
#define DSPMK_XHI_ROM	 0x0001ff
#define DSPMK_XHI_SYS	 0x000003
#define DSPMK_XHI_USR	 0x0000f5
#define DSPMK_XLE_RAM	 0x002000
#define DSPMK_XLE_SEG	 0x00a000
#define DSPMK_XLE_SYS	 0x00374c
#define DSPMK_XLE_USG	 0x00a000
#define DSPMK_XLE_USR	 0x002200
#define DSPMK_XLI_RAM	 0x000000
#define DSPMK_XLI_ROM	 0x000100
#define DSPMK_XLI_SYS	 0x000000
#define DSPMK_XLI_USR	 0x000004
#define DSPMK_YHE_RAM	 0x003fff
#define DSPMK_YHE_SEG	 0x00afff
#define DSPMK_YHE_SYS	 0x003f37
#define DSPMK_YHE_USG	 0x00afff
#define DSPMK_YHE_USR	 0x00310b
#define DSPMK_YHI_RAM	 0x0000ff
#define DSPMK_YHI_ROM	 0x0001ff
#define DSPMK_YHI_SYS	 0x000003
#define DSPMK_YHI_USR	 0x0000f5
#define DSPMK_YLE_RAM	 0x002000
#define DSPMK_YLE_SEG	 0x00a000
#define DSPMK_YLE_SYS	 0x0037a0
#define DSPMK_YLE_USG	 0x00a000
#define DSPMK_YLE_USR	 0x00310c
#define DSPMK_YLI_RAM	 0x000000
#define DSPMK_YLI_ROM	 0x000100
#define DSPMK_YLI_SYS	 0x000000
#define DSPMK_YLI_USR	 0x000004
#define DSPMK_NPE_SYSEP_FREE	 0x0008f2
#define DSPMK_SYS_REV	 0x000009
#define DSPMK_SYS_VER	 0x000000

/***** X SYMBOLS *****/
#define DSPMK_X_DMASTAT	 0x000001
#define DSPMK_X_DMA_REB	 0x00379d
#define DSPMK_X_DMA_REN	 0x00379e
#define DSPMK_X_DMA_REP	 0x00379f
#define DSPMK_X_DMA_RFB	 0x00379b
#define DSPMK_X_DMA_R_M	 0x003758
#define DSPMK_X_DMA_WEB	 0x00379a
#define DSPMK_X_DMA_WFB	 0x003797
#define DSPMK_X_DMA_WFN	 0x003799
#define DSPMK_X_DMA_WFP	 0x003798
#define DSPMK_X_DMA_W_M	 0x003759
#define DSPMK_X_DMQRP	 0x003774
#define DSPMK_X_DMQWP	 0x003775
#define DSPMK_X_DSPMSG_A1	 0x003754
#define DSPMK_X_DSPMSG_B0	 0x003753
#define DSPMK_X_DSPMSG_B1	 0x003752
#define DSPMK_X_DSPMSG_B2	 0x003751
#define DSPMK_X_DSPMSG_M_O	 0x003756
#define DSPMK_X_DSPMSG_R_O	 0x003755
#define DSPMK_X_DSPMSG_X0	 0x003750
#define DSPMK_X_DSPMSG_X1	 0x00374f
#define DSPMK_X_HMSRP	 0x00374d
#define DSPMK_X_HMSWP	 0x00374e
#define DSPMK_X_IRQB_SAVED_A0	 0x00378b
#define DSPMK_X_MIDI_MSG	 0x00377c
#define DSPMK_X_NCHANS	 0x00377a
#define DSPMK_X_NCLIP	 0x00377b
#define DSPMK_X_SAVED_A0	 0x003769
#define DSPMK_X_SAVED_A1	 0x003768
#define DSPMK_X_SAVED_A2	 0x003767
#define DSPMK_X_SAVED_B0	 0x00376c
#define DSPMK_X_SAVED_B1	 0x00376b
#define DSPMK_X_SAVED_B2	 0x00376a
#define DSPMK_X_SAVED_HOST_RCV1	 0x00376d
#define DSPMK_X_SAVED_HOST_RCV2	 0x00376e
#define DSPMK_X_SAVED_HOST_XMT1	 0x00376f
#define DSPMK_X_SAVED_HOST_XMT2	 0x003770
#define DSPMK_X_SAVED_M_HMS	 0x003773
#define DSPMK_X_SAVED_M_I1	 0x003760
#define DSPMK_X_SAVED_M_I2	 0x003761
#define DSPMK_X_SAVED_M_O	 0x003762
#define DSPMK_X_SAVED_N_HMS	 0x003772
#define DSPMK_X_SAVED_N_I1	 0x00375d
#define DSPMK_X_SAVED_N_I2	 0x00375e
#define DSPMK_X_SAVED_N_O	 0x00375f
#define DSPMK_X_SAVED_REGISTERS	 0x00375a
#define DSPMK_X_SAVED_R_HMS	 0x003771
#define DSPMK_X_SAVED_R_I1	 0x00375a
#define DSPMK_X_SAVED_R_I1_HMLIB	 0x003779
#define DSPMK_X_SAVED_R_I2	 0x00375b
#define DSPMK_X_SAVED_R_O	 0x00375c
#define DSPMK_X_SAVED_SR	 0x003778
#define DSPMK_X_SAVED_X0	 0x003764
#define DSPMK_X_SAVED_X1	 0x003763
#define DSPMK_X_SAVED_Y0	 0x003766
#define DSPMK_X_SAVED_Y1	 0x003765
#define DSPMK_X_SCI_COUNT	 0x00377d
#define DSPMK_X_SCRATCH1	 0x003776
#define DSPMK_X_SCRATCH2	 0x003777
#define DSPMK_X_SCRATCH3	 0x003794
#define DSPMK_X_SCRATCH4	 0x003795
#define DSPMK_X_SCRATCH5	 0x003796
#define DSPMK_X_SSIRP	 0x003780
#define DSPMK_X_SSIWP	 0x003781
#define DSPMK_X_SSI_PHASE	 0x003789
#define DSPMK_X_SSI_RFP	 0x00379c
#define DSPMK_X_SSI_SAVED_A0	 0x003784
#define DSPMK_X_SSI_SAVED_A1	 0x003785
#define DSPMK_X_SSI_SAVED_A2	 0x003786
#define DSPMK_X_SSI_SAVED_M_I1	 0x003783
#define DSPMK_X_SSI_SAVED_R_I1	 0x003782
#define DSPMK_X_SSI_SAVED_X0	 0x003787
#define DSPMK_X_SSI_SAVED_X1	 0x003788
#define DSPMK_X_START	 0x00374c
#define DSPMK_X_STDERR_A0	 0x003791
#define DSPMK_X_STDERR_A1	 0x003790
#define DSPMK_X_STDERR_A2	 0x00378f
#define DSPMK_X_STDERR_B0	 0x003793
#define DSPMK_X_STDERR_B1	 0x003792
#define DSPMK_X_STDERR_X0	 0x00378c
#define DSPMK_X_STDERR_Y0	 0x00378e
#define DSPMK_X_STDERR_Y1	 0x00378d
#define DSPMK_X_SWI_SAVED_A0	 0x00378a
#define DSPMK_X_TICK	 0x000002
#define DSPMK_X_TMQRP	 0x00377e
#define DSPMK_X_TMQWP	 0x00377f
#define DSPMK_X_XHM_R_I1	 0x003757
#define DSPMK_X_ZERO	 0x000000

/***** Y SYMBOLS *****/
#define DSPMK_YB_DMA_W	 0x003800
#define DSPMK_YB_DMA_W0	 0x003800
#define DSPMK_YB_DMA_W2	 0x003a00
#define DSPMK_YB_DMQ	 0x0037a0
#define DSPMK_YB_DMQ0	 0x0037a0
#define DSPMK_YB_HMS	 0x0037c0
#define DSPMK_YB_HMS0	 0x0037c0
#define DSPMK_YB_TMQ	 0x003c00
#define DSPMK_YB_TMQ0	 0x003c00
#define DSPMK_YB_TMQ2	 0x003d9c
#define DSPMK_Y_RUNSTAT	 0x000001
#define DSPMK_Y_TICK	 0x000002
#define DSPMK_Y_TINC	 0x000003
#define DSPMK_Y_ZERO	 0x000000

/***** L SYMBOLS *****/
#define DSPMK_L_STATUS	 0x000001
#define DSPMK_L_TICK	 0x000002
#define DSPMK_L_TINC	 0x000003
#define DSPMK_L_ZERO	 0x000000
#endif
