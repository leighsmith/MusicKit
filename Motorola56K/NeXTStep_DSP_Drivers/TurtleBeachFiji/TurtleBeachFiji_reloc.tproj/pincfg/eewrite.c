/************************************************************************
 *    MultiSound Pinnacle PNP resource EEPROM writer
 *
 *    This module is written to talk to the ATMEL AT93C66 serial
 *    EEPROM through the XILINX chip on the Multisound Pinnacle.
 *    The primary functions are read, write and verify the PNP data.
 *
 *    Copyright 1996  Turtle Beach Systems Inc., All rights reserved.
 *
 *
 * **********************************************************************/

#include <stdio.h>
#include "eewrite.h"

// global variables
WORD wReadPortAddress;
WORD wWritePortAddress;
// WORD wPortAddress=0x262;

// Timer functions used for clocking data
WORD wsnaptimer(void)
{
  BYTE b0,b1;

	outp(0x43,0);			// freeze the timer
	b0 = inp(0x40);                 // read it
	b1 = inp(0x40);
	return(MAKEWORD(b0,b1));
}

void DelayHalfCycle(void)
{
  WORD w0;
	w0 = wsnaptimer();
  while ((w0-wsnaptimer()) < EE_HALFCYCLE_TICKS) {};
}  


// EE functions
// bData must be either 0 or 1
void EEClockDataOut( BYTE bData )
{
  outp(wWritePortAddress, (bData&(~EE_SCLK))); // zero clock
  DelayHalfCycle();
  outp(wWritePortAddress, (bData|EE_SCLK)); // raise clock
  DelayHalfCycle();
}

BYTE EEClockDataIn( void )
{
  BYTE bData;
  outp(wWritePortAddress, ( EE_SCE )); // zero clock
  DelayHalfCycle();
  outp(wWritePortAddress, ( EE_SCE | EE_SCLK)); // raise clock
  bData=inp(wReadPortAddress) & 0x01;   // we only want bit0
  DelayHalfCycle();
  return(bData);
}

WORD EEWaitForReady(void)
{
  WORD wTimeOut = EE_WRITE_TO;
  EEClockDataOut(EE_SCE);
  while ( wTimeOut-- )
  {
    if ( EEClockDataIn() )
      return(EEOP_NOERR);
  }
  return(EEOP_TIMEOUT);
}

WORD EEAcknowledge( void )
{
  WORD wReturn;
  wReturn = EEWaitForReady();
  // put EE in standby mode
  EEClockDataOut(0);
  return(wReturn);
}

void EESerialOut(WORD wData, WORD wLength)
{
  int nCount;
  for( nCount=wLength-1 ; nCount >=0 ; nCount-- )
  {
    if ( wData & (1<<nCount) )
      EEClockDataOut(EE_DATA_ONE | EE_SCE);
    else
      EEClockDataOut(EE_DATA_ZERO | EE_SCE);
  }
}

void EECommandOut(WORD wCmd, WORD wLength )
{
  // assert chip enable
//  EEClockDataOut(EE_SCE);
  EESerialOut(wCmd, wLength);
  // terminate the command
  EEClockDataOut(0);
}

void EEWriteEnable(void)
{
  EECommandOut(EECMD_EWEN, EECMD_LENGTH);
}

void EEWriteDisable(void)
{
  EECommandOut(EECMD_EWDS, EECMD_LENGTH);
}

WORD EEErasePart(void)
{
  EECommandOut(EECMD_ERAL, EECMD_LENGTH);
  return(EEAcknowledge());
}

WORD EEWriteAll( BYTE bData )
{
  // assert chip enable
  EEClockDataOut(EE_SCE);
  EESerialOut(EECMD_WRAL, EECMD_LENGTH);
  EESerialOut(bData,8);
  // terminate command
  EEClockDataOut(0);
  return( EEAcknowledge() );
}

WORD EEWriteByte( BYTE bData, WORD wAddress )
{
  EESerialOut(EECMD_WRITE | wAddress, EECMD_LENGTH);
  EESerialOut(bData,8);
  // terminate command
  EEClockDataOut(0);
  return(EEAcknowledge());
}

WORD EEWriteWord( WORD wData, WORD wAddress )
{
  WORD wTemp;
  wTemp = MAKEWORD(HIBYTE(wData),LOBYTE(wData));
  EESerialOut( 0x140 | wAddress, 9);
  EESerialOut(wTemp,16);
  // terminate command
  EEClockDataOut(0);
  return(EEAcknowledge());
}

