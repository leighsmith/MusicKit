#import <stdlib.h>
#import <stdio.h>
#import <mach/mach.h>		/* Needed by _DSPObject.h */
#import "DSPObject.h"
#import "dspreg.h"
#import "_dsp.h"
#import "_DSPObject.h"
#import <objc/hashtable.h>

#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

static NSDictionary *DSPDefaults = nil;
static NSUserDefaults *ourDefaults = nil;

#if 0
static NXDefaultsVector DSPDefaults = {
#if i386
    {"DSP0", NULL},
    {"DSP1", NULL},
    {"DSP2", NULL},
    {"DSP3", NULL},
    {"DSP4", NULL},
    {"DSP5", NULL},
    {"DSP6", NULL},
    {"DSP7", NULL},
    {"DSP8", NULL},
    {"DSP9", NULL},
    {"DSP10", NULL},
    {"DSP11", NULL},
    {"DSP12", NULL},
    {"DSP13", NULL},
    {"DSP14", NULL},
    {"DSP15", NULL},
    {"DSP16", NULL},
    {"DSP17", NULL},
    {"DSP18", NULL},
    {"DSP19", NULL},
    {"DSP20", NULL},
    {"DSP21", NULL},
    {"DSP22", NULL},
    {"DSP23", NULL},
    {"DSP24", NULL},
    {"DSP25", NULL},
    {"DSP26", NULL},
    {"DSP27", NULL},
    {"DSP28", NULL},
    {"DSP29", NULL},
    {"DSP30", NULL},
    {"DSP31", NULL},
#endif
    {"DSPErrorFile", NULL},
    {"DSPTrace", NULL},      /* Integer */
    {"DSPVerbose", NULL},    /* Integer */
    {NULL}
};
#endif

void _DSPInitDefaults(void)
{
    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];
    NSString *s;
    static int defaultsInited = 0;
    ourDefaults = [NSUserDefaults standardUserDefaults];
    if (DSPDefaults == nil) DSPDefaults =  [[NSDictionary dictionaryWithObjectsAndKeys:
#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
    @"",@"DSP0",
    @"",@"DSP1",
    @"",@"DSP2",
    @"",@"DSP3",
    @"",@"DSP4",
    @"",@"DSP5",
    @"",@"DSP6",
    @"",@"DSP7",
    @"",@"DSP8",
    @"",@"DSP9",
    @"",@"DSP10",
    @"",@"DSP11",
    @"",@"DSP12",
    @"",@"DSP13",
    @"",@"DSP14",
    @"",@"DSP15",
    @"",@"DSP16",
    @"",@"DSP17",
    @"",@"DSP18",
    @"",@"DSP19",
    @"",@"DSP20",
    @"",@"DSP21",
    @"",@"DSP22",
    @"",@"DSP23",
    @"",@"DSP24",
    @"",@"DSP25",
    @"",@"DSP26",
    @"",@"DSP27",
    @"",@"DSP28",
    @"",@"DSP29",
    @"",@"DSP30",
    @"",@"DSP31",
#endif
    @"",@"DSPErrorFile",
    @"",@"DSPTrace",      /* Integer */
    @"",@"DSPVerbose",    /* Integer */
    NULL,NULL] retain];

    if (defaultsInited)
      return;
    defaultsInited = 1;
    [ourDefaults registerDefaults:DSPDefaults];
//    NXRegisterDefaults("MusicKit", DSPDefaults);
//    s = NXGetDefaultValue("MusicKit","DSPErrorFile");
    s = [ourDefaults objectForKey:@"DSPErrorFile"];
    if (!s)
      return;
    if (![s length]) return;
    if (DSPEnableErrorFile([s cString]))
      return;
//    s = NXGetDefaultValue("MusicKit","DSPTrace");
    s = [ourDefaults objectForKey:@"DSPTrace"];
    if ([s length])
      _DSPTrace = [s intValue];
//    s = NXGetDefaultValue("MusicKit","DSPVerbose");
    s = [ourDefaults objectForKey:@"DSPVerbose"];
    if (s)
      _DSPVerbose = [s intValue];
    [pool release];
}

#if !m68k && (defined(NeXT) || (defined(__APPLE__) && defined(__MACH__)))
/* This is the Objective-C portion of DSPObject.
 * It should be eventually merged with DSPObject.c.
 */
