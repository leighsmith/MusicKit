/************************************************************************
 *    MultiSound Pinnacle/Fiji Configuration Utility
 *
 *    This utility is used to configure the MultiSound Pinnacle
 *    card in a non-Plug and Play environment. The utility reads the
 *    data from a .INI format file. The values are programmed by
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
 *    See the Plug and Play documentation for the location of the
 *    various registers.
 *
 *    Copyright 1996  Turtle Beach Systems Inc., All rights reserved.
 *
 *
 * **********************************************************************/

#include <stdio.h>
#include "pincfg.h"
#include "cm.h"
#include "ca.h"
#include "eewrite.h"

// global variables
WORD wPortAddress;
//WORD wConfigMode;
char buf[80];

// register functions
void WriteCFGRegister(WORD wRegister, BYTE bValue )
{
  outp(wPortAddress, wRegister);
  outp(wPortAddress+1, bValue);
}

BYTE ReadCFGRegister(WORD wRegister)
{
  outp(wPortAddress, wRegister);
  return(inp(wPortAddress+1));
}

void ActivateLogicalDevice( BYTE bLogDev )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev );
  WriteCFGRegister(IREG_ACTIVATE, LD_ACTIVATE );
}

void ConfigureIO0(BYTE bLogDev, WORD wIOAddress )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_IO0_BASEHI, HIBYTE(wIOAddress));
  WriteCFGRegister(IREG_IO0_BASELO, LOBYTE(wIOAddress));
}

void ConfigureIO1(BYTE bLogDev, WORD wIOAddress )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_IO1_BASEHI, HIBYTE(wIOAddress));
  WriteCFGRegister(IREG_IO1_BASELO, LOBYTE(wIOAddress));
}

void ConfigureIRQ(BYTE bLogDev, WORD wIRQ )
{
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_IRQ_NUMBER, LOBYTE(wIRQ));
  WriteCFGRegister(IREG_IRQ_TYPE, IRQTYPE_EDGE );
}


void ConfigureRAM(BYTE bLogDev, WORD wRAMAddress)
{
  wRAMAddress = (wRAMAddress >> 4) & 0x0FFF;
  WriteCFGRegister(IREG_LOGDEVICE, bLogDev);
  WriteCFGRegister(IREG_MEMBASEHI, HIBYTE(wRAMAddress));
  WriteCFGRegister(IREG_MEMBASELO, LOBYTE(wRAMAddress));
  WriteCFGRegister(IREG_MEMCONTROL, (MEMTYPE_HIADDR | MEMTYPE_16BIT) );
}

void WriteLogicalDevice( LDDATA *ld )
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
}

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

BOOL VerifyHWExists(void)
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


// screen print functions
void PrintStr( char *string )
{
  printf(string);
}


// plug and play interface functions
// These functions are used to talk to the Pinnacle through a configuration manager
// when the card is in plug and play mode.

BOOL CAPresent(void)
{
  WORD wVersion;
  if ( _CA_GetVersion( &wVersion ) == CA_SUCCESS )
    return(TRUE);
  else
    return(FALSE);
}

BOOL CMPresent(void)
{
  WORD wVersion;
  if ( _CA_GetVersion( &wVersion ) == CA_SUCCESS )
    return(TRUE);
  else
    return(FALSE);
}

BOOL PnPPresent(void)
{
  return( CMPresent() && CAPresent() );
}

WORD TBSCardConfigured(void)
{
  Config_Info ci;
  WORD wDevIndex = 0;

  if ( !PnPPresent() )
    return(CM_CONFIG_MGR_NOT_PRESENT);

  while ( _CM_GetConfig( wDevIndex, &ci ) != CM_DEVICE_NOT_FOUND )
    {
    if ( ci.sDeviceId.dDevID == TBS_PINNACLE_PNPID )
      return(MAKEWORD(TRUE,ci.uBusAccess.sPnPAccess.bCSN));
    wDevIndex++;
    }

  return(FALSE);
}

