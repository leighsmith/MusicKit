#if i386

/* Write out a file on /tmp.

   DriverNameAndUnit-Subunit SerialPortDeviceParameter (if any)
   DriverNameAndUnit-Subunit SerialPortDeviceParameter (if any) 
   DriverNameAndUnit-Subunit SerialPortDeviceParameter (if any) 
   etc.

*/   

#import <stdlib.h>
#import <stdio.h>
#import <libc.h>  // Has unlink()
#import <objc/objc.h>
#import <objc/NXBundle.h>
#import <bsd/sys/param.h>
#import <driverkit/IOConfigTable.h>
#import <driverkit/IODeviceMaster.h>
#import <driverkit/IODevice.h>
#import <dsp/DSPObject.h>

#ifndef DSPDRIVER_PAR_SUBUNITS              /* Shouldn't happen */
#define DSPDRIVER_PAR_SUBUNITS "SubUnits"
#endif

static char *getDriverParameter(char *driverName,int unit,
				char *parameterName)
{
    IOReturn        ret;
    IOObjectNumber  tag;
    IOString        kind;
    IOCharParameter value;
    unsigned int    count = IO_MAX_PARAMETER_ARRAY_LENGTH;
    char            name[80];
    IODeviceMaster *devMaster;
    char           *rtn;    
    devMaster = [IODeviceMaster new];
    sprintf(name, "%s%d", driverName, unit);
    ret = [devMaster lookUpByDeviceName:name objectNumber:&tag 
	 deviceKind:&kind];
    if (ret != IO_R_SUCCESS) { 
        return NULL;
    } else { /* Successfully got the object number */
      /* Get the value of the driver's parameter. */
      ret = [devMaster getCharValues:value 
           forParameter:parameterName objectNumber:tag
           count:&count];
      if (ret != IO_R_SUCCESS) { 
        return NULL;
    } else /* Successfully got the parameter value */
        rtn = malloc(strlen(value)+1);
        strcpy(rtn,value);
        return rtn;
  }
}

void main(void)
{
    char *s1,*s2,*s3;
    List *installedDrivers,*driverList;
    id aConfigTable;
    char strbuff[2048];
    int i,j,driverCount,subUnitCount;
    int fd = creat("/tmp/.dsp_driver_list",0666); /* Read/write for all */
    if (fd == -1) {
	fprintf(stderr,"Music Kit Preferences: Can't write /tmp/.dsp_driver_list.\n");
	exit(0);
    }
    installedDrivers = [IOConfigTable tablesForInstalledDrivers];
    /* Creates, if necessary, and returns IOConfigTables, one for each
       device that has been loaded into the system.  This method knows only
       about those devices that are specified with the system configuration
       table's InUse Drivers and Boot Drivers keys.  It does not detect
       drivers that were loaded due to user action at boot time.  To get
       the IOConfigTables for those drivers, you can use
       tablesForBootDrivers.
       */
    driverList = [[List alloc] init];
    /* Get DSP drivers */
    for (i=0; i<[installedDrivers count]; i++) {
        /* Each driver */
        aConfigTable = [installedDrivers objectAt:i];
        if (!strcmp([aConfigTable valueForStringKey:"Family"],"DSP"))
          [driverList addObject:aConfigTable];
    }
    driverCount = [driverList count];
    for (i=0; i<driverCount; i++) {
        /* Or "Server Name"? */
        aConfigTable = [driverList objectAt:i];
	s1 = (char *)[aConfigTable valueForStringKey:"Class Names"],
	s2 = (char *)[aConfigTable valueForStringKey:"Instance"];
	if (!s1 || !s2) /* Should never happen */
	  continue; 
	s3 = getDriverParameter(s1,atoi(s2),DSPDRIVER_PAR_SUBUNITS);
	if (s3 && ((subUnitCount = atoi(s3)) > 1)) {
	    for (j=0; j<subUnitCount; j++) {
		sprintf(strbuff,"%s%s-%d ",s1,s2,j);
		write(fd,strbuff,strlen(strbuff));
		s1 = getDriverParameter(s1,atoi(s2),DSPDRIVER_PAR_SERIALPORTDEVICE);
		if (s1) 
		  write(fd,s1,strlen(s1));
		write(fd, "\n",1);
	    }
	} else {
	    sprintf(strbuff,"%s%s ",s1,s2);
	    write(fd,strbuff,strlen(strbuff));
	    s1 = getDriverParameter(s1,atoi(s2),DSPDRIVER_PAR_SERIALPORTDEVICE);
	    if (s1)
	      write(fd,s1,strlen(s1));
	    write(fd,"\n",1);
	}
    }
    close(fd);
    [driverList free];
    fd = creat("/tmp/.midi_driver_list",0666); /* Read/write for all */
    if (fd == -1) {
	fprintf(stderr,"Music Kit Preferences: Can't write /tmp/.midi_driver_list.\n");
	exit(0);
    }
    installedDrivers = [IOConfigTable tablesForInstalledDrivers];
    driverList = [[List alloc] init];
    /* Get MIDI drivers */
    for (i=0; i<[installedDrivers count]; i++) {
        /* Each driver */
        aConfigTable = [installedDrivers objectAt:i];
        if (!strcmp([aConfigTable valueForStringKey:"Family"],"MIDI"))
          [driverList addObject:aConfigTable];
    }
    driverCount = [driverList count];
    for (i=0; i<driverCount; i++) {
        /* Or "Server Name"? */
        aConfigTable = [driverList objectAt:i];
	s1 = (char *)[aConfigTable valueForStringKey:"Class Names"];
	s2 = (char *)[aConfigTable valueForStringKey:"Instance"];
	if (!s1 || !s2) /* Should never happen */
	  continue; 
	write(fd,s1,strlen(s1));
	write(fd,s2,strlen(s2));
	write(fd, "\n", 1);
    }
    close(fd);
    exit(0);
}

#else

#import <stdio.h>

void main(void)
{
    fprintf(stderr,"This program works only on Intel architecture.\n");
    exit(1);
}

#endif
