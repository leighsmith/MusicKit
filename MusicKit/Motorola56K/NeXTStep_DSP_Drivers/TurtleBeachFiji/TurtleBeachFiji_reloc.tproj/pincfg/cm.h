/******************************************************************/
/*    Copyright 1993 Intel Corporation ALL RIGHTS RESERVED        */
/*                                                                */
/* This program is confidential and a trade secret of Intel Corp. */
/* The receipt of or possession of this program does not convey   */
/* any rights to reproduce or disclose its contents or to         */
/* manufacture, use, sell anything that it may describe, in       */
/* whole, or in part, without the specific written consent of     */
/* Intel Corp.                                                    */
/******************************************************************/

#ifndef	_CM
#define	_CM

/********************* TYPE DEFINITIONS ******************************/
#ifndef FAR
#define	FAR		__far
#endif

// If windows.h is not included then typedef following
#ifndef	_CACM_DEFINED		// Already defined in another include file
#ifndef _INC_WINDOWS		// For MicroSoft Compiler
#ifndef __WINDOWS_H		// For Borland Compiler
//typedef unsigned char   BYTE;
//typedef unsigned short  WORD;
//typedef unsigned long DWORD;
typedef	unsigned int	HANDLE;
typedef BYTE FAR*	LPBYTE;
typedef	int		BOOL;
typedef long 		LONG;

typedef char FAR*	LPSTR;

//#define FALSE   0
//#define TRUE    1

//#define LOWORD(l) ((WORD)(DWORD)(l))
//#define HIWORD(l) ((WORD)((((DWORD)(l)) >> 16) & 0xFFFF))

//#define LOBYTE(l) ((BYTE)(WORD)(l))
//#define HIBYTE(l) ((BYTE)((((WORD)(l)) >> 8) & 0xFF))


typedef unsigned char _near* PBYTE;

#define	_CACM_DEFINED
#endif // __WINDOWS_H
#endif // _INC_WINDOWS
#endif // _CACM_DEFINED

#ifndef PASCAL
#define	PASCAL	_pascal
#endif

#ifdef	DOS_LIB
#define	_export
#endif

/******************* END OF TYPE DEFINITIONS *****************************/

#define	MAX_MEM_REGISTERS	9
#define	MAX_IO_PORTS		20
#define	MAX_IRQS		7
#define	MAX_DMA_CHANNELS	7

#define	BUS_TYPE_ISA	0x01
#define BUS_TYPE_EISA	0x02
#define	BUS_TYPE_PCI	0x04
#define BUS_TYPE_PCMCIA	0x08
#define BUS_TYPE_PNPISA	0x10
#define BUS_TYPE_MCA	0x20

#define	DEVICE_INITIALIZED	0x01
#define	DEVICE_ENABLED		0x02
#define	DEVICE_LOCKED		0x04


/*********************************************************************/

#define CM_SUCCESS			0
#define	CM_CONFIG_MGR_NOT_PRESENT	-1
#define	CM_FAILED			-1

#define	CM_DEVICE_NOT_FOUND		0x01

#define	CM_CONFIG_ERROR			0x01
#define	CM_IO_PORT_UNAVAILABLE		0x02
#define	CM_IRQ_UNAVAILABLE		0x04
#define	CM_DMA_CH_UNAVAILABLE		0x08
#define	CM_MEM_WINDOW_UNAVAILABLE	0x10

/*********************************************************************/

struct Device_ID
{
  DWORD	dBusID;		// Bus type 0 undefined
  DWORD	dDevID;		// Physical device ID, 0xFFFFFFFF is undefined
  DWORD dSerialNum;	// Serial/Instance number, 0 is undefined
  DWORD	dLogicalID;	// Logical device ID(PnP), Class code(PCI)
  DWORD	dFlags;
};

union Bus_Access
{
  struct PCIAccess
    {
      BYTE bBusNumber;
      BYTE bDevFuncNumber;
      WORD wRsvrd1;
    } sPCIAccess;
  struct EISAAccess
    {
      BYTE bSlotNumber;
      BYTE bFunctionNumber;
      WORD wRsvrd2;
    } sEISAAccess;
  struct PnPAccess
    {
      BYTE bCSN;
      BYTE bLogicalDevNumber;
      WORD wReadDataPort;
    } sPnPAccess;
};

typedef struct
{
  struct Device_ID sDeviceId;
  union Bus_Access uBusAccess;
  WORD  wNumMemWindows;
  DWORD dMemBase[MAX_MEM_REGISTERS];
  DWORD dMemLength[MAX_MEM_REGISTERS];
  WORD  wMemAttrib[MAX_MEM_REGISTERS];
  WORD  wNumIOPorts;
  WORD  wIOPort_Base[MAX_IO_PORTS];
  WORD  wIOPort_Length[MAX_IO_PORTS];
  WORD  wNumIRQs;
  BYTE  bIRQRegisters[MAX_IRQS];
  BYTE  bIRQAttrib[MAX_IRQS];
  WORD  wNumDMAs;
  BYTE  bDMALst[MAX_DMA_CHANNELS];
  WORD  wDMAAttrib[MAX_DMA_CHANNELS];
  BYTE  bReserved1[3];
} Config_Info;

/* Make the include file work with both C and C++ - MSC */
#ifdef __cplusplus
extern "C" {
#endif

#if defined(_INC_WINDOWS) || defined(__WINDOWS_H)

int PASCAL _export _CM_GetVersion(WORD FAR *, WORD FAR *);

int PASCAL _export _CM_GetConfig(WORD, Config_Info FAR *);

int PASCAL _export _CM_LockConfig(Config_Info FAR *);
int PASCAL _export _CM_UnlockConfig(Config_Info FAR *);

#else	// DOS

int _CM_GetVersion(WORD FAR *, WORD FAR *);

int _CM_GetConfig(WORD, Config_Info FAR *);

int _CM_LockConfig(Config_Info FAR *);
int _CM_UnlockConfig(Config_Info FAR *);

#endif	// _INC_WINDOWS | __WINDOWS_H

#ifdef __cplusplus
}
#endif

#endif	// _CM