WORD GetPnPReadPort(void)
{
  Config_Info ci;
  WORD wDevIndex=0;
  while ( _CM_GetConfig( wDevIndex++, &ci ) != CM_DEVICE_NOT_FOUND )
    {
    if ( ci.sDeviceId.dDevID == TBS_PINNACLE_PNPID )
      return(ci.uBusAccess.sPnPAccess.wReadDataPort);
    }
  return(CFGOP_NOREADPORT);
}

WORD ReadPnPConfig( BYTE bCSN, PPINCFG pData )
{
  Config_Info ci;
  WORD wDevIndex = 0;
  WORD wLogDev;

  ci.uBusAccess.sPnPAccess.bLogicalDevNumber = 0x00;
  ci.wIOPort_Base[0] = 0x00;
  ci.wIOPort_Base[1] = 0x00;
  ci.bIRQRegisters[0] = 0x00;
  ci.dMemBase[0] = 0x00;

  while ( _CM_GetConfig( wDevIndex++, &ci ) != CM_DEVICE_NOT_FOUND )
    {
    if ( ci.uBusAccess.sPnPAccess.bCSN == bCSN )
      {
      wLogDev=ci.uBusAccess.sPnPAccess.bLogicalDevNumber;
      pData->ld[wLogDev].bLDNumber = wLogDev;
      pData->ld[wLogDev].fActive = 1;
      pData->ld[wLogDev].wIOAddr0 = ci.wIOPort_Base[0];
      if ( ci.wNumIOPorts > 1 )
        pData->ld[wLogDev].wIOAddr1 = ci.wIOPort_Base[1];
      if ( ci.wNumIRQs > 0 )
        pData->ld[wLogDev].wIRQ = MAKEWORD(ci.bIRQRegisters[0],0x00);
      if ( ci.wNumMemWindows > 0 )
        pData->ld[wLogDev].wRAMAddr = LOWORD( ci.dMemBase[0] >> 4 );
      ci.uBusAccess.sPnPAccess.bLogicalDevNumber = 0x00;
      ci.wIOPort_Base[0] = 0x00;
      ci.wIOPort_Base[1] = 0x00;
      ci.bIRQRegisters[0] = 0x00;
      ci.dMemBase[0] = 0x00;
      }
    }
}

void WritePnPConfig( BYTE bCSN, PPINCFG pData )
{
  BYTE bLogDev = 0;
  BYTE bReg;

  for ( bLogDev=0 ; bLogDev<NUM_LOGICAL_DEVICES ; bLogDev++ )
    {
    bReg=HIBYTE(pData->ld[bLogDev].wIOAddr0);
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_IO0_BASEHI, 1, &bReg );
    bReg=LOBYTE(pData->ld[bLogDev].wIOAddr0);
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_IO0_BASELO, 1, &bReg );
    bReg=HIBYTE(pData->ld[bLogDev].wIOAddr1);
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_IO1_BASEHI, 1, &bReg );
    bReg=LOBYTE(pData->ld[bLogDev].wIOAddr1);
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_IO1_BASELO, 1, &bReg );
    bReg=LOBYTE(pData->ld[bLogDev].wIRQ);
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_IRQ_NUMBER, 1, &bReg );
    bReg=IRQTYPE_EDGE;
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_IRQ_TYPE, 1, &bReg );
    bReg=HIBYTE(pData->ld[bLogDev].wRAMAddr);
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_MEMBASEHI, 1, &bReg );
    bReg=LOBYTE(pData->ld[bLogDev].wRAMAddr);
    _CA_PnPISA_Write_Config_Byte( bCSN, bLogDev, IREG_MEMBASELO, 1, &bReg );
    bReg=(MEMTYPE_HIADDR | MEMTYPE_16BIT);
    }
}

// EEPROM functions


