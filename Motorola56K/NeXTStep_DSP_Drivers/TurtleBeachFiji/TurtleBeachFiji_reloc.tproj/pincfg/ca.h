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

#ifndef	_CA
#define	_CA

/********************* TYPE DEFINITIONS ******************************/
#ifndef FAR
#define	FAR		__far
#endif

// If windows.h is not included then typedef following
#ifndef _CACM_DEFINED		// defined in another include file
#ifndef _INC_WINDOWS		// For MicroSoft Compiler
#ifndef __WINDOWS_H		// For Borland Compiler
typedef unsigned char 	BYTE;
typedef unsigned short	WORD;
typedef unsigned long	DWORD;
typedef	unsigned int	HANDLE;
typedef BYTE FAR*	LPBYTE;
typedef	int		BOOL;
typedef long 		LONG;

typedef char FAR*	LPSTR;

#define	FALSE		0
#define	TRUE		1

#define	LOWORD(l)	((WORD)(DWORD)(l))
#define	HIWORD(l)	((WORD)((((DWORD)(l)) >> 16) & 0xFFFF))

#define	LOBYTE(l)	((BYTE)(WORD)(l))
#define	HIBYTE(l)	((BYTE)((((WORD)(l)) >> 8) & 0xFF))

#define	_CACM_DEFINED
#endif // __WINDOWS_H
#endif // _INC_WINDOWS
#endif //_CACM_DEFINED

#ifndef PASCAL
#define	PASCAL	_pascal
#endif

#ifdef	DOS_LIB
#define	_export		
#endif

/******************* END OF TYPE DEFINITIONS *****************************/

#define CA_SUCCESS			0
#define	CA_SUPPORT_NOT_PRESENT		-1
#define	CA_FAILED			-1

// PCI Error codes
#define	PCI_SUCCESS			0x00
#define	PCI_UNSUPPORTED_FUNCT		0x81
#define	PCI_BAD_VENDOR_ID		0x83
#define	PCI_DEVICE_NOT_FOUND		0x86
#define	PCI_BAD_REGISTER_NUMBER		0x87

// PnPISA Error codes
#define	PnPISA_SUCCESS			0x00
#define	PnPISA_CONFIG_ERROR		0x01
#define	PnPISA_UNSUPPORTED_FUNCT	0x81
#define	PnPISA_DEVICE_NOT_FOUND		0x86

// EISA error codes
#define	EISA_SUCCESS			0x00
#define	EISA_INVALID_SLOT_NUMBER	0x80
#define	EISA_INVALID_FUNC_NUMBER	0x81
#define	EISA_CORRUPTED_NVRAM		0x82
#define	EISA_EMPTY_SLOT			0x83
#define	EISA_WRITE_ERROR		0x84
#define	EISA_NVRAM_FULL			0x85
#define	EISA_UNSUPPORTED_FUNCT		0x86
#define	EISA_INVLD_OR_LOCKED_CONFIG	0x87
#define	EISA_UNSUPPORTED_ECU_VER	0x88

// ESCD error codes
#define	ESCD_SUCCESS			0x00
#define	ESCD_CONFIG_ERROR		0x01
#define	ESCD_BAD_NVS			0x02
#define	ESCD_UNSUPPORTED_FUNCT		0x81
#define	ESCD_FAILURE_ON_EISA_SYSTEM	0x82

// Acfg_PCI error codes
#define	ACFG_SUCCESS			0x00
#define	ACFG_INVALID			0x01
#define	ACFG_BUFFER_TOO_SMALL		0x59
#define	ACFG_UNSUPPORTED_FUNCT		0x81

/*********************************************************************/
// Used by _CA_Eisa_Get_Slot_Config function
typedef struct
{
  BYTE bslot_ah;
  BYTE bslot_dupidnm : 4;
  BYTE bslot_type : 2;
  BYTE bslot_prodid : 1;
  BYTE bslot_dupid : 1;
  BYTE bslot_mi_ver;
  BYTE bslot_ma_ver;
  WORD wslot_cfg_chksum;
  union slt_cfgfunc
    {
      struct sltcfgbyte
      {
        BYTE bslot_cfgfbyte;
      } sltcfgbyte;
      struct sltcfgbits
      {
        BYTE bslot_mltfun : 1;
        BYTE bslot_mltmem : 1;
        BYTE bslot_mltirq : 1;
        BYTE bslot_mltdma : 1;
        BYTE bslot_mltiop : 1;
        BYTE bslot_mltini : 1;
        BYTE bslot_mltsrv : 2;
      } sltcfgbits;
    } uslt_cfgfunc;
  BYTE bslot_num_func;
  WORD wslot_cmpid01;
  WORD wslot_cmpid23;
} EISA_SLOT_INFO;

