# Note that it is the makefile (small m that gets invoked by make)
# It in turn invokes this Makefile
#
# Modifcation history
# DAJ/July 10, 90 - Changed install to strip the binary.
# DAJ/July 26, 90 - Removed chmod u+s
# DAJ/Aug 13, 90 - Added chmod u+s again (because of fixed priority policy)
# DAJ/Aug 13, 90 - Flushed installing of man pages
# DAJ/Sept 26, 90 - Added scorefiles.user_bom in installsrc and install
# DAJ/Jan 8, 91 - Changed install rules and LIBS1 to support dynamic linking
# JOS/May 23, 92 - Changed /usr/bin to /usr/local/bin
# DAJ/June 2, 92 - Changed libraries to not be shlib.
# DAJ/Oct 11, 92 - Enabled install of man pages
# DAJ/Sep 7, 94 - added -lDriver for intel

# Installation directories
BINDIR = $(DSTROOT)/usr/local/bin
RELNOTES_DIR = ${DSTROOT}/usr/local/man/man1
BOMDIR = $(DSTROOT)/usr/local/BOMs

# Source files for this application. 
MFILES1 = playscore.m
MFILES2 = convertscore.m

#
# Libraries used by this application.
#

# We supply the -u flag for libNeXT_s and libsys_s to make sure
# that their symbols are available to dynamically loaded SynthPatches
LIBS1 = -lsynthpatches -lunitgenerators -lmusickit -ldsp \
	-u libNeXT_s -lNeXT_s -u libsys_s -lDriver