WORD WriteEEData(char *szEEDataFileName, WORD wReadPort, WORD wWritePort)
{
  FILE *fEEData;
  char pDataBuffer[EE_DATA_SIZE];
  WORD wTemp, wDataSize;

  if ( (fEEData = fopen( szEEDataFileName , "rb" ) ) == NULL )
    {
    printf("\nERROR: Could not open input file %s\n",szEEDataFileName);
    return(EC_BADFILENAME);
    }

  wDataSize = fread( pDataBuffer, sizeof(BYTE), EE_DATA_SIZE, fEEData);

  if ( wDataSize < EE_DATA_SIZE )
    for ( wTemp = wDataSize ; wTemp <  EE_DATA_SIZE ; wTemp++ )
      *(pDataBuffer+wTemp) = 0x0000;
//      *(pDataBuffer+wTemp) = 0xFFFF;

  printf("Writing file %s to EEPROM...",szEEDataFileName);

  if ( wTemp = WriteEEPROMData(wReadPort, wWritePort,pDataBuffer,wDataSize) )
  {
    printf("FAILED\nERROR: Write failed at offset %X\n\n",HIBYTE(wTemp));
    return(EC_EEWRITEFAIL);
  }

  printf("OK\nVerifying file %s to EEPROM...",szEEDataFileName);

  if ( wTemp = VerifyEEPROMData(wReadPort, wWritePort,pDataBuffer,wDataSize) )
  {
    printf("FAILED\nERROR: Verify failed at offset %X\n\n",HIBYTE(wTemp));
    return(EC_EEVERIFYFAIL);
  }
  printf("OK\n");

  return(EC_NOERR);
}


// file i/o and .ini operations
char *deblank(char *ptr)
{  char *p;

	p = ptr;
	while((*p == ' ') || (*p == '\t') && (*p != 0))
		p++;
	return(p);
}

WORD TextToHex( char *buf )
{
  char  c;
  WORD  n=0;
  char *p;
  p=buf;

  while (isxdigit(*p))
    {
    c = *p++;
    if (c > 'Z') c -= 'a' - 'A';
    c -= '0';
    if (c > 9) c -= 7;
    n = n * 16 + c;
    }
  return n;
}

WORD ReadINIFile( char *filename, PPINCFG pData )
{
  FILE *fpINI;
  char szINIBuffer[BUFLEN];
  char szCmdName[BUFLEN], *szINILine;
  int nEQOffset;
  int nLogicalDevice = LDEVICE_UNDEFINED;

  if ( (fpINI = fopen( filename , "rt" ) ) == NULL )
    return(CFGOP_BADFILENAME);

  while ( !feof(fpINI) )
    {
    int nStrLength;
    fgets (szINIBuffer, BUFLEN, fpINI);

    szINILine = deblank(szINIBuffer);
    nStrLength = strlen(szINILine);
    szINILine[nStrLength-1] = 0x0000; // change last char to NULL
    // cases to break on
    if ( szINILine[0] == STR_COMMENT &&
         szINILine[1] == STR_COMMENT )
      {
      // do nothing
      }
    else if ( strcmp( szINILine,STR_CONTROL ) == 0 )
      nLogicalDevice=4;
    else if ( strcmp( szINILine,STR_LD0 ) == 0 )
      nLogicalDevice=0;
    else if( strcmp( szINILine,STR_LD1 ) == 0 )
      nLogicalDevice=1;
    else if( strcmp( szINILine,STR_LD2 ) == 0 )
      nLogicalDevice=2;
    else if( strcmp( szINILine,STR_LD3 ) == 0 )
      nLogicalDevice=3;
    else if (nLogicalDevice != LDEVICE_UNDEFINED )
      {
      nEQOffset = strcspn(szINILine,"=");
      strcpy(szCmdName,szINILine);
      szCmdName[nEQOffset] = 0x00;

      if ( strcmp( szCmdName,STR_ACTIVE ) == 0 )
        pData->ld[nLogicalDevice].fActive=atoi(szINILine+nEQOffset+1);
      else if( strcmp( szCmdName,STR_IOADDRESS0 ) == 0 )
        pData->ld[nLogicalDevice].wIOAddr0=TextToHex(szINILine+nEQOffset+1);
      else if( strcmp( szCmdName,STR_IOADDRESS1 ) == 0 )
        pData->ld[nLogicalDevice].wIOAddr1=TextToHex(szINILine+nEQOffset+1);
      else if( strcmp( szCmdName,STR_IRQ ) == 0 )
        pData->ld[nLogicalDevice].wIRQ=atoi(szINILine+nEQOffset+1);
      else if( strcmp( szCmdName,STR_RAMADDRESS ) == 0 )
        pData->ld[nLogicalDevice].wRAMAddr=TextToHex(szINILine+nEQOffset+1);
      else
        {
        // error case unrecognized ini parameter
        }
      }
    }

  fclose(fpINI);
  return(CFGOP_NOERR);
}

