#import "dsp_types.h"
#import "dsp_structs.h"

typedef void (*DSPMKWriteDataUserFunc)
    (short *data,unsigned int dataCount,int dspNum);
