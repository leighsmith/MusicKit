/*
 * Serial channel register definitions.
 *
 * History
 * 22-May-91  Gregg Kellogg (gk) at NeXT
 *	Split out public interface.
 *
 * 04-Apr-90	Doug Mitchell at NeXT
 *	Added protogtype for zs_tc; made all of this file except for ioctl's
 *		dependent on ifdef KERNEL. 
 */

#ifndef	_MY_ZSREG_
#define _MY_ZSREG_

#import <sys/ioctl.h>
#import <sys/types.h>
#import	"zs85C30.h"

#ifdef	ARCH_PRIVATE

//#import <bsd/m68k/cpu.h>
//#import <bsd/machine/machparam.h>

#if	KERNEL || STANDALONE || MONITOR

// TODO - ALERT - hardwired address!! LMS
//#define P_SCC           0x01d8

//#define	ZSADDR_A	((volatile struct zsdevice *) (P_SCC + 1))
//#define	ZSADDR_B	((volatile struct zsdevice *) (P_SCC))

struct zsdevice {
	unsigned char	zs_ctrl;	/* control register */
	unsigned char : 8;
	unsigned char	zs_data;	/* data register */
};

/* SCC clock select register */
#define	SCC_RESET	0x80
#define	PCLK_10_MHZ	0x30
#define	PCLK_4_MHZ	0x10
#define	PCLK_313_ESCLK	0x10		/* dma 313 chip */
#define	PCLK_3684_MHZ	0x00
#define	SCLKB_ESCLK	0x0c
#define	SCLKB_4_MHZ	0x08
#define	SCLKB_10_MHZ	0x04
#define	SCLKB_313_ESCLK	0x04		/* dma 313 chip */
#define	SCLKB_3684_MHZ	0x00
#define	SCLKA_ESCLK	0x03
#define	SCLKA_4_MHZ	0x02
#define	SCLKA_10_MHZ	0x01
#define	SCLKA_313_ESCLK	0x01		/* dma 313 chip */
#define	SCLKA_3684_MHZ	0x00

/*
 * Clocks available to SCC
 */
#define	PCLK_NEW_HZ	10000000
#define	PCLK_HZ		 3684000
#define	RTXC_NEW_HZ	 3684000
#define	RTXC_HZ		 4000000

/*
 * Macros for reading various registers in the 8530
 * NOTE: these should be used only at splscc()!
 */
#define	ZSREAD_A(dst, regno)	\
	{ \
		IODelay(1); \
		ZSADDR_A->zs_ctrl = (regno); \
		IODelay(1); \
		(dst) = ZSADDR_A->zs_ctrl; \
	}

#define	ZSREAD_B(dst, regno)	\
	{ \
		IODelay(1); \
		ZSADDR_B->zs_ctrl = (regno); \
		IODelay(1); \
		(dst) = ZSADDR_B->zs_ctrl; \
	}

#define	ZSWRITE_A(regno, val)	\
	{ \
		IODelay(1); \
		ZSADDR_A->zs_ctrl = (regno); \
		IODelay(1); \
		ZSADDR_A->zs_ctrl = (val); \
	}

#define	ZSWRITE_B(regno, val)	\
	{ \
		IODelay(1); \
		ZSADDR_B->zs_ctrl = (regno); \
		IODelay(1); \
		ZSADDR_B->zs_ctrl = (val); \
	}

#define	ZSREAD(zsaddr, dst, regno)	\
	{ \
		IODelay(1); \
		(zsaddr)->zs_ctrl = (regno); \
		IODelay(1); \
		(dst) = (zsaddr)->zs_ctrl; \
	}

#define	ZSWRITE(zsaddr, regno, val)	\
	{ \
		IODelay(1); \
		(zsaddr)->zs_ctrl = (regno); \
		IODelay(1); \
		(zsaddr)->zs_ctrl = (val); \
	}

/*
 * Public functions
 */
extern int zs_tc(int baudrate, int clkx);

#endif	KERNEL || STANDALONE || MONITOR

#endif	ARCH_PRIVATE

#endif _MY_ZSREG_