WORD WriteINIFile( char *filename, PPINCFG pData )
{
  FILE *fpINI;
  BOOL fOK;
  int nSize=0;
  int nLine=0;
  int nStrLength, nEQOffset, nLen;
  int nLogicalDevice = LDEVICE_UNDEFINED;
  char * szINIFile[MAX_INIBUFFER_LINES];
  char *szINIBuffer;
  char *szINILine;
  char szCmdName[18];
  char *szCmdValue;

  nSize=BUFLEN*MAX_INIBUFFER_LINES;
  if( ( szINIBuffer=(char far *)calloc( nSize,sizeof(BYTE)))==NULL)
    return(CFGOP_NOMEM);

  if ( (fpINI = fopen( filename , "r+" ) ) == NULL )
    return(CFGOP_BADFILENAME);

  nLine=0;
  while ( !feof(fpINI) )
    {
    szINIFile[nLine]=szINIBuffer+BUFLEN*nLine;
    fgets (szINIFile[nLine], BUFLEN, fpINI);
    nLine++;
    }
//  fclose(fpINI);

  nSize=nLine;
  // update the ini file here
  // search for the key, and then fill it with the value in memory
  for ( nLine = 0 ; nLine < nSize ; nLine++ )
    {
    szINILine = deblank(szINIFile[nLine]);
    nStrLength = strlen(szINILine);
    szINILine[nStrLength-1] = 0x00; // change last char to NULL

    // cases to break on
    if ( szINILine[0] == STR_COMMENT &&
         szINILine[1] == STR_COMMENT )
      {
      // do nothing
      }
    else if ( strcmp( szINILine,STR_CONTROL ) == 0 )
      nLogicalDevice=4;
    else if ( strcmp( szINILine,STR_LD0 ) == 0 )
      nLogicalDevice=0;
    else if( strcmp( szINILine,STR_LD1 ) == 0 )
      nLogicalDevice=1;
    else if( strcmp( szINILine,STR_LD2 ) == 0 )
      nLogicalDevice=2;
    else if( strcmp( szINILine,STR_LD3 ) == 0 )
      nLogicalDevice=3;
    else if (nLogicalDevice != LDEVICE_UNDEFINED )
      {
      nEQOffset = strcspn(szINILine,"=");
      strcpy(szCmdName,szINILine);
      szCmdName[nEQOffset] = 0x00;

      // here we must write the line with the PNP data
      if ( strcmp( szCmdName,STR_ACTIVE ) == 0 )
        {
        fOK = TRUE;
        _itoa(pData->ld[nLogicalDevice].fActive, szCmdValue, 10);
        }
      else if( strcmp( szCmdName,STR_IOADDRESS0 ) == 0 )
        {
        fOK = TRUE;
        _itoa(pData->ld[nLogicalDevice].wIOAddr0, szCmdValue, 16);
        }
      else if( strcmp( szCmdName,STR_IOADDRESS1 ) == 0 )
        {
        fOK = TRUE;
        _itoa(pData->ld[nLogicalDevice].wIOAddr1, szCmdValue, 16);
        }
      else if( strcmp( szCmdName,STR_IRQ ) == 0 )
        {
        fOK = TRUE;
        _itoa(pData->ld[nLogicalDevice].wIRQ, szCmdValue, 10);
        }
      else if( strcmp( szCmdName,STR_RAMADDRESS ) == 0 )
        {
        fOK = TRUE;
        _itoa(pData->ld[nLogicalDevice].wRAMAddr, szCmdValue, 16);
        }
      else
        fOK = FALSE;

      if ( fOK==TRUE )
        {
        nLen = strlen(szCmdName);
        szCmdName[nLen] = 0x3D;
        szCmdName[nLen+1] = 0x00;
        strcat(szCmdName,szCmdValue);
        strcpy(szINILine,szCmdName);
        nStrLength = strlen(szINILine);
        nStrLength++;
        }
      }
    szINILine[nStrLength-1] = 0x0A; // change last char to line feed
    }

  rewind(fpINI);

  for ( nLine = 0 ; nLine < (nSize-1) ; nLine++ )
    {
    fputs ( szINIFile[nLine], fpINI );
    }

  fclose(fpINI);
  free(szINIBuffer);

  return(CFGOP_NOERR);
}

