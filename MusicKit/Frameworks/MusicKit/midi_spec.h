/*
  $Id$
  Defined In: The MusicKit

  Description: MIDI definitions

  Author: David Jaffe
 	Copyright (C) 1991, NeXT, Inc.
*/
/*
Modification history:

  $Log$
  Revision 1.3  2000/02/07 23:53:26  leigh
  added patch bank change and MIDI pitch bend range defintions

  Revision 1.2  1999/07/29 01:26:06  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef	_MIDI_SPEC_
#define _MIDI_SPEC_

/*
 * MIDI status bytes (from International MIDI Association document
 * MIDI-1.0, August 5, 1983)
 */
#define MIDI_RESETCONTROLLERS	0x79
#define MIDI_LOCALCONTROL	0x7a
#define MIDI_ALLNOTESOFF	0x7b
#define MIDI_OMNIOFF		0x7c
#define MIDI_OMNION		0x7d
#define MIDI_MONO		0x7e
#define MIDI_POLY		0x7f
#define	MIDI_NOTEOFF		0x80
#define	MIDI_NOTEON		0x90
#define	MIDI_POLYPRES		0xa0
#define	MIDI_CONTROL		0xb0
#define	MIDI_PROGRAM		0xc0
#define	MIDI_CHANPRES		0xd0
#define	MIDI_PITCH		0xe0
#define	MIDI_CHANMODE		MIDI_CONTROL
#define	MIDI_SYSTEM		0xf0
#define	MIDI_SYSEXCL		(MIDI_SYSTEM | 0x0)
#define MIDI_TIMECODEQUARTER	(MIDI_SYSTEM | 0x1)
#define	MIDI_SONGPOS		(MIDI_SYSTEM | 0x2)
#define	MIDI_SONGSEL		(MIDI_SYSTEM | 0x3)
#define	MIDI_TUNEREQ		(MIDI_SYSTEM | 0x6)
#define	MIDI_EOX		(MIDI_SYSTEM | 0x7)
#define MIDI_CLOCK		(MIDI_SYSTEM | 0x8)
#define MIDI_START		(MIDI_SYSTEM | 0xa)
#define MIDI_CONTINUE		(MIDI_SYSTEM | 0xb)
#define MIDI_STOP		(MIDI_SYSTEM | 0xc)
#define MIDI_ACTIVE		(MIDI_SYSTEM | 0xe)
#define MIDI_RESET		(MIDI_SYSTEM | 0xf)

#define MIDI_MAXDATA            0x7f
#define MIDI_OP(y)              (y & (MIDI_STATUSMASK))
#define MIDI_DATA(y)            (y & (MIDI_MAXDATA))
#define MIDI_MAXCHAN            0x0f
#define MIDI_NUMCHANS           16
#define MIDI_NUMKEYS            128
#define MIDI_ZEROBEND           0x2000
#define MIDI_DEFAULTVELOCITY    64

/* MIDI Controller numbers */

#define MIDI_MODWHEEL           1
#define MIDI_BREATH             2
#define MIDI_FOOT               4
#define MIDI_PORTAMENTOTIME     5
#define MIDI_DATAENTRY          6
#define MIDI_MAINVOLUME         7
#define MIDI_BALANCE            8
#define MIDI_PAN                10
#define MIDI_EXPRESSION         11
#define MIDI_EFFECTCONTROL1	12
#define MIDI_EFFECTCONTROL2	13			

/* LSB for above */
#define MIDI_MODWHEELLSB        (1 + 31)  
#define MIDI_BREATHLSB          (2 + 31)
#define MIDI_FOOTLSB            (4 + 31)
#define MIDI_PORTAMENTOTIMELSB  (5 + 31)
#define MIDI_DATAENTRYLSB       (6 + 31)
#define MIDI_MAINVOLUMELSB      (7 + 31)
#define MIDI_BALANCELSB         (8 + 31)
#define MIDI_PANLSB             (10 + 31)
#define MIDI_EXPRESSIONLSB      (11 + 31)

/* patch bank change commands */
#define MIDI_BANKMSB		0
#define MIDI_BANKLSB		32

#define MIDI_DAMPER             64
#define MIDI_PORTAMENTO         65
#define MIDI_SOSTENUTO          66
#define MIDI_SOFTPEDAL          67
#define MIDI_HOLD2              69
/*
 * Controller 91-95 definitions from original 1.0 MIDI spec
 */
#define MIDI_EXTERNALEFFECTSDEPTH 91
#define MIDI_TREMELODEPTH       92
#define MIDI_CHORUSDEPTH        93
#define MIDI_DETUNEDEPTH        94
#define MIDI_PHASERDEPTH        95
/*
 * Controller 91-95 definitions as of June 1990
 */
#define MIDI_EFFECTS1		91
#define MIDI_EFFECTS2		92
#define MIDI_EFFECTS3		93
#define MIDI_EFFECTS4		94
#define MIDI_EFFECTS5		95
#define MIDI_DATAINCREMENT      96
#define MIDI_DATADECREMENT      97

/* Controller 100-101 definitions for pitch bend range */
#define MIDI_PITCHBENDRANGE	100

/*
 * Masks for disassembling MIDI status bytes
 */
#define	MIDI_STATUSBIT	0x80	/* indicates this is a status byte */
#define	MIDI_STATUSMASK	0xf0	/* bits indicating type of status req */
#define	MIDI_SYSRTBIT	0x08	/* differentiates SYSRT from SYSCOM */

/* Some useful parsing macros. */
#define MIDI_TYPE_SYSTEM_REALTIME(byte)	(((byte)&0xf8) == 0xf8)
#define MIDI_TYPE_1BYTE(byte)	(   MIDI_TYPE_SYSTEM_REALTIME(byte) \
				 || (byte) == 0xf6 || (byte) == 0xf7)
#define MIDI_TYPE_2BYTE(byte)	(   (((byte)&0xe0) == 0xc0) \
				 || (((byte)&0xe0) == 0xd0) \
				 || ((byte)&0xfd) == 0xf1)
#define MIDI_TYPE_3BYTE(byte)	(   ((byte)&0xc0) == 0x80 \
				 || ((byte)&0xe0) == 0xe0 \
				 || (byte) == 0xf2)
#define MIDI_TYPE_SYSTEM(byte)	(((byte)&0xf0) == 0xf0)
#define MIDI_EVENTSIZE(byte)    (MIDI_TYPE_1BYTE(byte) ? 1 : \
				 MIDI_TYPE_2BYTE(byte) ? 2 : 3)

#endif	_MIDI_SPEC_