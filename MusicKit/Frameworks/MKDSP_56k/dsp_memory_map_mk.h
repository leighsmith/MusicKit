#ifndef __MK_dsp_memory_map_mk_H___
#define __MK_dsp_memory_map_mk_H___
/* $Id$
1.0 compatibility include file

The "DSPMK_" defined constants here have been replaced by the more generic
"DSP_" defines.  Instead of importing this file, you should change your
source code, replacing "DSPMK_" by "DSP_".  Import this file, if you must,
after first importing dsp_memory_map.h (which is imported by dsp.h).

Note that the definitions are not valid until after you have booted the DSP
(or at least called DSPSetSystem).  If you must have the constants before
booting, you can use the old 1.0 version of this file,
dsp_memory_map_ap_1.0.h, but then your code will be compiled only for 8K
words of DSP static RAM.

------------------------------------------------------------------------------

This include file contains definitions for Music Kit DSP Monitor
memory addresses.  Address names are of the form 

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
#define DSPMK_DEGMON_FLAG DSP_DEGMON_FLAG
#define DSPMK_DEGMON_FLAG2 DSP_DEGMON_FLAG2
#define DSPMK_DEGMON_H DSP_DEGMON_H
#define DSPMK_DEGMON_HCR DSP_DEGMON_HCR
#define DSPMK_DEGMON_HPD2 DSP_DEGMON_HPD2
#define DSPMK_DEGMON_IPR DSP_DEGMON_IPR
#define DSPMK_DEGMON_L DSP_DEGMON_L
#define DSPMK_DEGMON_N DSP_DEGMON_N
#define DSPMK_DEGMON_PC DSP_DEGMON_PC
#define DSPMK_DEGMON_RUN_LOC DSP_DEGMON_RUN_LOC
#define DSPMK_DEGMON_SR DSP_DEGMON_SR
#define DSPMK_DEGMON_SR2 DSP_DEGMON_SR2
#define DSPMK_DEGMON_TRACER_LOC DSP_DEGMON_TRACER_LOC
#define DSPMK_HE_USR DSP_HE_USR
#define DSPMK_I_0DBU16 DSP_I_0DBU16
#define DSPMK_I_0DBU24 DSP_I_0DBU24
#define DSPMK_I_DEFIPR DSP_I_DEFIPR
#define DSPMK_I_DEFOMR DSP_I_DEFOMR
#define DSPMK_I_EPS DSP_I_EPS
#define DSPMK_I_M12DBU16 DSP_I_M12DBU16
#define DSPMK_I_M12DBU24 DSP_I_M12DBU24
#define DSPMK_I_MAXPOS DSP_I_MAXPOS
#define DSPMK_I_MINPOS DSP_I_MINPOS
#define DSPMK_I_NTICK DSP_I_NTICK
#define DSPMK_I_ONEHALF DSP_I_ONEHALF
#define DSPMK_I_OUTY DSP_I_OUTY
#define DSPMK_LE_USR DSP_LE_USR
#define DSPMK_LHE_SEG DSP_LHE_SEG
#define DSPMK_LHE_SYS DSP_LHE_SYS
#define DSPMK_LHE_USG DSP_LHE_USG
#define DSPMK_LHE_USR DSP_LHE_USR
#define DSPMK_LHI_SYS DSP_LHI_SYS
#define DSPMK_LHI_USR DSP_LHI_USR
#define DSPMK_LLE_SEG DSP_LLE_SEG
#define DSPMK_LLE_SYS DSP_LLE_SYS
#define DSPMK_LLE_USG DSP_LLE_USG
#define DSPMK_LLE_USR DSP_LLE_USR
#define DSPMK_LLI_SYS DSP_LLI_SYS
#define DSPMK_LLI_USR DSP_LLI_USR
#define DSPMK_NAE_SYS DSP_NAE_SYS
#define DSPMK_NB_DMA DSP_NB_DMA
#define DSPMK_NB_DMA_R DSP_NB_DMA_R
#define DSPMK_NB_DMA_W DSP_NB_DMA_W
#define DSPMK_NB_DMQ DSP_NB_DMQ
#define DSPMK_NB_HMS DSP_NB_HMS
#define DSPMK_NB_TMQ DSP_NB_TMQ
#define DSPMK_NE_USR DSP_NE_USR
#define DSPMK_NLE_SEG DSP_NLE_SEG
#define DSPMK_NLE_SYS DSP_NLE_SYS
#define DSPMK_NLE_USG DSP_NLE_USG
#define DSPMK_NLE_USR DSP_NLE_USR
#define DSPMK_NLI_SYS DSP_NLI_SYS
#define DSPMK_NLI_USR DSP_NLI_USR
#define DSPMK_NPE_SEG DSP_NPE_SEG
#define DSPMK_NPE_SYS DSP_NPE_SYS
#define DSPMK_NPE_SYSEP DSP_NPE_SYSEP
#define DSPMK_NPE_USG DSP_NPE_USG
#define DSPMK_NPE_USR DSP_NPE_USR
#define DSPMK_NPI_RAM DSP_NPI_RAM
#define DSPMK_NPI_ROM DSP_NPI_ROM
#define DSPMK_NPI_SYS DSP_NPI_SYS
#define DSPMK_NPI_USR DSP_NPI_USR
#define DSPMK_NXE_SEG DSP_NXE_SEG
#define DSPMK_NXE_SYS DSP_NXE_SYS
#define DSPMK_NXE_USG DSP_NXE_USG
#define DSPMK_NXE_USR DSP_NXE_USR
#define DSPMK_NXI_RAM DSP_NXI_RAM
#define DSPMK_NXI_ROM DSP_NXI_ROM
#define DSPMK_NXI_SYS DSP_NXI_SYS
#define DSPMK_NXI_USR DSP_NXI_USR
#define DSPMK_NYE_SEG DSP_NYE_SEG
#define DSPMK_NYE_SYS DSP_NYE_SYS
#define DSPMK_NYE_USG DSP_NYE_USG
#define DSPMK_NYE_USR DSP_NYE_USR
#define DSPMK_NYI_RAM DSP_NYI_RAM
#define DSPMK_NYI_ROM DSP_NYI_ROM
#define DSPMK_NYI_SYS DSP_NYI_SYS
#define DSPMK_NYI_USR DSP_NYI_USR
#define DSPMK_PHE_RAM DSP_PHE_RAM
#define DSPMK_PHE_SEG DSP_PHE_SEG
#define DSPMK_PHE_SYS DSP_PHE_SYS
#define DSPMK_PHE_SYSEP DSP_PHE_SYSEP
#define DSPMK_PHE_USG DSP_PHE_USG
#define DSPMK_PHE_USR DSP_PHE_USR
#define DSPMK_PHI_RAM DSP_PHI_RAM
#define DSPMK_PHI_ROM DSP_PHI_ROM
#define DSPMK_PHI_SYS DSP_PHI_SYS
#define DSPMK_PHI_USR DSP_PHI_USR
#define DSPMK_PLE_RAM DSP_PLE_RAM
#define DSPMK_PLE_SEG DSP_PLE_SEG
#define DSPMK_PLE_SYS DSP_PLE_SYS
#define DSPMK_PLE_SYSEP DSP_PLE_SYSEP
#define DSPMK_PLE_USG DSP_PLE_USG
#define DSPMK_PLE_USR DSP_PLE_USR
#define DSPMK_PLI_RAM DSP_PLI_RAM
#define DSPMK_PLI_ROM DSP_PLI_ROM
#define DSPMK_PLI_SYS DSP_PLI_SYS
#define DSPMK_PLI_USR DSP_PLI_USR
#define DSPMK_XHE_RAM DSP_XHE_RAM
#define DSPMK_XHE_SEG DSP_XHE_SEG
#define DSPMK_XHE_SYS DSP_XHE_SYS
#define DSPMK_XHE_USG DSP_XHE_USG
#define DSPMK_XHE_USR DSP_XHE_USR
#define DSPMK_XHI_RAM DSP_XHI_RAM
#define DSPMK_XHI_ROM DSP_XHI_ROM
#define DSPMK_XHI_SYS DSP_XHI_SYS
#define DSPMK_XHI_USR DSP_XHI_USR
#define DSPMK_XLE_RAM DSP_XLE_RAM
#define DSPMK_XLE_SEG DSP_XLE_SEG
#define DSPMK_XLE_SYS DSP_XLE_SYS
#define DSPMK_XLE_USG DSP_XLE_USG
#define DSPMK_XLE_USR DSP_XLE_USR
#define DSPMK_XLI_RAM DSP_XLI_RAM
#define DSPMK_XLI_ROM DSP_XLI_ROM
#define DSPMK_XLI_SYS DSP_XLI_SYS
#define DSPMK_XLI_USR DSP_XLI_USR
#define DSPMK_YHE_RAM DSP_YHE_RAM
#define DSPMK_YHE_SEG DSP_YHE_SEG
#define DSPMK_YHE_SYS DSP_YHE_SYS
#define DSPMK_YHE_USG DSP_YHE_USG
#define DSPMK_YHE_USR DSP_YHE_USR
#define DSPMK_YHI_RAM DSP_YHI_RAM
#define DSPMK_YHI_ROM DSP_YHI_ROM
#define DSPMK_YHI_SYS DSP_YHI_SYS
#define DSPMK_YHI_USR DSP_YHI_USR
#define DSPMK_YLE_RAM DSP_YLE_RAM
#define DSPMK_YLE_SEG DSP_YLE_SEG
#define DSPMK_YLE_SYS DSP_YLE_SYS
#define DSPMK_YLE_USG DSP_YLE_USG
#define DSPMK_YLE_USR DSP_YLE_USR
#define DSPMK_YLI_RAM DSP_YLI_RAM
#define DSPMK_YLI_ROM DSP_YLI_ROM
#define DSPMK_YLI_SYS DSP_YLI_SYS
#define DSPMK_YLI_USR DSP_YLI_USR
#define DSPMK_NPE_SYSEP_FREE DSP_NPE_SYSEP_FREE
#define DSPMK_SYS_REV DSP_SYS_REV
#define DSPMK_SYS_VER DSP_SYS_VER

/***** X SYMBOLS *****/
#define DSPMK_X_ABORT_A1 DSP_X_ABORT_A1
#define DSPMK_X_ABORT_DMASTAT DSP_X_ABORT_DMASTAT
#define DSPMK_X_ABORT_HCR DSP_X_ABORT_HCR
#define DSPMK_X_ABORT_HSR DSP_X_ABORT_HSR
#define DSPMK_X_ABORT_M_IO DSP_X_ABORT_M_IO
#define DSPMK_X_ABORT_RUNSTAT DSP_X_ABORT_RUNSTAT
#define DSPMK_X_ABORT_R_HMS DSP_X_ABORT_R_HMS
#define DSPMK_X_ABORT_R_I1 DSP_X_ABORT_R_I1
#define DSPMK_X_ABORT_R_IO DSP_X_ABORT_R_IO
#define DSPMK_X_ABORT_SP DSP_X_ABORT_SP
#define DSPMK_X_ABORT_SR DSP_X_ABORT_SR
#define DSPMK_X_ABORT_X0 DSP_X_ABORT_X0
#define DSPMK_X_DMASTAT DSP_X_DMASTAT
#define DSPMK_X_DMA_REB DSP_X_DMA_REB
#define DSPMK_X_DMA_REN DSP_X_DMA_REN
#define DSPMK_X_DMA_REP DSP_X_DMA_REP
#define DSPMK_X_DMA_RFB DSP_X_DMA_RFB
#define DSPMK_X_DMA_R_M DSP_X_DMA_R_M
#define DSPMK_X_DMA_WEB DSP_X_DMA_WEB
#define DSPMK_X_DMA_WFB DSP_X_DMA_WFB
#define DSPMK_X_DMA_WFN DSP_X_DMA_WFN
#define DSPMK_X_DMA_WFP DSP_X_DMA_WFP
#define DSPMK_X_DMA_W_M DSP_X_DMA_W_M
#define DSPMK_X_DMQRP DSP_X_DMQRP
#define DSPMK_X_DMQWP DSP_X_DMQWP
#define DSPMK_X_DSPMSG_A1 DSP_X_DSPMSG_A1
#define DSPMK_X_DSPMSG_B0 DSP_X_DSPMSG_B0
#define DSPMK_X_DSPMSG_B1 DSP_X_DSPMSG_B1
#define DSPMK_X_DSPMSG_B2 DSP_X_DSPMSG_B2
#define DSPMK_X_DSPMSG_M_O DSP_X_DSPMSG_M_O
#define DSPMK_X_DSPMSG_R_O DSP_X_DSPMSG_R_O
#define DSPMK_X_DSPMSG_X0 DSP_X_DSPMSG_X0
#define DSPMK_X_DSPMSG_X1 DSP_X_DSPMSG_X1
#define DSPMK_X_HMSRP DSP_X_HMSRP
#define DSPMK_X_HMSWP DSP_X_HMSWP
#define DSPMK_X_MIDI_MSG DSP_X_MIDI_MSG
#define DSPMK_X_NCHANS DSP_X_NCHANS
#define DSPMK_X_NCLIP DSP_X_NCLIP
#define DSPMK_X_SAVED_A0 DSP_X_SAVED_A0
#define DSPMK_X_SAVED_A1 DSP_X_SAVED_A1
#define DSPMK_X_SAVED_A2 DSP_X_SAVED_A2
#define DSPMK_X_SAVED_B0 DSP_X_SAVED_B0
#define DSPMK_X_SAVED_B1 DSP_X_SAVED_B1
#define DSPMK_X_SAVED_B2 DSP_X_SAVED_B2
#define DSPMK_X_SAVED_HOST_RCV1 DSP_X_SAVED_HOST_RCV1
#define DSPMK_X_SAVED_HOST_RCV2 DSP_X_SAVED_HOST_RCV2
#define DSPMK_X_SAVED_HOST_XMT1 DSP_X_SAVED_HOST_XMT1
#define DSPMK_X_SAVED_HOST_XMT2 DSP_X_SAVED_HOST_XMT2
#define DSPMK_X_SAVED_M_HMS DSP_X_SAVED_M_HMS
#define DSPMK_X_SAVED_M_I1 DSP_X_SAVED_M_I1
#define DSPMK_X_SAVED_M_I2 DSP_X_SAVED_M_I2
#define DSPMK_X_SAVED_M_O DSP_X_SAVED_M_O
#define DSPMK_X_SAVED_N_HMS DSP_X_SAVED_N_HMS
#define DSPMK_X_SAVED_N_I1 DSP_X_SAVED_N_I1
#define DSPMK_X_SAVED_N_I2 DSP_X_SAVED_N_I2
#define DSPMK_X_SAVED_N_O DSP_X_SAVED_N_O
#define DSPMK_X_SAVED_REGISTERS DSP_X_SAVED_REGISTERS
#define DSPMK_X_SAVED_R_HMS DSP_X_SAVED_R_HMS
#define DSPMK_X_SAVED_R_I1 DSP_X_SAVED_R_I1
#define DSPMK_X_SAVED_R_I1_HMLIB DSP_X_SAVED_R_I1_HMLIB
#define DSPMK_X_SAVED_R_I2 DSP_X_SAVED_R_I2
#define DSPMK_X_SAVED_R_O DSP_X_SAVED_R_O
#define DSPMK_X_SAVED_SR DSP_X_SAVED_SR
#define DSPMK_X_SAVED_X0 DSP_X_SAVED_X0
#define DSPMK_X_SAVED_X1 DSP_X_SAVED_X1
#define DSPMK_X_SAVED_Y0 DSP_X_SAVED_Y0
#define DSPMK_X_SAVED_Y1 DSP_X_SAVED_Y1
#define DSPMK_X_SCI_COUNT DSP_X_SCI_COUNT
#define DSPMK_X_SCRATCH1 DSP_X_SCRATCH1
#define DSPMK_X_SCRATCH2 DSP_X_SCRATCH2
#define DSPMK_X_SSIRP DSP_X_SSIRP
#define DSPMK_X_SSIWP DSP_X_SSIWP
#define DSPMK_X_SSI_PHASE DSP_X_SSI_PHASE
#define DSPMK_X_SSI_RFP DSP_X_SSI_RFP
#define DSPMK_X_SSI_SAVED_A0 DSP_X_SSI_SAVED_A0
#define DSPMK_X_SSI_SAVED_A1 DSP_X_SSI_SAVED_A1
#define DSPMK_X_SSI_SAVED_A2 DSP_X_SSI_SAVED_A2
#define DSPMK_X_SSI_SAVED_M_I1 DSP_X_SSI_SAVED_M_I1
#define DSPMK_X_SSI_SAVED_R_I1 DSP_X_SSI_SAVED_R_I1
#define DSPMK_X_SSI_SAVED_X0 DSP_X_SSI_SAVED_X0
#define DSPMK_X_SSI_SAVED_X1 DSP_X_SSI_SAVED_X1
#define DSPMK_X_START DSP_X_START
#define DSPMK_X_TICK DSP_X_TICK
#define DSPMK_X_TMQRP DSP_X_TMQRP
#define DSPMK_X_TMQWP DSP_X_TMQWP
#define DSPMK_X_XHM_R_I1 DSP_X_XHM_R_I1
#define DSPMK_X_ZERO DSP_X_ZERO

