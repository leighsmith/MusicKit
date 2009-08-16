/* Music Kit Preferences panel. 
   (c) 1994 Stanford University

   David A. Jaffe

   Modification History:

   10/10/94/daj - created.
   10/15/94/daj - changed to always read OrchestraSoundOut from defaults

*/


#import <AppKit/AppKit.h>
#import <ansi/ctype.h>

#import "MusicKitPrefs.h"

@implementation MusicKitPrefs
  
+ new
  /*
    Called first time this section's button is clicked.
    */
{
    MusicKitPrefs *newObj = [super new];
    
#if i386
#define FILE_NAME "MKPrefs_intel"
#else
#define FILE_NAME "MKPrefs_next"
#endif
    
    if( ![NXApp loadNibForLayout: FILE_NAME owner: newObj] )
      return 0;
    
    // 'window' is an interface builder outlet.
    newObj->view = [newObj->window contentView];// 'view' MUST be initialized
    [newObj->view removeFromSuperview];
    [newObj->window setContentView: 0];	// Don't need the window for anything
    [newObj->window free];		// So free it.
    
    // Do any other set up here.
    
    return newObj;
}

static int dspNum = 0;

#define NO_DRIVER_STRING "<no driver>"
#define PRIVATE_STRING "<private>"
#define BLANK_STRING "--"
    
#import <defaults/defaults.h>
#import <dsp/DSPObject.h>
#ifndef DSP_MAXDSPS /* FIXME--Not being found, for some reason */
#define DSP_MAXDSPS 32
#endif

static NXDefaultsVector MusicKitDefaults = {
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
    {"DSPSerialPortDevice0", NULL},
    {"DSPSerialPortDevice1", NULL},
    {"DSPSerialPortDevice2", NULL},
    {"DSPSerialPortDevice3", NULL},
    {"DSPSerialPortDevice4", NULL},
    {"DSPSerialPortDevice5", NULL},
    {"DSPSerialPortDevice6", NULL},
    {"DSPSerialPortDevice7", NULL},
    {"DSPSerialPortDevice8", NULL},
    {"DSPSerialPortDevice9", NULL},
    {"DSPSerialPortDevice10", NULL},
    {"DSPSerialPortDevice11", NULL},
    {"DSPSerialPortDevice12", NULL},
    {"DSPSerialPortDevice13", NULL},
    {"DSPSerialPortDevice14", NULL},
    {"DSPSerialPortDevice15", NULL},
    {"DSPSerialPortDevice16", NULL},
    {"DSPSerialPortDevice17", NULL},
    {"DSPSerialPortDevice18", NULL},
    {"DSPSerialPortDevice19", NULL},
    {"DSPSerialPortDevice20", NULL},
    {"DSPSerialPortDevice21", NULL},
    {"DSPSerialPortDevice22", NULL},
    {"DSPSerialPortDevice23", NULL},
    {"DSPSerialPortDevice24", NULL},
    {"DSPSerialPortDevice25", NULL},
    {"DSPSerialPortDevice26", NULL},
    {"DSPSerialPortDevice27", NULL},
    {"DSPSerialPortDevice28", NULL},
    {"DSPSerialPortDevice29", NULL},
    {"DSPSerialPortDevice30", NULL},
    {"DSPSerialPortDevice31", NULL},
    {"MIDI0", NULL},
    {"MIDI1", NULL},
    {"MIDI2", NULL},
    {"MIDI3", NULL},
    {"MIDI4", NULL},
    {"MIDI5", NULL},
    {"MIDI6", NULL},
    {"MIDI7", NULL},
    {"MIDI8", NULL},
    {"MIDI9", NULL},
    {"MIDI10", NULL},
    {"MIDI11", NULL},
    {"MIDI12", NULL},
    {"MIDI13", NULL},
    {"MIDI14", NULL},
    {"MIDI15", NULL},
#if m68k
    {"OrchestraSoundOut", "Host"},
#else
    {"OrchestraSoundOut", "SSI"},
#endif
    {NULL}};