WORD ReadCFGData( PPINCFG pData )
{
  int i;
  for ( i=0 ; i < NUM_LOGICAL_DEVICES ; i++ )
    ReadLogicalDevice( &(pData->ld[i]) );
}

WORD WriteCFGData( PPINCFG pData )
{
  int i;
  for ( i=0 ; i < NUM_LOGICAL_DEVICES ; i++ )
    WriteLogicalDevice( &(pData->ld[i]));
}

void SetHWDefaults( PPINCFG pData )
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


// User Interface functions
void DisplayCFGData( PPINCFG pData )
{
  int i;
  for ( i=0 ; i < (NUM_LOGICAL_DEVICES-1) ; i++ )
    {
    if ( pData->ld[i].fActive )
      {
      printf("LOGICAL DEVICE %d:\n",pData->ld[i].bLDNumber);
      printf("IO Address 0            = %X\n",pData->ld[i].wIOAddr0);
      printf("IO Address 1            = %X\n",pData->ld[i].wIOAddr1);
      printf("IRQ Number              = %d\n",pData->ld[i].wIRQ);
      printf("RAM Address             = %X\n\n",((pData->ld[i].wRAMAddr)<<4));
      }
    }
}

void run_screen(void)
{
   int nInker=0;
   printf("MultiSound Pinnacle(tm) Configuration Utility, Version %s\n",SOFTWARE_VERSION);
   printf("Utility to configure the Pinnacle card.\n");
   while(nInker<78) {
       printf("%c",0xcd);
       nInker++;
   }
   printf("\n");
   printf("(c)1996 Turtle Beach Systems  All Rights Reserved.\n");
}

void help_screen()
{
   run_screen();
   printf("Usage:    PINCFG [/Ffilename | /Lfilename | /D | /O | /?]\n\n");
   printf("          /Ffilename => .INI file containing the desired configuration\n");
   printf("          /D         => Display the current board settings\n");
   printf("          /O         => Override PnP settings with setting in filname\n");
#ifdef DEBUG
   printf("          /T         => Test case for DEBUG functions\n");
#endif
   printf("          /Lfilename => Load the resource data in filename to the board\n");
   printf("          /?         => Display this help screen\n");
   printf("Defaults:\n");
   printf("    filename     = %s\n\n",DEF_CFG_FILE_NAME);
   return;
}