#import <objc/objc.h>
#import <objc/NXBundle.h>
#import <bsd/sys/param.h>
#import <driverkit/IOConfigTable.h>
#import <driverkit/IODeviceMaster.h>
#import <driverkit/IODevice.h>

/* Arrays indexed by driver number (arbitary).  
   Size is dspDriverCount */
/*sb: decided to leave as char* */
static char **dspDriverNames = NULL;
static float *dspDriverVersions = NULL;
static int *dspDriverUnits = NULL;
static int *dspDriverSubUnits = NULL;
static unsigned long *dspDriverSUVects = NULL;
static int dspDriverCount = 0;

/* Arrays indexed by DSP number (specified by
   user) */
static char **inUseDriverNames = NULL;
static int *inUseDriverUnits = NULL;
static float *inUseDriverVersions = NULL;
static int *inUseDriverSubUnits = NULL;

static void initIntelBasedDSPs(void)
{
    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];
    char *s;
    List *installedDrivers,*dspDriverList;
    id *inUseDriverArray;
    id aConfigTable;
    BOOL foundIt,foundOne;
    char *defaultsValue;
    unsigned long myBit;
#define MAX_DSP_STR 8 /* "DSP"+<up to 3 digits>+NULL */
#define MAX_CARD_INSTANCE_DIGITS 3
#define MAX_DRIVER_NAME 128
    char dspNumStrArr[MAX_DSP_STR];
    char driverStrArr[MAX_CARD_INSTANCE_DIGITS+MAX_DRIVER_NAME+1];
    unsigned int    count = IO_MAX_PARAMETER_ARRAY_LENGTH;
    IOObjectNumber  tag;
    IOString        kind;
    IOCharParameter value;
    IODeviceMaster *devMaster;
    IOReturn        ret;
    int i,j,len;
    static BOOL driverInfoInitialized = NO;
    if (driverInfoInitialized) { /* Already initialized */
      {[pool release];return;}
    } else driverInfoInitialized = YES;
    _DSPInitDefaults();
    [ourDefaults registerDefaults:DSPDefaults];/*sb: to initialize backup defaults */

    installedDrivers = [IOConfigTable tablesForInstalledDrivers];
    /* Creates, if necessary, and returns IOConfigTables, one for each
       device that has been loaded into the system.  This method knows only
       about those devices that are specified with the system configuration
       table's InUse Drivers and Boot Drivers keys.  It does not detect
       drivers that were loaded due to user action at boot time.  To get
       the IOConfigTables for those drivers, you can use
       tablesForBootDrivers.
       */
    dspDriverList = [[List alloc] init];
    /* Get DSP drivers */
    for (i=0; i<[installedDrivers count]; i++) {
        /* Each driver */
        aConfigTable = [installedDrivers objectAt:i];
        if (!strcmp([aConfigTable valueForStringKey:"Family"],"DSP"))
          [dspDriverList addObject:aConfigTable];
    }
