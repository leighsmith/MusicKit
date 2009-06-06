/* numerics.h */

/* 6/1/95  - jos, created */
/* 4/6/96  - gps, integrated all include files in musickit_c.h */ 
/* 4/11/96 - gps, added SGI dependencies                       */ 


#define NTICK 16
#define MKTICKSIZE NTICK
#define MKVECTORSIZE MKTICKSIZE

#define MAX(a,b) ((a)<(b) ? (b) : (a))
#define MIN(a,b) ((a)>(b) ? (b) : (a))

typedef double word;		/* signed data */
typedef double u_word;		/* unsigned data */
typedef double dbl;		/* double precision */
typedef double u_dbl;		/* unsigned double precision */

#define MAX_WORD ((double)(1.0))
#define MIN_WORD ((double)(-1.0))

#define mk_int_to_word(ival) (((word)ival) / (((word)MAXINT)+1.0))
#define mk_unsigned_int_to_word(ival) ((word)(ival) / (2.0*(((word)MAXINT)+1.0)))
#define mk_double_to_word(dval) dval
#define mk_word_to_short(dval) ((short)(MIN(MAX((dval*((word)MAXSHORT)), \
						-((word)MAXSHORT)), \
					    ((word)MAXSHORT))));
void mk_double_to_word_array(word *wval, double *dval, int n);
void mk_word_to_short_array(short *sval, double *wval, int n);
#define mk_double_to_doubleword(dval) dval

typedef double addr;          		/* 16 bit addresses  */
typedef double MKPatchVector[16];       /* Patchvectors are 16-sample arrays */
typedef double MKPatchVectorDouble[16]; /* Needed for init() code */
typedef double PP[16];                  /* Abbreviated form */
typedef double *pp;                     /* Use this in UGs */
typedef double *synthdata;              /* Synthdata can be any length */

typedef struct _MKWavetable {
    word *data;
    int size;
} MKWavetable;

enum roundingModes {rounding, truncation, magnitude_truncation};