// main routine
main(argc, argv)
int argc;
char *argv[];
{
  // initialize default values
  PINCFG p;
  BYTE bCSN;
  BOOL fPnPPresent=FALSE;
  BOOL fTBSPnPConfig=FALSE;
  BOOL fOverridePnP=FALSE;
  int nParam;
  BYTE bTemp;
  char *szTemp;
  WORD wReadPort, wWritePort;
  WORD wReturn;
  Config_Info sConfigBuffer;
  WORD wOperation=EXE_CONFIGURE;
  char *szEEDataFileName;
  char *szFileName = DEF_CFG_FILE_NAME;
  wPortAddress = DEF_PORT_ADDRESS;

  SetHWDefaults(&p);

  for( nParam = 1 ; nParam < argc ; nParam++ )
  {
    if( *argv[ nParam ] != '/' )
    {
      help_screen();
      printf("\nERROR: Bad command line parameter %s ; no forward slash\n",argv[ nParam ]);
      exit(EC_INVALIDOPTION);
    }
        switch( toupper( *(argv[ nParam ] + 1 ) ) )
        {
//          case 'P' :
//              szTemp = argv[ nParam ] + 2;
//              wPortAddress = TextToHex( szTemp );
//              break;

          case 'F' :
              szFileName = argv[ nParam ] + 2;
              break;

          case 'D' :
              wOperation = EXE_READ;
              break;
#ifdef DEBUG
          case 'T' :
              wOperation = EXE_DEBUG;
              ReadINIFile( szFileName, &p );
              WriteINIFile( "testout.ini", &p);
              exit(0);
              break;
#endif
          case 'L' :
              wOperation = EXE_LOADEEFILE;
              szEEDataFileName = argv[ nParam ] + 2;
              break;

          case 'O' :
              fOverridePnP=TRUE;
              break;

          case '?' :
              help_screen();
              exit(EC_NOERR);
              break;

          default:
              help_screen();
              printf("\nERROR: Bad command line parameter %s\n",argv[ nParam ]);
              exit(EC_INVALIDOPTION);
              break;
          }
  }

  if ( (fPnPPresent=PnPPresent()) == TRUE )
    {
    if (LOBYTE((wReturn=TBSCardConfigured())) == TRUE)
      {
      fTBSPnPConfig=LOBYTE(wReturn);
      bCSN=HIBYTE(wReturn);
      ReadPnPConfig( bCSN, &p );
      }
    }

  if ( fTBSPnPConfig && !fOverridePnP && (wOperation!=EXE_READ) && (wOperation!=EXE_LOADEEFILE))
    {
    run_screen();
    printf("Pinnacle Configured by PnP Manager\n");
    printf("Updating %s\n",szFileName);
    if( WriteINIFile( szFileName, &p ) != CFGOP_NOERR )
      {
      printf("Error writing %s.\n",szFileName);
      exit(EC_BADFILENAME);
      }
    printf("Operation Completed Successfully\n");
    exit(EC_NOERR);
    }

  if ( !fTBSPnPConfig )
    {
    if( ReadINIFile( szFileName, &p ) )
      {
      help_screen();
      printf("\nERROR: Could not open input file %s\n",szFileName);
      exit(EC_BADFILENAME);
      }
    wPortAddress=p.ld[LD_CTRL].wIOAddr0;
    }

  // verify existence of HW
  if( !fTBSPnPConfig && (wOperation!=EXE_LOADEEFILE))
    {
    if ( VerifyHWExists() )
      {
      run_screen();
      printf("\nERROR: Hardware not present at I/O address %Xh\n",wPortAddress);
      exit(EC_HW_NOTPRESENT);
      }
    }

  switch ( wOperation )
  {
    case EXE_LOADEEFILE:
      run_screen();
      if ( fTBSPnPConfig )
        {
        if ( (wReadPort = GetPnPReadPort()) == CFGOP_NOREADPORT )
          {
          printf("\nERROR: Unable to acquire PnP read data port address\n");
          exit(EC_NOREADPORT);
          }
        wWritePort=PNP_WRITEDATA_PORT;
        outp( PNP_WRITEADDR_PORT, IREG_EECONTROL );
        }
      else
        {
        wReadPort=wPortAddress+2;
        wWritePort=wPortAddress+2;
        }

      wReturn = WriteEEData(szEEDataFileName, wReadPort, wWritePort);

      if ( wReturn!=EC_NOERR )
        exit(wReturn);
      break;

    case EXE_CONFIGURE:
      // configure the card with the setting in filename
      if ( fOverridePnP )
        {
        if ( !fTBSPnPConfig )
          {
          run_screen();
          printf("\nERROR: /O option not valid in non-PnP system\n");
          exit(EC_INVALIDOPTION);
          }
        else
          {
          run_screen();
          WritePnPConfig( bCSN, &p );
          printf("Updating card configuration with data in %s\n",szFileName);
          }
        }
      else
        {
        WriteCFGData(&p);
        run_screen();
        }
      break;

    case EXE_READ:
      // read the config regs and display the current configuration
      if ( !fTBSPnPConfig )
        ReadCFGData( &p );
      run_screen();
      DisplayCFGData( &p );

      break;

#ifdef DEBUG
    case EXE_DEBUG:
      // compare verify pHW + pINI
      ReadCFGData( &p );
      run_screen();
      printf("OK\n");
      break;
#endif

    default:
      break;
  }

  printf("Operation completed successfully\n");
  exit(EC_NOERR);
}

