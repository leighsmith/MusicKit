
# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	playsndfaders
	
ADDITIONAL_TOOL_LIBS += -lMKPerformSndMIDI -lSndKit -lgnustep-base -lst -ljpeg

ADDITIONAL_CFLAGS += -g


playsndfaders_LIBRARIES_DEPEND_UPON += -lSndKit -lgnustep-base -lst -lobjc

ifneq (mingw32, $(GNUSTEP_HOST_OS))
  ADDITIONAL_TOOL_LIBS += -lgnustep-gui -lmp3lame -lshout
  playsndfaders_LIBRARIES_DEPEND_UPON +=  -lgnustep-gui
else
  ADDITIONAL_LIB_DIRS = -Ld:/cygwin/usr/local/lib
  ADDITIONAL_FLAGS += -Id:/cygwin/usr/local/include
  playsndfaders_LIBRARIES_DEPEND_UPON += -Ld:/cygwin/usr/local/lib
endif

# The Objective-C source files to be compiled
playsndfaders_OBJC_FILES = main.m

SRCS = $(TEST_TOOL_NAME:=.m)

HDRS =

DIST_FILES = $(SRCS) $(HDRS)

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include Makefile.postamble
