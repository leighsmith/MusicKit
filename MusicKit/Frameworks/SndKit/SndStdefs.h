/* Sndstdefs.h */

#ifndef __SNDSTDDEFS__
#define __SNDSTDDEFS__

#ifdef GNUSTEP
#include <objc/objc.h>
#else
#import <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */
#endif
//#ifndef TRUE
//#define TRUE  1
//#endif

//#ifndef FALSE
//#define FALSE 0
//#endif

#ifndef PI
#define PI (3.14159265358979232846)
#endif

#ifndef PI2
#define PI2 (6.28318530717958465692)
#endif

#define D2R (0.01745329348)          /* (2*pi)/360 */
#define R2D (57.29577951)            /* 360/(2*pi) */

#ifndef MAX
#define MAX(x,y) ((x)>(y) ?(x):(y))
#endif
#ifndef MIN
#define MIN(x,y) ((x)<(y) ?(x):(y))
#endif

#ifndef ABS
#define ABS(x)   ((x)<0   ?(-(x)):(x))
#endif

#ifndef SGN
#define SGN(x)   ((x)<0   ?(-1):((x)==0?(0):(1)))
#endif

//typedef char           BOOL;
typedef short          SND_HWORD;
typedef unsigned short SND_UHWORD;
typedef int            SND_WORD;
typedef unsigned int   SND_UWORD;

#define MAX_HWORD (32767)
#define MIN_HWORD (-32768)

#ifdef DEBUG
#define INLINE
#else DEBUG
#define INLINE inline
#endif DEBUG

#endif
