#import "DSPObject_stubs.h"

extern int DSPCheckVersion(
    int *sysver,	   /* system version running on DSP (returned) */
    int *sysrev)	   /* system revision running on DSP (returned) */
{
    return 0;
}

int DSPMKBLTTimed(DSPFix48 *timeStamp,
			 DSPMemorySpace memorySpace,
			 DSPAddress sourceAddr,
			 DSPAddress destinationAddr,
			 DSPFix24 wordCount)
{
    return 0;
}

int DSPMKMemoryFillSkipTimed(
    DSPFix48 *aTimeStampP,
    DSPFix24 fillConstant,
    DSPMemorySpace space,
    DSPAddress address,
    int skip,			/* skip factor in DSP memory */
    int count)
{
    return 0;
}

void DSPEnableErrorFile(char *filename)
{
}

int DSPMKSendArraySkipTimed(DSPFix48 *aTimeStampP,
				   DSPFix24 *data,
				   DSPMemorySpace space,
				   DSPAddress address,
				   int skipFactor,
				   int count)
{
    return 0;
}

int DSPWriteIntArray(
    int *intArray,
    DSPMemorySpace memorySpace,
    DSPAddress startAddress,
    int skipFactor,
    int wordCount)
{
    return 0;
}

int DSPMKSendLongTimed(DSPFix48 *aTimeStampP, 
			      DSPFix48 *aFix48Val,
			      int addr)
{
    return 0;
}

int DSPMKSendValueTimed(DSPFix48 *aTimeStampP,
			       int value,
			       DSPMemorySpace space,
			       int addr)
{
    return 0;
}

int DSPReadValue(DSPMemorySpace space,
			DSPAddress address,
			DSPFix24 *value)
{
    return 0;
}

int DSPMKSendShortArraySkipTimed(DSPFix48 *aTimeStampP,
    short int *data,
    DSPMemorySpace space,
    DSPAddress address,
    int skipFactor,
    int count)
{
    return 0;
}

int _DSPMKSendUnitGeneratorWithLooperTimed(
    DSPFix48 *aTimeStampP, 
    DSPMemorySpace space,
    DSPAddress address,
    DSPFix24 *data,		/* DSP gets rightmost 24 bits of each word */
    int count,
    int looperWord)
{
    return 0;
}

int _DSPReloc(DSPDataRecord *data, DSPFixup *fixups,
    int fixupCount, int *loadAddresses)
{
    return 0;
}

int _DSPError1(
    int errorcode,
    char *msg,
    char *arg)
{
    return 0;
}


int _DSPError(
    int errorcode,
    char *msg)
{
    return 0;
}

FILE *DSPGetSimulatorFP(void)
{
    return 0;
}


char **DSPGetDriverNames(void)
{
return 0;
}


char **DSPGetInUseDriverNames(void)
{
return 0;
}


char *DSPGetDriverParameter(const char *parameterName)
{
return 0;
}


const char *DSPMemoryNames(int memSpaceNo)
{
return 0;
}

  /* Memory spaces (N,X,Y,L,P) */
 DSPAddress DSPGetHighestExternalUserAddress(void)
{
return 0;
}


DSPAddress DSPGetHighestExternalUserPAddress(void)
{
return 0;
}


 DSPAddress DSPGetHighestExternalUserXAddress(void)
{
return 0;
}


 DSPAddress DSPGetHighestExternalUserYAddress(void)
{
return 0;
}


 DSPAddress DSPGetLowestExternalUserAddress(void)
{
return 0;
}


 DSPAddress DSPGetLowestExternalUserPAddress(void)
{
return 0;
}


 DSPAddress DSPGetLowestExternalUserXAddress(void)
{
return 0;
}


 DSPAddress DSPGetLowestExternalUserYAddress(void)
{
return 0;
}


 double DSPFix48ToDouble(register DSPFix48 *aFix48P)
{
return 0;
}


int	DSPLCtoMS[DSP_LC_NUM] = {0,1,1,1,2,2,2,3,3,3,4,4,4};

int DSPBoot(DSPLoadSpec *system)
{
return 0;
}


 int DSPBootFile(char *fn)
{
return 0;
}


 int DSPClose(void)
{
return 0;
}


 int DSPCloseCommandsFile(DSPFix48 *endTimeStamp)
{
return 0;
}


 int DSPCloseErrorFP(void)
{
return 0;
}


 int DSPCloseSaveState(void)
{
return 0;
}


 int DSPCloseSimulatorFile(void)
{
return 0;
}


 int DSPCloseWhoFile(void)
{
return 0;
}


 int DSPCopyLoadSpec(DSPLoadSpec **dspPTo,DSPLoadSpec *dspFrom)
{
return 0;
}

