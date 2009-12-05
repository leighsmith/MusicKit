/************************************************************************
 *    MultiSound Pinnacle/Fiji Configuration Utility
 *
 *    The values are programmed by
 *    setting the disable PnP jumper on the board, and then writing
 *    to config registers. These registers are located at:
 *
 *    00 => PNP MODE(DEFAULT)
 *    01 => 250h
 *    10 => 260h
 *    11 => 270h
 *
 *    The registers are:
 *    0 => PnP Index register
 *    1 => PnP Data register
 *
 *    Portions Copyright 1996  Turtle Beach Systems Inc., All rights reserved.
 *
 *
 * **********************************************************************/

#include <stdio.h>
#include "pincfg.h"

#define VERIFY_CFG 0

// global variables
static WORD wPortAddress;

#define outp outb
#define inp inb

// register functions
static void WriteCFGRegister(WORD wRegister, BYTE bValue )
{
  outp(wPortAddress, wRegister);
  outp(wPortAddress+1, bValue);
}

static BYTE ReadCFGRegister(WORD wRegister)
{
  outp(wPortAddress, wRegister);
  return(inp(wPortAddress+1));
}

static void ActivateLogicalDevice( BYTE bLogDev )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev );
  WriteCFGRegister(IREG_ACTIVATE, LD_ACTIVATE );
}

static void DisActivateLogicalDevice( BYTE bLogDev )
{	// added by daj
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev );
  WriteCFGRegister(IREG_ACTIVATE, LD_DISACTIVATE );
}

static void ConfigureIO0(BYTE bLogDev, WORD wIOAddress )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_IO0_BASEHI, HIBYTE(wIOAddress));
  WriteCFGRegister(IREG_IO0_BASELO, LOBYTE(wIOAddress));
}

static void ConfigureIO1(BYTE bLogDev, WORD wIOAddress )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_IO1_BASEHI, HIBYTE(wIOAddress));
  WriteCFGRegister(IREG_IO1_BASELO, LOBYTE(wIOAddress));
}

static void ConfigureIRQ(BYTE bLogDev, WORD wIRQ )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_IRQ_NUMBER, LOBYTE(wIRQ));
  WriteCFGRegister(IREG_IRQ_TYPE, IRQTYPE_EDGE );
}


static void ConfigureRAM(BYTE bLogDev, WORD wRAMAddress)
{
  wRAMAddress = (wRAMAddress >> 4) & 0x0FFF;
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_MEMBASEHI, HIBYTE(wRAMAddress));
  WriteCFGRegister(IREG_MEMBASELO, LOBYTE(wRAMAddress));
  WriteCFGRegister(IREG_MEMCONTROL, (MEMTYPE_HIADDR | MEMTYPE_16BIT) );
}

static void WriteLogicalDevice( LDDATA *ld )
{
//  if the device is not active from the .INI, do not
//  configure it. This will prevent the IDE from being reset
//  if it was configured by PINIDE.SYS

  if ( ld->fActive )
  {
    WriteCFGRegister(IREG_LOGDEVICE, ld->bLDNumber);
    ConfigureIO0( ld->bLDNumber , ld->wIOAddr0 );
    ConfigureIO1( ld->bLDNumber , ld->wIOAddr1 );
    ConfigureIRQ( ld->bLDNumber , ld->wIRQ );
    ConfigureRAM( ld->bLDNumber , ld->wRAMAddr );
    ActivateLogicalDevice( ld->bLDNumber );
   }
   else // added by daj
	DisActivateLogicalDevice( ld->bLDNumber );
}

static BOOL VerifyHWExists(void)
{
  BYTE bSaveReg;

  WriteCFGRegister( IREG_LOGDEVICE, 0x00 );
  bSaveReg = ReadCFGRegister(IREG_IO0_BASELO); // save the config value
  WriteCFGRegister( IREG_IO0_BASELO, 0xAA );
  if ( ReadCFGRegister(IREG_IO0_BASELO) != 0xAA )
    return(CFGOP_NOHARDWARE);

  WriteCFGRegister( IREG_IO0_BASELO, 0x55 );
  if ( ReadCFGRegister(IREG_IO0_BASELO) != 0x55 )
    return(CFGOP_NOHARDWARE);
  WriteCFGRegister(IREG_IO0_BASELO,bSaveReg);   // restore the config value

  WriteCFGRegister( IREG_LOGDEVICE, 0x01 );
  bSaveReg = ReadCFGRegister(IREG_IO0_BASELO); // save the config value
  WriteCFGRegister( IREG_IO0_BASELO, 0xAA );
  if ( ReadCFGRegister(IREG_IO0_BASELO) != 0xAA )
    return(CFGOP_NOHARDWARE);

  WriteCFGRegister( IREG_IO0_BASELO, 0x55 );
  if ( ReadCFGRegister(IREG_IO0_BASELO) != 0x55 )
    return(CFGOP_NOHARDWARE);
  WriteCFGRegister(IREG_IO0_BASELO,bSaveReg);   // restore the config value

  return(CFGOP_NOERR);
}