static char *serialPortDeviceNames[] = 
  {"ArielProPort","SSAD64x","StealthDAI2400","GENERIC"};
    
/* FIXME Add for user-addable serial port devices. */
#define SERIAL_PORT_DEVICE_COUNT (sizeof(serialPortDeviceNames)/sizeof(char *))
    
#include <dsp/dsp.h>   /* For DSP_MAXDSPS */

#if i386

#import <stdlib.h>
#import <stdio.h>
#import <objc/objc.h>
#import <objc/NXBundle.h>
#import <bsd/sys/param.h>
#import <driverkit/IOConfigTable.h>
#import <driverkit/IODeviceMaster.h>
#import <driverkit/IODevice.h>

#define MAX_DRIVERS 32 /* Should be enough! */

#define MAX_DRIVER_NAME_LENGTH 64

static char *dspDriverNames[MAX_DRIVERS];
static char *dspSerialPortDevices[MAX_DRIVERS];

static int dspDriverCount = 0;



/* Because stupid Preferences doesn't link against libDriver, 
 * (although it links against everything else under the sun), we have to run a
 * command line program, then read its output.  SIGH! 
 */
    
static int findAppWrapperFile(char *fileName,char *returnNameBuffer)
  /* fileName should include extension.
   * returnNameBuffer should be of size MAXPATHLEN + 1.
   * This function returns 1 and sets returnNameBuffer if successful.
   * If unsuccessful, resturns 0.
   */
  {
      int err;
//      id bundle = [NXBundle mainBundle];	
      id bundle = [NXBundle bundleForClass:[MusicKitPrefs class]];
      if (!bundle)
	return 0;
      err=[bundle getPath:returnNameBuffer forResource:fileName ofType:NULL];
      return err;
  }
    
static int inUseDSPDrivers[DSP_MAXDSPS] = {0}; 
    /* Contains indecies into dspDriverNames[] and dspSerialPortDevices[] */
    
    
