
# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

# The tools to be compiled
TOOL_NAME = \
	playsndfaders
	
ADDITIONAL_TOOL_LIBS += -lSndKit

ADDITIONAL_CFLAGS += -g

ifeq (mingw32, $(GNUSTEP_HOST_OS))
  ADDITIONAL_LIB_DIRS = -Ld:/cygwin/usr/local/lib
  ADDITIONAL_FLAGS += -Id:/cygwin/usr/local/include
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