int	 DSPErrorNo = 0;	/* Last DSP error */

 int DSPGetDSPCount(void)
{
return 0;
}


 int DSPGetSystemSymbolValueInLC(char *name, DSPLocationCounter lc)
{
return 0;
}


 int DSPHostMessage(int msg)
{
return 0;
}


 int DSPIsSavingCommands(void)
{
return 0;
}


 int DSPIsSavingCommandsOnly(void)
{
return 0;
}


 int DSPLoadSpecFree(DSPLoadSpec *dsp)
{
return 0;
}


 int DSPMKAwaitEndOfTime(DSPFix48 *aTimeStampP)
{
return 0;
}


 int DSPMKCallTimedV(DSPFix48 *aTimeStampP,int hm_opcode,int nArgs,...)
{
return 0;
}


 int DSPMKDisableAtomicTimed(DSPFix48 *aTimeStampP)
{
return 0;
}


 int DSPMKDisableBlockingOnTMQEmptyTimed(DSPFix48 *aTimeStampP)
{
return 0;
}


 int DSPMKEnableAtomicTimed(DSPFix48 *aTimeStampP)
{
return 0;
}


 int DSPMKEnableBlockingOnTMQEmptyTimed(DSPFix48 *aTimeStampP)
{
return 0;
}


 int DSPMKEnableReadData(void)
{
return 0;
}


 int DSPMKEnableSSIReadData(void)
{
return 0;
}


 int DSPMKEnableSSISoundOut(void)
{
return 0;
}


 int DSPMKEnableSmallBuffers(void)
{
return 0;
}


 int DSPMKEnableSoundOut(void)
{
return 0;
}


 int DSPMKEnableWriteData(void)
{
return 0;
}


 int DSPMKFlushTimedMessages(void)
{
return 0;
}


 int DSPMKFreezeOrchestra(void)
{
return 0;
}


 int DSPMKPauseOrchestra(void)
{
return 0;
}


 int DSPMKPauseOrchestraTimed(DSPFix48 *aTimeStampP)
{
return 0;
}


 int DSPMKPauseReadDataTimed(DSPTimeStamp *aTimeStampP)
{
return 0;
}

 
extern int DSPMKReadTime(DSPFix48 *dspTime)
{
return 0;
}


int DSPMKResumeOrchestra(void)
{
return 0;
}


int DSPMKResumeReadDataTimed(DSPTimeStamp *aTimeStampP)
{
return 0;
}


int DSPMKSendValue(int value, DSPMemorySpace space, int addr)
{
return 0;
}


int DSPMKSetReadDataFile(const char *fn)
{
return 0;
}


int DSPMKSetSamplingRate(double srate)
{
return 0;
}


int DSPMKSetUserWriteDataFunc(DSPMKWriteDataUserFunc userFunc)
{
return 0;
}


int DSPMKSetWriteDataFile(const char *fn)
{
return 0;
}


int DSPMKStartReadDataTimed(DSPTimeStamp *aTimeStampP)
{
return 0;
}


int DSPMKStartReaders(void)
{
return 0;
}


int DSPMKStartSSIReadData(void)
{
return 0;
}


int DSPMKStartSoundOut(void)
{
return 0;
}


int DSPMKStartWriteDataTimed(DSPTimeStamp *aTimeStampP)
{
return 0;
}


int DSPMKStopMsgReader(void)
{
return 0;
}


int DSPMKThawOrchestra(void)
{
return 0;
}


int DSPOpenCommandsFile(const char *fn)
{
return 0;
}


int DSPOpenSimulatorFile(char *fn)
{
return 0;
}

			
int DSPReadFile(DSPLoadSpec **dsppp, const char *fn)
{
return 0;
}


int DSPReboot(DSPLoadSpec *system)
{
return 0;
}


int DSPSetCurrentDSP(int newidsp)
{
return 0;
}


int DSPSetSystem(DSPLoadSpec *system)
{
return 0;
}


int DSPSetTimedZeroNoFlush(int yesOrNo)
{
return 0;
}


int DSPStartAtAddress(DSPAddress startAddress)
{
return 0;
}


int DSPWriteSCI(unsigned char value, DSPSCITXReg reg)
{
return 0;
}

int DSPWriteValue(int value, DSPMemorySpace space, int addr)
{
return 0;
}

int _DSPRelocate()
{
return 0;
}


int _DSPRelocateUser()
{
return 0;
}


int *DSPGetDriverSubUnits(void)
{
return 0;
}


int *DSPGetDriverUnits(void)
{
return 0;
}


int *DSPGetInUseDriverSubUnits(void)
{
return 0;
}


int *DSPGetInUseDriverUnits(void)
{
return 0;
}


int DSPGetDriverCount(void)
{
return 0;
}

int _DSPErrorV(int errorcode,char *fmt,...)
{
return 0;
}


int _DSPHostMessageTimed(DSPFix48 *aTimeStampP, int msg)
{
return 0;
}