-(int)_initIntelBasedDSPs
  {
      BOOL foundIt,foundOne,foundOther;
      char c;
      char *defaultsValue,*s;
#define MAX_DSP_NUM_STR 8 /* "DSP"+<up to 3 digits>+NULL */ 
      char dspNumStrArr[MAX_DSP_NUM_STR];
      int i,j,k;
      FILE *fp;
      /* See note above */
      fp = fopen("/tmp/.dsp_driver_list","r");
      if (fp == NULL) {
	  fprintf(stderr,
		  "Music Kit preferences: Can't read file /tmp/.dsp_driver_list.\n");
	  return -1;
      }
      /* Get DSP drivers */
      for (dspDriverCount = 0, i=0; i<MAX_DRIVERS && !feof(fp); i++) {
	  /* Each driver */
	  dspDriverCount++;
	  j = 0;
	  s = dspDriverNames[i] = (char *)malloc(MAX_DRIVER_NAME_LENGTH);
	  /* Parsing can be crude because we're the ones who write the file */
	  while (++j < MAX_DRIVER_NAME_LENGTH) {
	      c = getc(fp);
	      if (feof(fp) || isspace(c))
		break;
	      *s++ = c;
	  }
	  *s = '\0';
	  if (strlen(dspDriverNames[i]) == 0) { /* Extra CR? */
	      free(dspDriverNames[i]);
	      dspDriverNames[i] = NULL;
	      dspDriverCount--;
	      break;
	  }
	  s = dspSerialPortDevices[i] = (char *)malloc(MAX_DRIVER_NAME_LENGTH);
	  j = 0;
	  if (c == ' ') {
	      while (++j < MAX_DRIVER_NAME_LENGTH) {
		  c = getc(fp);
		  if (feof(fp) || isspace(c))
		    break;
		  *s++ = c;
	      }
	  }
	  *s = '\0';
      }
      fclose(fp);
      if (unlink("/tmp/.dsp_driver_list") == -1) { 
	fprintf(stderr,"Music Kit Preferences: Can't delete /tmp/.dsp_driver_list.\n");
      } 
      /******** Now see which of these are in use, as requested by user *****/
      foundOne = 0;
      for (i=0; i<DSP_MAXDSPS; i++) {
	  sprintf(dspNumStrArr,"DSP%d",i);
	  if (!(defaultsValue = (char *)
		NXGetDefaultValue("MusicKit",(const char *)dspNumStrArr))) {
	      inUseDSPDrivers[i] = -1;
	      continue;
	  }
	  foundOther = foundIt = 0;
	  for (j=0; j<dspDriverCount && !foundIt; j++) {
	      if (strcasecmp(dspDriverNames[j],defaultsValue) == 0) {
		  /* we now know that j is the index we're looking for in 
		     inUseDSPDrivers[] */
		  foundOther = 0;
		  for (k=0; k<i && !foundOther; k++) {
		      if (inUseDSPDrivers[k] == j) {
			  NXRunAlertPanel("MusicKit Preferences",
					  "%s appears twice, as DSP%d and DSP%d.",NULL,
					  NULL,NULL,defaultsValue,k,i);
			  NXRemoveDefault("MusicKit",(const char *)dspNumStrArr);
			  foundOther = 1;
		      }
		  }
		  if (!foundOther) {
		      inUseDSPDrivers[i] = j;
		      foundOne = 1;
		      foundIt = 1;
		  }
	      }
	  }
	  if (!foundIt) {
	      if (!foundOther) {
		  NXRunAlertPanel("MusicKit Preferences",
				  "%s, assigned to DSP%d, has not been added to the system.",
				  NULL,NULL,NULL,defaultsValue,i);
		  NXRemoveDefault("MusicKit",(const char *)dspNumStrArr);
	      }
	      inUseDSPDrivers[i] = -1;
	  }
      }
      /* If the users's data base doesn't have anything or we couldn't
	 find anything, use the first one we have. */
      if (!foundOne)
	inUseDSPDrivers[0] = 0;

      if (!dspDriverNames[0]) { /* No drivers at all */
	  [dspDriverPopUpButton setEnabled:0];
	  [dspNumField setStringValue:BLANK_STRING];
	  [dspNumField setEnabled:0];
	  [dspDriverPopUpButton setEnabled:0];
	  [dspDriverPopUpButton setTitle:NO_DRIVER_STRING];
	  return -1;
      }
      return 0;
  }
    
#define MAX_MIDIS 16 /* MIDI15 is the highest */
    
static int inUseMidiUnits[MAX_MIDIS];
static int midiDriverCount = 0;
static int unitToMidiMap[MAX_DRIVERS];
    
static BOOL getTrailingNumber(char *s,int *rtn)
  {
      char *s2,*s3;
      s3 = s2 = s + strlen(s) - 1;
      while (isdigit(*s2) && (s2 > s)) 
	s2--;
      if (s2 == s3) {	/* not found */
	  NXRunAlertPanel("MusicKit Preferences",
			  "No unit number found in driver name %s.",
			  NULL,NULL,NULL,s);
	  return NO;
      }
      if (s2 == s) {	/* not found */
	  NXRunAlertPanel("MusicKit Preferences",
			  "Illegal driver name found: %s.",
			  NULL,NULL,NULL,s);
	  return NO;
      }
      s2++;
      *rtn = atoi(s2);
      return YES;
  }
    
