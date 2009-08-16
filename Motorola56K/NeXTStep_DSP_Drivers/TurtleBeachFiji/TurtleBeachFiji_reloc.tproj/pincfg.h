//  Header file containing equates for PINCFG.C
//
//  Copyright 1996 Turtle Beach Systems Inc.  All rights reserved
//  
//  Changes:
//  daj/4-6-97 - WORD typedef changed to short, commented out BOOL

// Software Version
#define SOFTWARE_VERSION        "1.00.3"

// system defaults
#define   DEF_PORT_ADDRESS      0x250
#define   DEF_CFG_FILE_NAME     "PINCFG.INI"
#define   NUM_LOGICAL_DEVICES   0x05
#define   MAX_INIBUFFER_LINES   0x40
#define   PNP_WRITEDATA_PORT    0xA79
#define   PNP_WRITEADDR_PORT    0x279

// PnP ID's
#define   TBS_PINNACLE_PNPID    0x4004CA0A    // TBS2002
#define   TBS_PINNACLE_LD0      0x00005350    // TBS0000   - DSP
#define   TBS_PINNACLE_LD1      0x01005350    // TBS0001   - MPU
#define   TBS_PINNACLE_LD2      0x2FB0D041    // PNPB02F   - Game Port ID
#define   TBS_PINNACLE_LD3      0x03005350    // TBS0003   - IDE

// board defaults
//dsp LD0
#define   DEF_DSP_PORT          0x290
#define   DEF_DSP_RAM           0xD000
#define   DEF_DSP_IRQ           11
//kurzweil LD1
#define   DEF_KZ_PORT           0x330
#define   DEF_KZ_IRQ            9
//game LD2
#define   DEF_GAME_PORT         0x200
//ide LD3
#define   DEF_IDE_PORT0         0x170
#define   DEF_IDE_PORT1         0x370
#define   DEF_IDE_IRQ           15

// application modes
#define   CFGMODE_PNP           0x00
#define   CFGMODE_NOPNP         0x01
//#define   STR_PNPMODE           "PNP"
//#define   STR_NOPNPMODE         "NOPNP"

// application operations
#define   EXE_CONFIGURE         0x00
#define   EXE_READ              0x01
#define   EXE_VERIFY            0x02
#define   EXE_DEBUG             0x03  //debug case for test functions
#define   EXE_LOADEEFILE        0x04  // write resource EEPROM with file

// application exit codes
#define   EC_NOERR              0x00
#define   EC_HW_NOTPRESENT      0x01
#define   EC_NOREADPORT         0x02
#define   EC_EEWRITEFAIL        0x03
#define   EC_EEVERIFYFAIL       0x04
#define   EC_BADFILENAME        0x05
#define   EC_INVALIDOPTION      0x06

// .INI file reader constants
#define   LD_CTRL                 0x04
#define   STR_COMMENT             0x2F
#define   STR_CONTROL             "[ConfigControl]"
#define   STR_LD0                 "[LogicalDevice0]"
#define   STR_LD1                 "[LogicalDevice1]"
#define   STR_LD2                 "[LogicalDevice2]"
#define   STR_LD3                 "[LogicalDevice3]"
#define   STR_ACTIVE              "Active"
#define   STR_IOADDRESS0          "IOAddress0"
#define   STR_IOADDRESS1          "IOAddress1"
#define   STR_IRQ                 "IRQNumber"
#define   STR_RAMADDRESS          "RAMAddress"
//#define   STR_CONFIGMODE          "Config"

#define   BUFLEN                0x40
#define   LDEVICE_ZERO          0x00
#define   LDEVICE_ONE           0x01
#define   LDEVICE_TWO           0x02
#define   LDEVICE_THREE         0x03
#define   LDEVICE_UNDEFINED     0x0F
#define   ACTIVE_STATE          0x100
#define   IO_ADDRESS0_VALUE     0x101
#define   IO_ADDRESS1_VALUE     0x102
#define   IRQ_VALUE             0x103
#define   RAM_ADDRESS_VALUE     0x104

// function returns
#define   CFGOP_NOERR            0x00
#define   CFGOP_TIMEOUT          0x01
#define   CFGOP_BADVERIFY        0x03
#define   CFGOP_BADFILENAME      0x04
#define   CFGOP_NOHARDWARE       0x05
#define   CFGOP_NOREADPORT       0x00
#define   CFGOP_CANTWRITE        0x06
#define   CFGOP_NOMEM            0x07

// macros and typedefs
typedef unsigned char BYTE;
typedef unsigned short  WORD;
typedef unsigned long DWORD;
// typedef int BOOL;

#ifndef TRUE
#define TRUE  1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#define HIWORD(l)    ((WORD)((((DWORD)(l)) >> 16) & 0xFFFF ))
#define LOWORD(l)    ((WORD)(DWORD)(l))
#define HIBYTE(w)    ((BYTE)(((WORD)(w) >> 8 ) & 0xFF ))
#define LOBYTE(w)    ((BYTE)(w))
#define MAKELONG(low,hi) ((long)(((WORD)(low))|(((DWORD)((WORD)(hi)))<<16)))
#define MAKEWORD(low,hi) ((WORD)(((BYTE)(low))|(((WORD)((BYTE)(hi)))<<8)))

// Configuration register definitions
// device regs
#define   IREG_LOGDEVICE    0x07
#define   IREG_ACTIVATE     0x30
#define   LD_ACTIVATE       0x01
#define   LD_DISACTIVATE    0x00
#define   IREG_EECONTROL    0x3F

// memory window regs
#define   IREG_MEMBASEHI    0x40
#define   IREG_MEMBASELO    0x41
#define   IREG_MEMCONTROL   0x42
#define   IREG_MEMRANGEHI   0x43
#define   IREG_MEMRANGELO   0x44
#define   MEMTYPE_8BIT      0x00
#define   MEMTYPE_16BIT     0x02
#define   MEMTYPE_RANGE     0x00
#define   MEMTYPE_HIADDR    0x01

// I/O regs
#define   IREG_IO0_BASEHI   0x60
#define   IREG_IO0_BASELO   0x61
#define   IREG_IO1_BASEHI   0x62
#define   IREG_IO1_BASELO   0x63

// IRQ regs
#define   IREG_IRQ_NUMBER   0x70
#define   IREG_IRQ_TYPE     0x71
#define   IRQTYPE_HIGH      0x02
#define   IRQTYPE_LOW       0x00
#define   IRQTYPE_LEVEL     0x01
#define   IRQTYPE_EDGE      0x00

// data structures
typedef struct tagLDDATA {
  BYTE bLDNumber;
  BOOL fActive;
  WORD wIOAddr0;
  WORD wIOAddr1;
  WORD wIRQ;
  WORD wRAMAddr;
} LDDATA, *PLDDATA ;

typedef struct tagPINCFGDATA {
  LDDATA ld[NUM_LOGICAL_DEVICES];
} PINCFG, *PPINCFG;