//    [installedDrivers free]; /* Doc is unclear about whether we should do this */
    dspDriverCount = [dspDriverList count];
    if (!dspDriverCount == 0) {
	dspDriverNames = (char **)malloc(sizeof(char *)*dspDriverCount);
	dspDriverUnits = (int *)malloc(sizeof(int)*dspDriverCount);
	dspDriverVersions = (float *)malloc(sizeof(float)*dspDriverCount);
	dspDriverSubUnits = (int *)malloc(sizeof(int)*dspDriverCount);
	dspDriverSUVects = 
	  (unsigned long *)calloc(dspDriverCount,sizeof(unsigned long));
    }
    devMaster = [IODeviceMaster new];
    for (i=0; i<dspDriverCount; i++) {
        /* Or "Server Name"? */
        aConfigTable = [dspDriverList objectAt:i];
        dspDriverNames[i] = (char *)[aConfigTable valueForStringKey:"Class Names"];
        s = (char *)[aConfigTable valueForStringKey:"Instance"];
        dspDriverUnits[i] = s ? atoi(s) : 0;
        s = (char *)[aConfigTable valueForStringKey:"Version"];
        dspDriverVersions[i] = s ? atof(s) : 0;
	sprintf(driverStrArr, "%s%d", dspDriverNames[i], dspDriverUnits[i]);
	ret = [devMaster lookUpByDeviceName:driverStrArr objectNumber:&tag 
	     deviceKind:&kind];
	if (ret == IO_R_SUCCESS) { 
	    ret = [devMaster getCharValues:value 
		 forParameter:DSPDRIVER_PAR_SUBUNITS objectNumber:tag
		 count:&count];
	    if (ret != IO_R_SUCCESS)  
	      dspDriverSubUnits[i] = 1;
	    else 
	      dspDriverSubUnits[i] = atoi(value);
	} else /* Reality failure */
	  dspDriverSubUnits[i] = 1;
    }

    /************ Now see which of these are in use, as requested by user *****\
/
    /* We keep the defaults in the form:
     * DSP0=ArielPC56d0, DSP1=Multisound2, DSP3=ArielPC56d1, ...
     * Note that there may be 'holes'.
     * For sub-units, they appear as, e.g.:
     * DSP4=Frankenstein0-2  (this means the second sub-unit of Frankenstein0)
     */
    inUseDriverArray = calloc(DSP_MAXDSPS,sizeof(id));
    inUseDriverNames = (char **)calloc(DSP_MAXDSPS,sizeof(char *));
    inUseDriverUnits = (int *)calloc(DSP_MAXDSPS,sizeof(int));
    inUseDriverSubUnits = (int *)calloc(DSP_MAXDSPS,sizeof(id));
    inUseDriverVersions = (float *)calloc(DSP_MAXDSPS,sizeof(float));
    foundOne = 0;
    for (i=0; i<DSP_MAXDSPS; i++) {
        sprintf(dspNumStrArr,"DSP%d",i);
        if (!(defaultsValue = (char *)
/*              NXGetDefaultValue("MusicKit",(const char *)dspNumStrArr))) */
	        [[ourDefaults objectForKey:[NSString stringWithCString:dspNumStrArr]] cString]))

          continue;
        if (!(*defaultsValue)) continue;
        foundIt = 0;
        for (j=0; j<dspDriverCount && !foundIt; j++) {
            sprintf(driverStrArr,"%s%d",dspDriverNames[j],dspDriverUnits[j]);
	    len = strlen(driverStrArr);
            if (strncasecmp(driverStrArr,defaultsValue,len) == 0) {
		foundIt = 1;
		if (len == strlen(defaultsValue))
		  inUseDriverSubUnits[i] = 0;
		else { /* Subunit is of form <driver><unit>-<subunit> */
		    inUseDriverSubUnits[i] = atoi(&(defaultsValue[len+1]));
		    if (inUseDriverSubUnits[i] >= dspDriverSubUnits[j]) {
			/* Bogus value */
			inUseDriverSubUnits[i] = 0;
                        fprintf(stderr,"Music Kit: %s specifies a non-existant sub-unit.\nRemoving stale default value.\n",defaultsValue);
//                        NXRemoveDefault("MusicKit",(const char *)dspNumStrArr);
	        	  [ourDefaults removeObjectForKey:[NSString stringWithCString:dspNumStrArr]];

			continue;
		    }
		}
		myBit = (1<<inUseDriverSubUnits[i]);
		if (dspDriverSUVects[j] & myBit) {
                    fprintf(stderr,"Music Kit: %s is assigned to more than one DSP index.\nRemoving stale default value.\n",defaultsValue);
//                    NXRemoveDefault("MusicKit",(const char *)dspNumStrArr);
	        [ourDefaults removeObjectForKey:[NSString stringWithCString:dspNumStrArr]];

		    continue;
		}
		dspDriverSUVects[j] |= myBit;
		inUseDriverArray[i] = [dspDriverList objectAt:j];
		inUseDriverNames[i] = dspDriverNames[j];
		inUseDriverUnits[i] = dspDriverUnits[j];
		inUseDriverVersions[i] = dspDriverVersions[j];
		foundOne = 1;
	    }
	}
        if (!foundIt) {
            fprintf(stderr,"Music Kit: %s not found. Removing stale default value.\n",
		    defaultsValue);
//            NXRemoveDefault("MusicKit",(const char *)dspNumStrArr);
	        [ourDefaults removeObjectForKey:[NSString stringWithCString:dspNumStrArr]];

        }
    }
    /* If the users's data base doesn't have anything or we couldn't
       find anything, use the first one we have. */
    if (!foundOne && (dspDriverCount != 0)) {
	inUseDriverArray[0] = [dspDriverList objectAt:0];
	inUseDriverNames[0] = dspDriverNames[0];
	inUseDriverUnits[0] = dspDriverUnits[0];
	inUseDriverVersions[0] = dspDriverVersions[0];
	inUseDriverSubUnits[0] = 1;
	dspDriverSUVects[0] = 1;
    }
    [dspDriverList free];
    if (dspDriverCount != 0)
      for (i=0; i<DSP_MAXDSPS; i++)
        _DSPAddIntelBasedDSP(inUseDriverNames[i],inUseDriverUnits[i],
                             inUseDriverSubUnits[i],inUseDriverVersions[i]);
    else
      for (i=0; i<DSP_MAXDSPS; i++)
        _DSPAddIntelBasedDSP(NULL,0,0,0.0);
    free((void *)inUseDriverArray);
    [pool release];
}