-(int)_initIntelBasedMIDIs {
    /* We assume that the maximum unit number we find implies all lesser units
       exist. We also assume that there's only one mididriver called 
       "Mididriver". If we ever support other Midi drivers, we'll have to 
       change this code.
       */
#define MAX_MIDI_NUM_STR 8 /* "MIDI"+<up to 3 digits>+NULL */ 
    char midiNumStrArr[MAX_MIDI_NUM_STR];
    char midiTextStrArr[64];
    int i,j,unitNum;
    BOOL foundOne, foundOther;
    char *defaultsValue;
    FILE *fp;
    fp = fopen("/tmp/.midi_driver_list","r");
    if (!fp) {
	fprintf(stderr,
		"Music Kit preferences: Can't read file /tmp/.midi_driver_list.\n");
	return -1;
    }
    /* Get MIDI drivers */
    for (midiDriverCount = 0, i=0; i<MAX_DRIVERS && !feof(fp); i++) {
	/* Count lines */
	while (!feof(fp) && (getc(fp)!='\n'))
	  ;
	if (!feof(fp))
	  midiDriverCount++;
    }
    for (i=0; i<MAX_DRIVERS; i++)
      unitToMidiMap[i] = -1;
    if (midiDriverCount <= 1)
      sprintf(midiTextStrArr,"Select MIDI# and set unit# to 0");
    else if (midiDriverCount == 2)
      sprintf(midiTextStrArr,"Select MIDI# and set unit# to 0 or 1");
    else 
      sprintf(midiTextStrArr,"Select MIDI# and set unit# between 0 and %d",
	      midiDriverCount-1);
    [midiText setStringValue:midiTextStrArr];
    fclose(fp);
    if (unlink("/tmp/.midi_driver_list") == -1) { 
	fprintf(stderr,"Music Kit Preferences: Can't delete /tmp/.midi_driver_list.\n");
    } 
    /******** Now see which of these are in use, as requested by user *****/
    foundOne = 0;
    for (i=0; i<MAX_MIDIS; i++) {
	sprintf(midiNumStrArr,"MIDI%d",i);
	if (!(defaultsValue = (char *)
	      NXGetDefaultValue("MusicKit",(const char *)midiNumStrArr))) {
	    inUseMidiUnits[i] = -1;
	    continue;
	}
	if (!getTrailingNumber(defaultsValue,&unitNum))
	  continue;
	if (unitNum >= midiDriverCount) {
	    NXRunAlertPanel("MusicKit Preferences",
			    "%s, assigned to MIDI%d, has not been added to the system.",
			    NULL,NULL,NULL,defaultsValue,i);
	    NXRemoveDefault("MusicKit",(const char *)midiNumStrArr);
	}
	foundOther = 0;
	for (j=0; j<i; j++)
	  if (inUseMidiUnits[j] == unitNum) {
	      NXRunAlertPanel("MusicKit Preferences",
			      "%s appears twice, as MIDI%d and MIDI%d.",NULL,
			      NULL,NULL,defaultsValue,j,i);
	      NXRemoveDefault("MusicKit",(const char *)midiNumStrArr);
	      foundOther = 1;
	      inUseMidiUnits[i] = -1;
	      break;
	  }
	if (!foundOther) {
	    unitToMidiMap[unitNum] = i;
	    inUseMidiUnits[i] = unitNum;
	    foundOne = 1;
	}
    }
    /* If the users's data base doesn't have anything or we couldn't
       find anything, use the first one we have. */
    if (!foundOne) {
	inUseMidiUnits[0] = 0;
	unitToMidiMap[0] = 0;
    }
    return 0;
}
    
-_initIntelDrivers
  {
      char buff1[MAXPATHLEN+1];
      static BOOL driverInfoInitialized = 0;
      if (driverInfoInitialized) { /* Already initialized */
	  return self;
      } else driverInfoInitialized = YES;
      if (findAppWrapperFile("driverinfo",buff1)) {
	  system(buff1);
      } else {
	  fprintf(stderr,
		  "Music Kit preferences: Can't find driverinfo utility in Preferences app wrapper.\n");
	  return nil;
      }
      [self _initIntelBasedDSPs];
      [self _initIntelBasedMIDIs];
      return self;
  }
    
#endif
    