# Add the SynthPatches and UnitGenerators that you want loaded here.
# We load all the UnitGenerators so that any UnitGenerators referenced
# by dynamically loaded SynthPatches will be found.
LIBFLAGS1 = -u .objc_class_name_Simp \
	-u .objc_class_name_Wave1 \
	-u .objc_class_name_Wave1v \
	-u .objc_class_name_DBWave1v \
	-u .objc_class_name_Wave1i \
	-u .objc_class_name_Wave1vi \
	-u .objc_class_name_DBWave1vi \
	-u .objc_class_name_DBWave2vi \
	-u .objc_class_name_Fm1 \
	-u .objc_class_name_Fm1v \
	-u .objc_class_name_Fm1i \
	-u .objc_class_name_Fm1vi \
	-u .objc_class_name_Fm2pvi \
	-u .objc_class_name_Fm2pnvi \
	-u .objc_class_name_Fm2cvi \
	-u .objc_class_name_Fm2cnvi \
	-u .objc_class_name_DBFm1vi \
	-u .objc_class_name_Pluck \
	-u .objc_class_name_Shape \
	-u .objc_class_name_Shapev \
	-u .objc_class_name_Add2UG \
	-u .objc_class_name_InterpUGyyyy \
	-u .objc_class_name_OscgafUGyyyx\
	-u .objc_class_name_Add2UGxxx \
	-u .objc_class_name_Mul1add2UG \
	-u .objc_class_name_OscgafUGyyyy\
	-u .objc_class_name_Add2UGxxy \
	-u .objc_class_name_Mul1add2UGxxxx \
	-u .objc_class_name_OscgafiUG\
	-u .objc_class_name_Add2UGxyx \
	-u .objc_class_name_Mul1add2UGxxxy \
	-u .objc_class_name_OscgafiUGxxxx\
	-u .objc_class_name_Add2UGxyy \
	-u .objc_class_name_Mul1add2UGxxyx \
	-u .objc_class_name_OscgafiUGxxxy\
	-u .objc_class_name_Add2UGyxx \
	-u .objc_class_name_Mul1add2UGxxyy \
	-u .objc_class_name_OscgafiUGxxyx\
	-u .objc_class_name_Add2UGyxy \
	-u .objc_class_name_Mul1add2UGxyxx \
	-u .objc_class_name_OscgafiUGxxyy\
	-u .objc_class_name_Add2UGyyx \
	-u .objc_class_name_Mul1add2UGxyxy \
	-u .objc_class_name_OscgafiUGxyxx\
	-u .objc_class_name_Add2UGyyy \
	-u .objc_class_name_Mul1add2UGxyyx \
	-u .objc_class_name_OscgafiUGxyxy\
	-u .objc_class_name_Allpass1UG \
	-u .objc_class_name_Mul1add2UGxyyy \
	-u .objc_class_name_OscgafiUGxyyx\
	-u .objc_class_name_Allpass1UGxx \
	-u .objc_class_name_Mul1add2UGyxxx \
	-u .objc_class_name_OscgafiUGxyyy\
	-u .objc_class_name_Allpass1UGxy \
	-u .objc_class_name_Mul1add2UGyxxy \
	-u .objc_class_name_OscgafiUGyxxx\
	-u .objc_class_name_Allpass1UGyx \
	-u .objc_class_name_Mul1add2UGyxyx \
	-u .objc_class_name_OscgafiUGyxxy\
	-u .objc_class_name_Allpass1UGyy \
	-u .objc_class_name_Mul1add2UGyxyy \
	-u .objc_class_name_OscgafiUGyxyx\
	-u .objc_class_name_AsympUG \
	-u .objc_class_name_Mul1add2UGyyxx \
	-u .objc_class_name_OscgafiUGyxyy\
	-u .objc_class_name_AsympUGx \
	-u .objc_class_name_Mul1add2UGyyxy \
	-u .objc_class_name_OscgafiUGyyxx\
	-u .objc_class_name_AsympUGy \
	-u .objc_class_name_Mul1add2UGyyyx \
	-u .objc_class_name_OscgafiUGyyxy\
	-u .objc_class_name_BiquadUG \
	-u .objc_class_name_Mul1add2UGyyyy \
	-u .objc_class_name_OscgafiUGyyyx\
	-u .objc_class_name_BiquadUGx \
	-u .objc_class_name_Mul2UG \
	-u .objc_class_name_OscgafiUGyyyy\
	-u .objc_class_name_BiquadUGy \
	-u .objc_class_name_Mul2UGxxx \
	-u .objc_class_name_Out1aUG\
	-u .objc_class_name_ConstantUG \
	-u .objc_class_name_Mul2UGxxy \
	-u .objc_class_name_Out1aUGx\
	-u .objc_class_name_ConstantUGx \
	-u .objc_class_name_Mul2UGxyx \
	-u .objc_class_name_Out1aUGy\
	-u .objc_class_name_ConstantUGy \
	-u .objc_class_name_Mul2UGxyy \
	-u .objc_class_name_Out1bUG\
	-u .objc_class_name_DelayUG \
	-u .objc_class_name_Mul2UGyxx \
	-u .objc_class_name_Out1bUGx\
	-u .objc_class_name_DelayUGxxx \
	-u .objc_class_name_Mul2UGyxy \
	-u .objc_class_name_Out1bUGy\
	-u .objc_class_name_DelayUGxxy \
	-u .objc_class_name_Mul2UGyyx \
	-u .objc_class_name_Out2sumUG\
	-u .objc_class_name_DelayUGxyx \
	-u .objc_class_name_Mul2UGyyy \
	-u .objc_class_name_Out2sumUGx\
	-u .objc_class_name_DelayUGxyy \
	-u .objc_class_name_OnepoleUG \
	-u .objc_class_name_Out2sumUGy\
	-u .objc_class_name_DelayUGyxx \
	-u .objc_class_name_OnepoleUGxx \
	-u .objc_class_name_ScaleUG\
	-u .objc_class_name_DelayUGyxy \
	-u .objc_class_name_OnepoleUGxy \
	-u .objc_class_name_ScaleUGxx\
	-u .objc_class_name_DelayUGyyx \
	-u .objc_class_name_OnepoleUGyx \
	-u .objc_class_name_ScaleUGxy\
	-u .objc_class_name_DelayUGyyy \
	-u .objc_class_name_OnepoleUGyy \
	-u .objc_class_name_ScaleUGyx\
	-u .objc_class_name_DswitchUG \
	-u .objc_class_name_OnezeroUG \
	-u .objc_class_name_ScaleUGyy\
	-u .objc_class_name_DswitchUGxx \
	-u .objc_class_name_OnezeroUGxx \
	-u .objc_class_name_Scl1add2UG\
	-u .objc_class_name_DswitchUGxy \
	-u .objc_class_name_OnezeroUGxy \
	-u .objc_class_name_Scl1add2UGxxx\
	-u .objc_class_name_DswitchUGyx \
	-u .objc_class_name_OnezeroUGyx \
	-u .objc_class_name_Scl1add2UGxxy\
	-u .objc_class_name_DswitchUGyy \
	-u .objc_class_name_OnezeroUGyy \
	-u .objc_class_name_Scl1add2UGxyx\
	-u .objc_class_name_DswitchtUG \
	-u .objc_class_name_OscgUG \
	-u .objc_class_name_Scl1add2UGxyy\
	-u .objc_class_name_DswitchtUGxx \
	-u .objc_class_name_OscgUGxx \
	-u .objc_class_name_Scl1add2UGyxx\
	-u .objc_class_name_DswitchtUGxy \
	-u .objc_class_name_OscgUGxy \
	-u .objc_class_name_Scl1add2UGyxy\
	-u .objc_class_name_DswitchtUGyx \
	-u .objc_class_name_OscgUGyx \
	-u .objc_class_name_Scl1add2UGyyx\
	-u .objc_class_name_DswitchtUGyy \
	-u .objc_class_name_OscgUGyy \
	-u .objc_class_name_Scl1add2UGyyy\
	-u .objc_class_name_InterpUG \
	-u .objc_class_name_OscgafUG \
	-u .objc_class_name_Scl2add2UG\
	-u .objc_class_name_InterpUGxxxx \
	-u .objc_class_name_OscgafUGs \
	-u .objc_class_name_Scl2add2UGxxx\
	-u .objc_class_name_InterpUGxxxy \
	-u .objc_class_name_OscgafUGxxxx \
	-u .objc_class_name_Scl2add2UGxxy\
	-u .objc_class_name_InterpUGxxyx \
	-u .objc_class_name_OscgafUGxxxy \
	-u .objc_class_name_Scl2add2UGxyx\
	-u .objc_class_name_InterpUGxxyy \
	-u .objc_class_name_OscgafUGxxyx \
	-u .objc_class_name_Scl2add2UGxyy\
	-u .objc_class_name_InterpUGxyxx \
	-u .objc_class_name_OscgafUGxxyy \
	-u .objc_class_name_Scl2add2UGyxx\
	-u .objc_class_name_InterpUGxyxy \
	-u .objc_class_name_OscgafUGxyxx \
	-u .objc_class_name_Scl2add2UGyxy\
	-u .objc_class_name_InterpUGxyyx \
	-u .objc_class_name_OscgafUGxyxy \
	-u .objc_class_name_Scl2add2UGyyx\
	-u .objc_class_name_InterpUGxyyy \
	-u .objc_class_name_OscgafUGxyyx \
	-u .objc_class_name_Scl2add2UGyyy\
	-u .objc_class_name_InterpUGyxxx \
	-u .objc_class_name_OscgafUGxyyy \
	-u .objc_class_name_SnoiseUG\
	-u .objc_class_name_InterpUGyxxy \
	-u .objc_class_name_OscgafUGyxxx \
	-u .objc_class_name_SnoiseUGx\
	-u .objc_class_name_InterpUGyxyx \
	-u .objc_class_name_OscgafUGyxxy \
	-u .objc_class_name_SnoiseUGy\
	-u .objc_class_name_InterpUGyxyy \
	-u .objc_class_name_OscgafUGyxyx \
	-u .objc_class_name_UnoiseUG\
	-u .objc_class_name_InterpUGyyxx \
	-u .objc_class_name_OscgafUGyxyy \
	-u .objc_class_name_UnoiseUGx\
	-u .objc_class_name_InterpUGyyxy \
	-u .objc_class_name_OscgafUGyyxx \
	-u .objc_class_name_UnoiseUGy\
	-u .objc_class_name_InterpUGyyyx \
	-u .objc_class_name_OscgafUGyyxy \
	-u .objc_class_name_TablookiUGxxx \
	-u .objc_class_name_TablookiUGxxy \
	-u .objc_class_name_TablookiUGxyx \
	-u .objc_class_name_TablookiUGxyy \
	-u .objc_class_name_TablookiUGyxx \
	-u .objc_class_name_TablookiUGyxy \
	-u .objc_class_name_TablookiUGyyx \
	-u .objc_class_name_TablookiUG\
	-u .objc_class_name_TablookiUGyyy

