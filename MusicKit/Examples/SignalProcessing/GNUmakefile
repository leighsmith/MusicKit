include $(GNUSTEP_MAKEFILES)/common.make

OBJCFLAGS += -Wall

APP_NAME = SignalProcessing

SignalProcessing_RESOURCE_FILES = English.lproj

SignalProcessing_HEADERS = \
	SignalProcessingController.h \
	SndStreamInput.h

SignalProcessing_OBJC_FILES = \
	SignalProcessing_main.m \
	SignalProcessingController.m \
	SndStreamInput.m

ADDITIONAL_TOOL_LIBS += -lSndKit

SignalProcessing_MAIN_MODEL_FILE = SignalProcessing

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
