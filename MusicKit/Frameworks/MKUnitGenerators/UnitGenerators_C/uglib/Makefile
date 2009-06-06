# Makefile for musickit_c unit generators.  Greatly simplified. 
#
#  Architecture specific defines: 
#     _SGI_SOURCE        SGI
#     i386               NeXT x86 
#     m68k               NeXT 68k 
#



UGLIB = libugs_c.a

HFILES = ugs_c.h

CFILES = 

UG_CFILES = add2.c add3.c add4.c allpass1.c asymp.c biquad.c constant.c \
	cubicnl.c cubicnlg.c cubicnlc.c dcblock.c delay.c delayi.c \
	dswitch.c dswitcht.c exp.c fir3.c interp.c moden.c moogVCFbl.c mul1add2.c mul2.c \
	onepole.c onepoleswept.c onezero.c \
	oscg.c oscgaf.c oscgafi.c \
	out2sum.c readonce.c \
	scale.c scaleup.c scl1add2.c scl2add2.c \
	snoise.c tablooki.c unoise.c maxzero.c pnf.c delayai.c

UG_HFILES = $(UG_CFILES:.c=.h)

UG_OFILES = $(UG_CFILES:.c=.o)

$(UGLIB):: $(UG_OFILES)
	/bin/rm -f  $(UGLIB)
	/bin/ar  q $(UGLIB) $(UG_OFILES)

.SUFFIXES: .c .o

.c.o:
	cc -g -c $*.c

clean:
	/bin/rm -f *.o $(UGLIB) *~
