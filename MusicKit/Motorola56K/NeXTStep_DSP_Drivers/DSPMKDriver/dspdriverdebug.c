#if i386
#define NO_LIB_DSP
#import "dspdriverAccess.c"

void main(int argc,char *argv[]) {
  int flags;
  int rtn;
  if (argc != 3) {
    fprintf(stderr,"Usage: dspdriverdebug <driverName> <int_value>\n");
    exit(1);
  }
  flags = atoi(argv[2]);
  rtn = dsp_debug(argv[1],flags);
  if (rtn == -1)
    fprintf(stderr,"Driver not found.\n");
  else if (rtn == -2)
    fprintf(stderr,"Can't set flags.\n");
  else fprintf(stderr,"Flags set.\n");
  exit(0);
}

#else

#import <ansi/stdio.h>
void main(void) {
  fprintf(stderr,"This program not supported on this architecture.\n");
}

#endif
