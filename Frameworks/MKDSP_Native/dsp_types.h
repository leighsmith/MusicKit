#ifndef __MK_dsp_types_H___
#define __MK_dsp_types_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Numeric typedefs */
typedef int DSPMuLaw;
typedef int DSPFix8;
typedef int DSPFix16;
typedef int DSPFix24;
typedef struct _DSPFix48 {
    int high24;		      /* High order 24 bits, right justified */
    int low24;		      /* Low order 24 bits, right justified */
} DSPFix48;

typedef DSPFix16 DSPAddress;
typedef DSPFix24 DSPDatum;
typedef DSPFix48 DSPLongDatum;
typedef DSPFix48 DSPTimeStamp;

typedef int DSP_BOOL;
#define DSP_TRUE 1
#define DSP_FALSE 0
#define DSP_NOT_SET 2
#define DSP_MAYBE (-2)		/* TRUE and FALSE defined in nextstd.h */
#define DSP_UNKNOWN (-1)	/* like DSP_{MAYBE,NOT_SET} for adresses */

#endif
