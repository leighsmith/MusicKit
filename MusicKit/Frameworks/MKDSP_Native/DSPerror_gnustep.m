#import "MKDSPDefines.h"
#import <Foundation/Foundation.h>
#import "dsp_errno.h"

#define DSP_ERRORS_FILE "/tmp/dsperrors"
static int s_error_log_disabled = 1;  /* Stifle error print-out if nonzero */
static FILE *s_err_fp = 0;
static char *s_err_fn = DSP_ERRORS_FILE;
MKDSP_API int _DSPVerbose;
MKDSP_API int DSPErrorNo;

static const char LITERAL_N[] = "N";
static const char LITERAL_X[] = "X";
static const char LITERAL_XL[] = "XL";
static const char LITERAL_XH[] = "XH";
static const char LITERAL_Y[] = "Y";
static const char LITERAL_YL[] = "YL";
static const char LITERAL_YH[] = "YH";
static const char LITERAL_L[] = "L";
static const char LITERAL_LL[] = "LL";
static const char LITERAL_LH[] = "LH";
static const char LITERAL_P[] = "P";
static const char LITERAL_PL[] = "PL";
static const char LITERAL_PH[] = "PH";
static const char LITERAL_GLOBAL[] = "GLOBAL";
static const char LITERAL_SYSTEM[] = "SYSTEM";
static const char LITERAL_USER[] = "USER";

MKDSP_API const char * DSPMemoryNames(int memorySpaceNum)
{
    static const char *memNames[] = { LITERAL_N, LITERAL_X, LITERAL_Y, LITERAL_L, LITERAL_P };
 
    return memNames[memorySpaceNum];
}

MKDSP_API int _DSPError1(
    int errorcode,
    char *msg,
    char *arg)
{
    extern int errno;
 
    if (s_error_log_disabled)
      return errorcode;
 
    _DSPCheckErrorFP();
 
    fflush(stdout);
    if ( errorcode != -1 )
      DSPErrorNo = errorcode;   /* DSPGlobals.c */
    if ( errorcode < DSP_ERRORBASE && errorcode != -1 )
      errno = errorcode;
 
    fprintf(s_err_fp,";;*** libdsp:");
    fprintf(s_err_fp,msg,arg);
    fprintf(s_err_fp," ***\n");
    if ( errorcode == -1 ) {
        perror(";;\t\tLast UNIX error:");
        fprintf(s_err_fp,"\n");
    }
 
    fflush(s_err_fp); /* unnecessary? */
    return errorcode;
}

MKDSP_API int _DSPError(
    int errorcode,
    char *msg)
{
    if (s_error_log_disabled)
        return errorcode;       /* To avoid memory leak assoc. w DSPCat() */
    else
        return(_DSPError1(errorcode,[NSString stringWithFormat:@"%s%s",msg,"%s"],""));
}
int DSPEnableErrorLog(void)
{
    s_error_log_disabled = 0;
    return 0;
}
int DSPSetErrorFile(
    char *fn)
{
    s_err_fn = fn;
    s_err_fp = 0;
    return(0);
}
 
 
char *DSPGetErrorFile(void)
{
    return s_err_fn;
}
 
 
MKDSP_API int DSPEnableErrorFile(
    const char *fn)
{
    //DSP_UNTIL_ERROR(DSPEnableErrorLog());
    DSPEnableErrorLog();
    return DSPSetErrorFile(fn);
}
int _DSPCheckErrorFP(void)
{
    //time_t tloc;
    NSDate *now = [NSDate date];
 
    if (s_error_log_disabled)
      return 0;
 
    if (s_err_fp == 0) { /* open error log */
//      umask(0); /* Don't CLEAR any filemode bits (arg is backwards!) */
        if ((s_err_fp=fopen(s_err_fn,"wb"))==NULL) {
            fprintf(stderr,
                    "*** _DSPCheckErrorFP: Could not open DSP error file %s\n"
                    "Setting error output to stderr.\n",
                    s_err_fn);
            s_err_fp = stderr;
            return(-1);
        } else
          if (_DSPVerbose)
            fprintf(stderr,"Opened DSP error log file %s\n",s_err_fn);
 
        //tloc = time(0);
 
        fprintf(s_err_fp,"DSP error log for PID %d started on %s\n",
                getpid(),[[now description] cString]);
 
        fflush(s_err_fp);
        return(0);
    }
    return 0;
}

