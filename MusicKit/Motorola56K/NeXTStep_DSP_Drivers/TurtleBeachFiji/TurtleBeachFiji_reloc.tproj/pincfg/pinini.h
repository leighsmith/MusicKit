// system defaults
#define   DEF_PORT_ADDRESS      0x298
#define   DEF_CFG_FILE_NAME    "PINCFG.INI"
#define   NUM_LOGICAL_DEVICES   0x04

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

// .INI file reader constants
#define   STR_LD0                 "[LogicalDevice0]"
#define   STR_LD1                 "[LogicalDevice1]"
#define   STR_LD2                 "[LogicalDevice2]"
#define   STR_LD3                 "[LogicalDevice3]"
#define   STR_ACTIVE              "Active"
#define   STR_IOADDRESS0          "IOAddress0"
#define   STR_IOADDRESS1          "IOAddress1"
#define   STR_IRQ                 "IRQNumber"
#define   RAM_ADDRESS_VALUE       "RAMAddress"

#define   BUFLEN                256
#define   LOGICAL_DEVICE_ZERO   0x00
#define   LOGICAL_DEVICE_ONE    0x01
#define   LOGICAL_DEVICE_TWO    0x02
#define   LOGICAL_DEVICE_THREE  0x03

#define   ACTIVE_STATE          0x100
#define   IO_ADDRESS0_VALUE     0x101
#define   IO_ADDRESS1_VALUE     0x102
#define   IRQ_VALUE             0x103
#define   RAM_ADDRESS_VALUE     0x104

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


