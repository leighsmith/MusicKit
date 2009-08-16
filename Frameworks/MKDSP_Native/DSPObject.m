#import <Foundation/Foundation.h>
#include "_dsp.h"

static NSDictionary *DSPDefaults = nil;
static NSUserDefaults *ourDefaults = nil;

/****************** Getting and setting DSP system files *********************/

const char *DSPGetDSPDirectory(void)
{
    NSString *dspdir;
    char *dspdirenv;
    //    struct stat sbuf;
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;

#if 0
    if (s_dsp_count==0) {
        _DSPInitDefaults();
    }
#endif
    dspdirenv = getenv("DSP"); // LMS FIXME: getenv should be replaced with access from NSUserDefaults
    dspdir = (dspdirenv == NULL) ? 
	    DSP_SYSTEM_DIRECTORY :
		[manager stringWithFileSystemRepresentation:dspdirenv length:strlen(dspdirenv)];
    // here is the potential to do path grooming appropriate to the Operating system.
//    if(stat(dspdir,&sbuf)) LMS
    if([manager fileExistsAtPath: dspdir isDirectory: &isDir] != YES || !isDir) {
      [dspdir release];
      dspdir = DSP_FALLBACK_SYSTEM_DIRECTORY;
    }
    return [dspdir fileSystemRepresentation];
}

int DSPAddMappedDSP(DSPRegs *hostInterfaceAddress, const char *name)
{
#if 0
    s_addDSP(name);
    s_hostInterfaceArray[s_dsp_count-1] = hostInterfaceAddress;
    s_mapped_only[s_dsp_count-1] = 1;
#endif
    return 0;
}

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
    if (DSPEnableErrorFile([s fileSystemRepresentation]))
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