typedef struct
{
  BYTE bPnPBIOS		:1;	/* Bit 0 - PnP BIOS present = 1 */
  BYTE bReserved 	:7;	/* Bit 1-7 Reserved (0) */
  BYTE bMaxCSN;			/* Highest PnP ISA CSN */
  DWORD dPnPBIOSAddr;		/* Physical addr. of  PnP BIOS info strcut.
                                   when 0, struct not present */
} PnPInfoBuffer;

typedef struct
{
  WORD 	wBufferSize;
  LPBYTE lpDataBuffer;
} IRQRoutingInfoBuffer;


/* Make the include file work with both C and C++ - MSC */
#ifdef __cplusplus
extern "C" {
#endif

#if defined(_INC_WINDOWS) || defined(__WINDOWS_H)

int PASCAL _export _CA_GetVersion(WORD FAR *);

int PASCAL _export _CA_PCI_Read_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PCI_Read_Config_Word(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PCI_Read_Config_DWord(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PCI_Write_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PCI_Write_Config_Word(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PCI_Write_Config_DWord(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PCI_Generate_Special_Cycle(BYTE, DWORD);

int PASCAL _export _CA_PnPISA_Get_Info(BYTE FAR *);
int PASCAL _export _CA_PnPISA_Read_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PnPISA_Write_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_PnPISA_Get_Resource_Data(BYTE, WORD, WORD FAR *, BYTE FAR *);

int PASCAL _export _CA_EISA_Get_Board_ID(BYTE, BYTE FAR *);
int PASCAL _export _CA_EISA_Get_Slot_Config(BYTE, BYTE FAR *);
int PASCAL _export _CA_EISA_Get_SlotFunc_Config(BYTE, BYTE, BYTE FAR *);
int PASCAL _export _CA_EISA_Clear_Nvram_Config(BYTE, BYTE);
int PASCAL _export _CA_EISA_Write_Config(WORD, BYTE FAR *);

int PASCAL _export _CA_ESCD_Get_Info(WORD FAR *);
int PASCAL _export _CA_ESCD_Read_Config(BYTE FAR *);
int PASCAL _export _CA_ESCD_Write_Config(BYTE FAR *);

int PASCAL _export _CA_Acfg_PCI_Manage_IRQs(BYTE FAR *);
int PASCAL _export _CA_Acfg_PCI_Get_Routing_Options(BYTE FAR *);

#else	// DOS

int _CA_GetVersion(WORD FAR *);

int _CA_PCI_Read_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PCI_Read_Config_Word(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PCI_Read_Config_DWord(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PCI_Write_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PCI_Write_Config_Word(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PCI_Write_Config_DWord(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PCI_Generate_Special_Cycle(BYTE, DWORD);

int _CA_PnPISA_Get_Info(BYTE FAR *);
int _CA_PnPISA_Read_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PnPISA_Write_Config_Byte(BYTE, BYTE, BYTE, BYTE, BYTE FAR *);
int _CA_PnPISA_Get_Resource_Data(BYTE, WORD, WORD FAR *, BYTE FAR *);

int _CA_EISA_Get_Board_ID(BYTE, BYTE FAR *);
int _CA_EISA_Get_Slot_Config(BYTE, BYTE FAR *);
int _CA_EISA_Get_SlotFunc_Config(BYTE, BYTE, BYTE FAR *);
int _CA_EISA_Clear_Nvram_Config(BYTE, BYTE);
int _CA_EISA_Write_Config(WORD, BYTE FAR *);

int _CA_ESCD_Get_Info(WORD FAR *);
int _CA_ESCD_Read_Config(BYTE FAR *);
int _CA_ESCD_Write_Config(BYTE FAR *);

int _CA_Acfg_PCI_Manage_IRQs(BYTE FAR *);
int _CA_Acfg_PCI_Get_Routing_Options(BYTE FAR *);

#endif	// _INC_WINDOWS | __WINDOWS_H

#ifdef __cplusplus
}
#endif
      
#endif	// _CA
