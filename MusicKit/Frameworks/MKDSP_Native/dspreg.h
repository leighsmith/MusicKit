#ifndef __MK_dspreg_H___
#define __MK_dspreg_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */

/* structure view of dsp registers */
struct dsp_regs {
	unsigned char	icr;
#define ICR_INIT	0x80
#define ICR_HM1		0x40
#define ICR_HM0		0x20
#define ICR_HF1		0x10
#define ICR_HF0		0x08
#define	ICR_TREQ	0x02
#define	ICR_RREQ	0x01
	unsigned char	cvr;
#define CVR_HC		0x80
#define	CVR_HV		0x1f
	unsigned char	isr;
#define ISR_HREQ	0x80
#define ISR_DMA		0x40
#define ISR_HF3		0x10
#define ISR_HF2		0x08
#define	ISR_TRDY	0x04
#define ISR_TXDE	0x02
#define ISR_RXDF	0x01
	unsigned char	ivr;
	union {
		unsigned int	receive_i;
		struct {
			unsigned char	pad;
			unsigned char	h;
			unsigned char	m;
			unsigned char	l;
		} receive_struct;
		struct {
			unsigned short	pad;
			unsigned short	s;
		} receive_s;
		unsigned int	transmit_i;
		struct {
			unsigned char	pad;
			unsigned char	h;
			unsigned char	m;
			unsigned char	l;
		} transmit_struct;
		struct {
			unsigned short pad;
			unsigned short s;
		} transmit_s;
	} data;
};

#endif
