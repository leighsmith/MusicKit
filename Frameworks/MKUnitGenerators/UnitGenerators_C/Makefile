#  Simplified musickit_c makefile. 
#
#  Architecture specific defines: 
#     _SGI_SOURCE        SGI
#     i386               NeXT x86 
#     m68k               NeXT 68k 

# Next libraries and sound utility
LIBS = # -lsys_s
SNDPLAY = playsnd

# SGI libraries and sound utility
#LIBS = -laudiofile -laudioutil -lm
#SNDPLAY = sfplay

# Directory of example patches generated from SynthBuilder
PATCHES = patches

# Unit-generator library
UGLIB = uglib/libugs_c.a

# Ultra-simplified computational environment
MKLIB = libmk_c.a

TEST1 = clarinet
TEST2 = flute
TEST3 = pluck
TEST4 = distortionGuitar
TEST5 = newDistortionGuitar
TEST6 = sixteenstrings
TEST7 = moden
TEST8 = moogtest

HFILES = musickit_c.h mk_sys.h soundout.h numerics.h
CFILES = mk_sys.c soundout.c numerics.c
OFILES = $(CFILES:.c=.o)

examples: t1 t2 t3 t4 t5 t6 t7 t8

t1: $(TEST1)
	/bin/time ./$(TEST1)
	$(SNDPLAY) $(TEST1).snd

$(TEST1): $(PATCHES)/$(TEST1).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST1) $(PATCHES)/$(TEST1).o $(MKLIB) $(LIBS)

t2: $(TEST2)
	/bin/time ./$(TEST2)
	$(SNDPLAY) $(TEST2).snd

$(TEST2): $(PATCHES)/$(TEST2).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST2) $(PATCHES)/$(TEST2).o $(MKLIB) $(LIBS)

t3: $(TEST3)
	/bin/time ./$(TEST3)
	$(SNDPLAY) $(TEST3).snd

$(TEST3): $(PATCHES)/$(TEST3).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST3) $(PATCHES)/$(TEST3).o $(MKLIB) $(LIBS)

t4: $(TEST4)
	/bin/time ./$(TEST4)
	$(SNDPLAY) $(TEST4).snd

$(TEST4): $(PATCHES)/$(TEST4).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST4) $(PATCHES)/$(TEST4).o $(MKLIB) $(LIBS)

t5: $(TEST5)
	/bin/time ./$(TEST5)
	$(SNDPLAY) $(TEST5).snd

$(TEST5): $(PATCHES)/$(TEST5).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST5) $(PATCHES)/$(TEST5).o $(MKLIB) $(LIBS)

t6: $(TEST6)
	/bin/time ./$(TEST6)
	$(SNDPLAY) $(TEST6).snd

$(TEST6): $(PATCHES)/$(TEST6).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST6) $(PATCHES)/$(TEST6).o $(MKLIB) $(LIBS)

t7: $(TEST7)
	/bin/time ./$(TEST7)
	$(SNDPLAY) $(TEST7).snd

$(TEST7): $(PATCHES)/$(TEST7).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST7) $(PATCHES)/$(TEST7).o $(MKLIB) $(LIBS)

t8: $(TEST8)
	/bin/time ./$(TEST8)
	$(SNDPLAY) $(TEST8).snd

$(TEST8): $(PATCHES)/$(TEST8).o $(OFILES) $(MKLIB) $(UGLIB)
	cc -o $(TEST8) $(PATCHES)/$(TEST8).o $(MKLIB) $(LIBS)

$(MKLIB):: $(OFILES) $(UGLIB)
	/bin/rm -f $(MKLIB)
	cd uglib; make; cd ..
	/bin/ar  q  $(MKLIB) $(OFILES) uglib/*.o
	ranlib $(MKLIB)

.SUFFIXES: .c .o

.c.o:
	cc -g -I. -c $*.c -o $*.o

clean:
	/bin/rm -f $(MKLIB) *.o *.snd *~ \
		$(TEST1) $(TEST2) $(TEST3) $(TEST4) $(TEST5) $(TEST6) $(TEST7) $(TEST8)
	cd patches; /bin/rm -f *.o
	cd uglib; make clean