/***** Y SYMBOLS *****/
#define DSPMK_YB_DMA_W DSP_YB_DMA_W
#define DSPMK_YB_DMA_W0 DSP_YB_DMA_W0
#define DSPMK_YB_DMA_W2 DSP_YB_DMA_W2
#define DSPMK_YB_DMQ DSP_YB_DMQ
#define DSPMK_YB_DMQ0 DSP_YB_DMQ0
#define DSPMK_YB_HMS DSP_YB_HMS
#define DSPMK_YB_HMS0 DSP_YB_HMS0
#define DSPMK_YB_TMQ DSP_YB_TMQ
#define DSPMK_YB_TMQ0 DSP_YB_TMQ0
#define DSPMK_YB_TMQ2 DSP_YB_TMQ2
#define DSPMK_Y_RUNSTAT DSP_Y_RUNSTAT
#define DSPMK_Y_TICK DSP_Y_TICK
#define DSPMK_Y_TINC DSP_Y_TINC
#define DSPMK_Y_ZERO DSP_Y_ZERO

/***** L SYMBOLS *****/
#define DSPMK_L_STATUS DSP_L_STATUS
#define DSPMK_L_TICK DSP_L_TICK
#define DSPMK_L_TINC DSP_L_TINC
#define DSPMK_L_ZERO DSP_L_ZERO

#endif