WORD EEEraseByte( WORD wAddress )
{
  EECommandOut( EECMD_ERASE | wAddress, EECMD_LENGTH);
  return(EEAcknowledge());
}

BYTE EEReadByte( WORD wAddress )
{
  BYTE bData, bBit;
  // this is temporary for the AT93C46
//  EESerialOut(( 0x0300 | wAddress),10);
  EESerialOut(EECMD_READ | wAddress, EECMD_LENGTH);
  // clock the dummy bit in
//  EEClockDataIn();
  // clock in the data
  for ( bBit=0 ; bBit<8 ; bBit++ )
  {
    bData = (bData << 1) & 0xFE;     // shift and clear d0
    bData |= EEClockDataIn();
  }
  // terminate the command
  EEClockDataOut(0);
  return(bData);
}

WORD EEReadWord( WORD wAddress )
{
  WORD wData,wTemp;
  BYTE bBit;
  // this is temporary for the AT93C46 in Word mode
  EESerialOut(( 0x0180 | wAddress),9);
  EEClockDataIn();
  // clock in the data
  for ( bBit=0 ; bBit<16 ; bBit++ )
  {
    wData = (wData << 1) & 0xFFFE;     // shift and clear d0
    wData |= EEClockDataIn();
  }
  // terminate the command
  EEClockDataOut(0);
  wTemp = MAKEWORD(HIBYTE(wData),LOBYTE(wData));
  return(wData);
}

WORD EEWritePartData( EEDATA *pData, WORD wDataSize )
{
  WORD wAddress;
  if ( wDataSize > EE_DATA_SIZE )
    return(EEOP_TOOBIG);

  for ( wAddress=0 ; wAddress<EE_DATA_SIZE ; wAddress++ )
  {
#if WORD_WRITES
    if (EEWriteWord( *(pData+wAddress), wAddress ) )
      return(MAKEWORD(EEOP_TIMEOUT,(LOBYTE(wAddress))));
#else
    if (EEWriteByte( *(pData+wAddress), wAddress ) )
      return(MAKEWORD(EEOP_TIMEOUT,(LOBYTE(wAddress))));
#endif
  }
  return(EEOP_NOERR);
}

// needs buffer the size of the part
void EEReadPartData( EEDATA *pData )
{
  WORD wAddress;
  for ( wAddress=0 ; wAddress<EE_DATA_SIZE ; wAddress++ )
#if WORD_WRITES
    *(pData+wAddress) = EEReadWord(wAddress);
#else
    *(pData+wAddress) = EEReadByte(wAddress);
#endif
}

// data buffer must be postpended with 0xFF's from end of file to part size
WORD EEVerifyPartData( EEDATA *pData )
{
  WORD wAddress;
  for ( wAddress=0 ; wAddress<EE_DATA_SIZE ; wAddress++ )
    {
#if WORD_WRITES
    if ( EEReadWord(wAddress) != *(pData+wAddress) )
#else
    if ( EEReadByte(wAddress) != (BYTE)*(pData+wAddress) )
#endif
      return(MAKEWORD(EEOP_BADVERIFY,(LOBYTE(wAddress))));
    }
  return(EEOP_NOERR);
}

// Resource validation functions
WORD ValidateChecksum( EEDATA *pData, WORD wDataSize )
{
  WORD wSum=0;
  WORD wCount;
  BYTE bCheckSum;
  for( wCount = 0 ; wCount < (wDataSize-1) ; wCount++ )
    wSum += *((BYTE *)pData+wCount);

  bCheckSum = (BYTE)(-wSum);

  if ( *(pData+wDataSize-1) == bCheckSum )
    return(EEOP_NOERR);
  else
    return( MAKEWORD( EEOP_BADCHECKSUM, bCheckSum ) );
}

// interface functions
WORD WriteEEPROMData(WORD wRead, WORD wWrite, BYTE *pData, WORD wDataSize)
{
  WORD wReturn;
  wReadPortAddress = wRead;
  wWritePortAddress = wWrite;
  EEWriteEnable();
  wReturn=EEWritePartData( pData, wDataSize );
  EEWriteDisable();
  return wReturn;
}

WORD VerifyEEPROMData(WORD wRead, WORD wWrite, BYTE *pData, WORD wDataSize)
{
  WORD wIndex;
  wReadPortAddress = wRead;
  wWritePortAddress = wWrite;
  return (EEVerifyPartData(pData));
}