-updateDspDisplay
  {
      /* Initialize state from defaults data base and such here. */
      char spdName[64];
      id menuMatrix;
      char *s;
      int i;
#if i386
      if (dspNum < 0)
	dspNum = 0;
      if (dspNum > DSP_MAXDSPS-1)
	dspNum = DSP_MAXDSPS-1;
      [dspNumDec setEnabled:(dspNum > 0) && (dspDriverCount>1)];
      [dspNumInc setEnabled:(dspNum != DSP_MAXDSPS-1) &&
       (dspDriverCount > 1)];
      if (!dspDriverNames[0]) /* No drivers at all */
	return self;
      [dspDriverPopUpButton setEnabled:1];
      [dspNumField setIntValue:dspNum];

      menuMatrix = [[dspDriverPopUpButton target] itemList];
      [menuMatrix renewRows:dspDriverCount+1 cols:1]; 
      for (i=0; i<dspDriverCount; i++) 
	[[menuMatrix cellAt:i :0] setTitle:dspDriverNames[i]];
      [[menuMatrix cellAt:dspDriverCount :0] setTitle:NO_DRIVER_STRING];
//      [menuMatrix renewRows:dspDriverCount+1 cols:1]; 
      if (inUseDSPDrivers[dspNum] != -1) {
	  [dspDriverPopUpButton setTitle:dspDriverNames[inUseDSPDrivers[dspNum]]];
	  [menuMatrix selectCellAt:inUseDSPDrivers[dspNum] :0];
	}
      else {
	  [dspDriverPopUpButton setTitle:NO_DRIVER_STRING];
	  [menuMatrix selectCellAt:dspDriverCount :0];
      }
      
      menuMatrix = [[serialPortDevicePopUpButton target] itemList];
      [menuMatrix renewRows:SERIAL_PORT_DEVICE_COUNT cols:1]; 
      for (i=0; i<SERIAL_PORT_DEVICE_COUNT; i++)
	[[menuMatrix cellAt:i :0] setTitle:serialPortDeviceNames[i]];
      if (inUseDSPDrivers[dspNum] != -1)
	s = dspSerialPortDevices[inUseDSPDrivers[dspNum]];
      else s = "";
      if (!strcmp(s,"NeXT")) {
	  [serialPortDevicePopUpButton setEnabled:1];
	  sprintf(spdName,"DSPSerialPortDevice%d",dspNum);
	  s = (char *)NXGetDefaultValue("MusicKit",(const char *)spdName);
	  if (!s || !strcmp(s,"DSPSerialPortDevice"))
	    s = "GENERIC";
	  [serialPortDevicePopUpButton setTitle:s];
	  [menuMatrix renewRows:SERIAL_PORT_DEVICE_COUNT cols:1]; 
      } else {
	  [serialPortDevicePopUpButton setEnabled:0];
	  [serialPortDevicePopUpButton setTitle:PRIVATE_STRING];
      }
#else
      dspNum = 0;
      menuMatrix = [[serialPortDevicePopUpButton target] itemList];
      [serialPortDevicePopUpButton setEnabled:1];
      [menuMatrix renewRows:SERIAL_PORT_DEVICE_COUNT cols:1]; 
      for (i=0; i<SERIAL_PORT_DEVICE_COUNT; i++)
	[[menuMatrix cellAt:i :0] setTitle:serialPortDeviceNames[i]];
      sprintf(spdName,"DSPSerialPortDevice%d",dspNum);
      s = (char *)NXGetDefaultValue("MusicKit",(const char *)spdName);
//      s = (char *)NXReadDefault("MusicKit",(const char *)spdName);
      if (!s || !strcmp("DSPSerialPortDevice",s))
	s = "GENERIC";
      [serialPortDevicePopUpButton setTitle:s];
      [menuMatrix renewRows:SERIAL_PORT_DEVICE_COUNT cols:1]; 
//      s = (char *)NXGetDefaultValue("MusicKit","OrchestraSoundOut");
      s = (char *)NXReadDefault("MusicKit","OrchestraSoundOut");
      if (s)
	NXSetDefault("MusicKit","OrchestraSoundOut",s);
      if (s && !strcmp(s,"SSI"))
	[soundOutMatrix selectCellWithTag:1];
      else 
	[soundOutMatrix selectCellWithTag:0];
#endif
      return self;
  }
    