#define MAX_DRIVER_PARAMETER_NAME_LENGTH 80

static char *getDriverParameter(char *parameterName)
{
    NSAutoreleasePool *pool =[[NSAutoreleasePool alloc] init];
    IOReturn        ret;
    IOObjectNumber  tag;
    IOString        kind;
    IOCharParameter value;
    unsigned int    count = IO_MAX_PARAMETER_ARRAY_LENGTH;
    char            name[MAX_DRIVER_PARAMETER_NAME_LENGTH];
    char           *driverName;
    int             unit;
    IODeviceMaster *devMaster;
    int             dspIndex = DSPGetCurrentDSP();
    driverName = inUseDriverNames[dspIndex];
    unit = inUseDriverUnits[dspIndex];
    if (!driverName)
      {[pool release];return NULL;}
    devMaster = [IODeviceMaster new];
    sprintf(name, "%s%d", driverName, unit);
    ret = [devMaster lookUpByDeviceName:name objectNumber:&tag 
	 deviceKind:&kind];
    if (ret != IO_R_SUCCESS) {
      {[pool release];return NULL;}
    } else { /* Successfully got the object number */
      /* Get the value of the driver's parameter. */
      ret = [devMaster getCharValues:value 
           forParameter:parameterName objectNumber:tag
           count:&count];
      if (ret != IO_R_SUCCESS) {
        {[pool release];return NULL;}
    } else /* Successfully got the parameter value */
      {[pool release];return (char *)NXUniqueString(value);}
    }
    [pool release];
  }


void _DSPAddIntelBasedDSPs(void)
{
    initIntelBasedDSPs();
}

char **DSPGetDriverNames(void)
{
    initIntelBasedDSPs();
    return dspDriverNames;
}

int *DSPGetDriverUnits(void)
{
    initIntelBasedDSPs();
    return dspDriverUnits;
}

int *DSPGetDriverSubUnits(void)
{
    initIntelBasedDSPs();
    return dspDriverSubUnits;
}

unsigned long *DSPGetDriverSUVects(void)
{
    initIntelBasedDSPs();
    return dspDriverSUVects;
}

int DSPGetDriverCount(void)
{
    initIntelBasedDSPs();
    return dspDriverCount;
}

char **DSPGetInUseDriverNames(void)
{
    initIntelBasedDSPs();
    return inUseDriverNames;
}

int *DSPGetInUseDriverUnits(void)
{
    initIntelBasedDSPs();
    return inUseDriverUnits;
}

int *DSPGetInUseDriverSubUnits(void)
{
    initIntelBasedDSPs();
    return inUseDriverSubUnits;
}

char *DSPGetDriverParameter(const char *parameterName)
{
    initIntelBasedDSPs();
    return getDriverParameter((const char *)parameterName);
}

#else
/* Dummys */

char *DSPGetDriverParameter(const char *parameterName) { return NULL; }
int DSPGetDriverCount(void) { return 0; }
char **DSPGetDriverNames(void) { return NULL; }
int *DSPGetDriverUnits(void) { return NULL; }
int *DSPGetDriverSubUnits(void) { return NULL; }
unsigned long *DSPGetDriverSUVects(void) { return NULL; }
char **DSPGetInUseDriverNames(void) { return NULL; }
int *DSPGetInUseDriverUnits(void) { return NULL; }
int *DSPGetInUseDriverSubUnits(void) { return NULL; }

#endif