# LIBFLAGS1 =

LIBS2 = -lmusickit -lNeXT_s -lsys_s -lDriver
LIBFLAGS2 =
#
# Flags to pass on to the compiler and linker.
#
NEEDED_INCDIR = $(DSTROOT)/LocalDeveloper/Headers
NEEDED_LDIR = $(DSTROOT)/usr/local/lib

# CFLAGS =  -O -I$(NEEDED_INCDIR) -L../dsp/src/lib -L../musickit $(RC_CFLAGS)
CFLAGS =  -O -I$(NEEDED_INCDIR) -L$(NEEDED_LDIR) $(RC_CFLAGS)
#
# Rules.
#
MAKEFILES = Makefile makefile

SRCFILES = $(MFILES1) $(MFILES2) $(MAKEFILES)
DERIVED = $(PSWFILES:.psw=.c) 
GARBAGE = $(DERIVED) core errs 

all: playscore convertscore

playscore: playscore.o
	${CC} ${CFLAGS} -o $@ playscore.o ${LIBS1} ${LIBFLAGS1}

convertscore: convertscore.o
	${CC} ${CFLAGS} -o $@ convertscore.o ${LIBS2} ${LIBFLAGS2}

installsrc: $(SRCROOT)
	tar cf - $(SRCFILES) | (cd $(SRCROOT); tar xf -)
	chmod 664 $(SRCROOT)/*
	cp -p playscore.1 $(SRCROOT)
	chmod 775 playscore.1 
	cp -p convertscore.1 $(SRCROOT)
	chmod 775 convertscore.1 
	
install: $(BINDIR) playscore convertscore 
	cp playscore playscore.tmp
	strip -A -S playscore
	install -m 755 playscore $(BINDIR)
	rm playscore
	mv playscore.tmp playscore
	install -s -m 755 convertscore $(BINDIR)
	install -m 664 playscore.1 $(RELNOTES_DIR)
	install -m 664 convertscore.1 $(RELNOTES_DIR)

installhdrs:
	echo 'No headers to install for scorefiles project' >/dev/null

clean: 
	-rm -f *.o playscore convertscore $(DERIVED) $(GARBAGE) 

help: 
	@echo '  make $(NAME) - to make the application'
	@echo '  make clean -    to remove all files but the source'


$(SRCROOT) $(BINDIR) $(DSTROOT): foobar
	mkdirs -m 775 $@

foobar:

ARCHS=m68k i386
ARCHIFY = /usr/lib/arch_tool -archify_list
arch_flags=`$(ARCHIFY) $(ARCHS)`

fat_install:
	make $(MF) install DSTROOT=$(DSTROOT) "RC_CFLAGS = $(arch_flags)"

fat_debug_install:
	make $(MF) debug_install DSTROOT=$(DSTROOT) "RC_CFLAGS = $(arch_flags)"