-setDSPDriver:sender
  {
#if i386
      int i,driverNum = -1;
      char dspName[16];
      char *s = (char *)[[sender selectedCell] title];
      sprintf(dspName,"DSP%d",dspNum);
      if (!strcmp(s,NO_DRIVER_STRING)) {
	  inUseDSPDrivers[dspNum] = -1;
	  NXRemoveDefault("MusicKit",dspName);
	  [self updateDspDisplay];
	  return self;
      }
      for (i=0; i<dspDriverCount; i++) {
	  /* Find driver matching the selected name */
	  if (!strcmp(dspDriverNames[i],s)) {
	      driverNum = i;
	      break;
	  }
      }
      for (i=0; i<DSP_MAXDSPS; i++)
	if ((i != dspNum) && inUseDSPDrivers[i] == driverNum) {
	    NXRunAlertPanel("MusicKit Preferences",
			    "The driver you selected is already assigned to DSP%d.",
			    "OK",NULL,NULL,i);
	    /* Set it back to what it was */
	    if (inUseDSPDrivers[dspNum] == -1)
	      [dspDriverPopUpButton setTitle:NO_DRIVER_STRING];
	    else [dspDriverPopUpButton setTitle:dspDriverNames[inUseDSPDrivers[dspNum]]];
	    [[[dspDriverPopUpButton target] itemList] 
	     renewRows:dspDriverCount+1 cols:1]; 
	    return self;
	}
      inUseDSPDrivers[dspNum] = driverNum;
      NXWriteDefault("MusicKit",dspName,s); 
      [self updateDspDisplay];
#endif
      return self;
  }
      
-setSerialPortDevice:sender
  {
      char spdName[32];
      char *s = (char *)[[sender selectedCell] title];
      sprintf(spdName,"DSPSerialPortDevice%d",dspNum);
      if (!strcmp("GENERIC",s))
	s = "DSPSerialPortDevice";
      NXWriteDefault("MusicKit",spdName,s); 
      return self;
  }
	  
- setSoundOutType:sender
  {
      NXWriteDefault("MusicKit","OrchestraSoundOut",
		     [sender selectedRow] ? "SSI" : "Host");
      return self;
  }
      
- awakeFromNib
  {
      [[dspDriverPopUpButton target] setTarget:self];
      [[dspDriverPopUpButton target] setAction:@selector(setDSPDriver:)];
      [[serialPortDevicePopUpButton target] setTarget:self];
      [[serialPortDevicePopUpButton target] setAction:@selector(setSerialPortDevice:)];
      return self;
  }
      
- setDspNum:sender
  {
      dspNum = [sender intValue];
      if (dspNum >= DSP_MAXDSPS) 
	dspNum = DSP_MAXDSPS-1;
      else if (dspNum < 0)
	dspNum = 0;
      [self updateDspDisplay];
      return self;
  }
	  
	  
- incDspNum:sender
  {
      dspNum++;
      return [self updateDspDisplay];
  }
	  
- decDspNum:sender
  {
      dspNum--;
      return [self updateDspDisplay];
  }

static int midiNum = 0;
	  
- updateMidiDisplay
  {
#if i386
      if (midiNum > MAX_MIDIS)
	midiNum = MAX_MIDIS-1;
      if (midiNum < 0)
	midiNum = 0;
      [midiNumField setIntValue:midiNum];
      if (inUseMidiUnits[midiNum] == -1) {
	  [midiUnitNumField setStringValue:BLANK_STRING];
      } else
	[midiUnitNumField setIntValue:inUseMidiUnits[midiNum]];
      [midiNumDec setEnabled:(midiNum > 0) && (midiDriverCount>1)];
      [midiNumInc setEnabled:(midiNum != MAX_MIDIS-1) &&
       (midiDriverCount > 1)];
#endif
      return self;
  }
	  
- setMidiNum:sender
  {
      midiNum = [sender intValue];
      return [self updateMidiDisplay];
  }
	  
- incMidiNum:sender
  {
      midiNum++;
      return [self updateMidiDisplay];
  }
	  
