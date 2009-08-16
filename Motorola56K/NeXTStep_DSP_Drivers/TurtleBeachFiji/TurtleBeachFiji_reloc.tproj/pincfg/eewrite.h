//  Header file containing equates for EEWRITE.C
//
//  Copyright 1996 Turtle Beach Systems Inc.  All rights reserved

// macros and typedefs
typedef unsigned char BYTE;
typedef unsigned int  WORD;
typedef unsigned long DWORD;
typedef int BOOL;

#define TRUE  1
#define FALSE 0

#define HIWORD(l)    ((WORD)((((DWORD)(l)) >> 16) & 0xFFFF ))
#define LOWORD(l)    ((WORD)(DWORD)(l))
#define HIBYTE(w)    ((BYTE)(((WORD)(w) >> 8 ) & 0xFF ))
#define LOBYTE(w)    ((BYTE)(w))
#define MAKELONG(low,hi) ((long)(((WORD)(low))|(((DWORD)((WORD)(hi)))<<16)))
#define MAKEWORD(low,hi) ((WORD)(((BYTE)(low))|(((WORD)((BYTE)(hi)))<<8)))

// write in word mode
#define WORD_WRITES             (0)

// system defaults
#define   EE_BYTE_SIZE          512
#if WORD_WRITES
#define   EE_DATA_SIZE          (EE_BYTE_SIZE/2)
#else
#define   EE_DATA_SIZE          (EE_BYTE_SIZE)
#endif

// EEPROM Pins
#define   EE_SCE                0x04
#define   EE_SCLK               0x02
#define   EE_SDATAO             0x01
#define   EE_SDATAI             0x01

// EEPROM Data Values
#define   EE_DATA_ONE           0x01
#define   EE_DATA_ZERO          0x00

// instruction command strings for the AT93C66
// EEPROM Command strings
// params for opcode EEOP_EWEN      EWEN    11xxxxxxx - enable programming
//                                  ERAL    10xxxxxxx - erases all memory
//                                  WRAL    01xxxxxxx - writes all memory D7-D0
//                                  EWDS    00xxxxxxx - disables all programming
#define   EECMD_LENGTH          12      // command length for 93C66
//#define   EECMD_LENGTH          9      // command length for 93C46
#define   EECMD_EWEN            0x09FF
#define   EECMD_EWDS            0x087F
#define   EECMD_ERAL            0x097F

// The following commands must be ord with the address
// EE Read   1 1 0 a8 | a7 a6 a5 a4 | a3 a2 a1 a0
#define   EECMD_READ            0x0C00      // read location A8-A0

// EE Write  1 0 1 a8 | a7 a6 a5 a4 | a3 a2 a1 a0 | d7 d6 d5 d4 | d3 d2 d1 d0
// must or address w/ cmd , must write data byte after command/address
#define   EECMD_WRITE           0x0A00      // write location A8-A0

// EE Erase  1 1 1 a8 | a7 a6 a5 a4 | a3 a2 a1 a0
#define   EECMD_ERASE           0x0E00      //erase location A8-A0

// EE Write All  1 0 0 0 | 1 x x x | x x x x | d7 d6 d5 d4 | d3 d2 d1 d0
// must write data byte after command/address
#define   EECMD_WRAL            0x0880      //write all locations w/ d7-d0

// EEPROM Cycle Times
#define   EE_WRITE_TO           1000
#define   EE_HALFCYCLE_TICKS    25          // this is about 100KHz

// EE function returns
#define   EEOP_NOERR            0x00
#define   EEOP_TIMEOUT          0x01
#define   EEOP_TOOBIG           0x02
#define   EEOP_BADVERIFY        0x03
#define   EEOP_BADCHECKSUM      0x04

#if WORD_WRITES
typedef unsigned int EEDATA;
#else
typedef unsigned char EEDATA;
#endif