static void WriteCFGData( PPINCFG pData )
{
  int i;
  for ( i=0 ; i < NUM_LOGICAL_DEVICES ; i++ )
    WriteLogicalDevice( &(pData->ld[i]));
}

static void SetHWDefaults( PPINCFG pData )
{
  int i;
  for ( i=0 ; i < NUM_LOGICAL_DEVICES ; i++ )
    {
    pData->ld[i].bLDNumber=i;
    pData->ld[i].fActive=0;
    pData->ld[i].wIOAddr0=0;
    pData->ld[i].wIOAddr1=0;
    pData->ld[i].wIRQ=0;
    pData->ld[i].wRAMAddr=0;
    }
}

#if VERIFY_CFG
void ReadLogicalDevice( LDDATA *ld )
{
  WriteCFGRegister(IREG_LOGDEVICE, ld->bLDNumber);
  ld->fActive = ReadCFGRegister(IREG_ACTIVATE);
  ld->wIOAddr0 = MAKEWORD( ReadCFGRegister(IREG_IO0_BASELO),
                             ReadCFGRegister(IREG_IO0_BASEHI));
  ld->wIOAddr1 = MAKEWORD( ReadCFGRegister(IREG_IO1_BASELO),
                             ReadCFGRegister(IREG_IO1_BASEHI));

  ld->wIRQ = ReadCFGRegister(IREG_IRQ_NUMBER) & 0x00FF;
  ld->wRAMAddr = MAKEWORD( ReadCFGRegister(IREG_MEMBASELO),
                        ReadCFGRegister(IREG_MEMBASEHI) );
}

void ReadCFGData( PPINCFG pData )
{
  int i;
  for ( i=0 ; i < NUM_LOGICAL_DEVICES ; i++ )
    ReadLogicalDevice( &(pData->ld[i]) );
}


#endif


static int configFiji(int configPortAddress,int dspPortAddress,int dspIRQ,int dspRamAddr)
{
  // initialize default values
  PINCFG p;
  wPortAddress = configPortAddress;
  SetHWDefaults(&p);
  if ( VerifyHWExists() )
      {
      return EC_HW_NOTPRESENT;
      }

  /* DSP is logical device 0 */
  p.ld[0].fActive=1;
  p.ld[0].wIOAddr0=dspPortAddress;
  p.ld[0].wIRQ=dspIRQ;
  p.ld[0].wRAMAddr=dspRamAddr;

  // configure the card with the setting in filename
  WriteCFGData(&p);

#if VERIFY_CFG
  {
	PINCFG r;
	int i,errorCount = 0;
	ReadCFGData(&r);
	IOLog("Fiji configuration\n");
  	for ( i=0 ; i < NUM_LOGICAL_DEVICES ; i++ ) {
    		if (p.ld[i].fActive != r.ld[i].fActive) {
			IOLog("CFG error. wrote %x != read %x for device %d fActive\n",
				p.ld[i].fActive,r.ld[i].fActive,i);
			errorCount++;
		} 
    		if (p.ld[i].wIOAddr0 != r.ld[i].wIOAddr0) {
			IOLog("CFG error. wrote %x != read %x for device %d wIOAddr0\n",
				p.ld[i].wIOAddr0,r.ld[i].wIOAddr0,i); 
			errorCount++;
		} 
    		if (p.ld[i].wIOAddr1 != r.ld[i].wIOAddr1) {
			IOLog("CFG error. wrote %x != read %x for device %d wIOAddr1\n",
				p.ld[i].wIOAddr1,r.ld[i].wIOAddr1,i); 
 			errorCount++;
		} 
   		if (p.ld[i].wIRQ != r.ld[i].wIRQ) {
			IOLog("CFG error. wrote %x != read %x for device %d wIRQ\n",
				p.ld[i].wIRQ,r.ld[i].wIRQ,i); 
			errorCount++;
		} 
    		if (p.ld[i].wRAMAddr != r.ld[i].wRAMAddr) {
			IOLog("CFG error. wrote %x != read %x for device %d wRAMAddr\n",
				p.ld[i].wRAMAddr,r.ld[i].wRAMAddr,i); 
			errorCount++;
		} 
	}
	IOLog("CFG check found %d errors\n",errorCount);
  }
#endif

  return EC_NOERR;
}