- decMidiNum:sender
  {
      midiNum--;
      return [self updateMidiDisplay];
  }
	  
- clearMidiUnit:sender
  {
#if i386
      char midiName[8];
      [midiUnitNumField setStringValue:BLANK_STRING];
      if (inUseMidiUnits[midiNum] == -1)
	return self;
      unitToMidiMap[inUseMidiUnits[midiNum]] = -1;
      inUseMidiUnits[midiNum] = -1;
      sprintf(midiName,"MIDI%d",midiNum);
      NXRemoveDefault("MusicKit",(const char *)midiName);
#endif
      return [self updateMidiDisplay];
  }
	  
- setMidiUnit:sender
  {
#if i386
      char midiName[10];
      char midiDriverName[16];
      int whichUnit = [sender intValue];
      if (whichUnit >= midiDriverCount ||
	  whichUnit < 0) { /* Illegal value */
	  NXBeep();
	  if (inUseMidiUnits[midiNum] == -1)
	    [midiUnitNumField setStringValue:BLANK_STRING];
	  else [midiUnitNumField setIntValue:inUseMidiUnits[midiNum]];
	  return self;
      }
      if (!strcmp([sender stringValue],BLANK_STRING)) {
	  if (inUseMidiUnits[midiNum] != -1)
	    unitToMidiMap[inUseMidiUnits[midiNum]] = -1;
	  inUseMidiUnits[midiNum] = -1;
	  sprintf(midiName,"MIDI%d",midiNum);
	  NXRemoveDefault("MusicKit",(const char *)midiName);
	  return self;
      }
      if (unitToMidiMap[whichUnit] != -1) {
	  NXRunAlertPanel("MusicKit Preferences",
			  "The unit you selected is already assigned to MIDI%d.",
			  NULL,NULL,NULL,unitToMidiMap[whichUnit]);
	  if (inUseMidiUnits[midiNum] == -1)
	    [midiUnitNumField setStringValue:BLANK_STRING];
	  else [midiUnitNumField setIntValue:inUseMidiUnits[midiNum]];
	  return self;
      }
      inUseMidiUnits[midiNum] = whichUnit;
      unitToMidiMap[whichUnit] = midiNum;
      sprintf(midiName,"MIDI%d",midiNum);
      sprintf(midiDriverName,"Mididriver%d",whichUnit);
      NXWriteDefault("MusicKit",midiName,midiDriverName); 
      [midiUnitNumField setIntValue:whichUnit];
#endif
      return self;
}

- willSelect: sender
  /*
    Before the view is added via addSubview
    */
  {
      dspNum = 0;
      midiNum = 0;
      NXRegisterDefaults("MusicKit", MusicKitDefaults);
#if i386
      [self _initIntelDrivers];
#endif
      [self updateDspDisplay];
      [self updateMidiDisplay];
      return self;
  }
      
- didSelect: sender
  /*
    After the view is added via addSubview
    */
  {
      /*
	Enable all of the edit and window menu items, just for the heck of it.
	*/
      [NXApp enableEdit: CUT_ITEM|COPY_ITEM|PASTE_ITEM|SELECTALL_ITEM];
      [NXApp enableWindow: MINIATURIZE_ITEM|CLOSE_ITEM];
      return self;
  }
	  
- willUnselect: sender
  /*
    Before removeFromSuperview
    */
  {
      /* Make sure that we aren't editing any text fields. */
      [[NXApp appWindow] endEditingFor: self];  
      return self;
  }
	  
- didUnselect: sender
  /*
    Before removeFromSuperview
    */
  {
      /*
	Disable all of the edit and window menu items, just for the heck of it.
	*/
      [NXApp enableEdit: NO];
      [NXApp enableWindow: NO];
      return self;
  }
	  
- didHide: sender
  /*
    Application was just hidden.
    */
  {
      return self;
  }
      
- didUnhide: sender
  /*
    Application was just unhidden.
    */
  {
      return self;
  }
	  
@end
