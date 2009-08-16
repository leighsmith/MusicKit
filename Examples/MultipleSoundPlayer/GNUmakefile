include $(GNUSTEP_MAKEFILES)/common.make
 
OBJCFLAGS += -Wall
 
APP_NAME = MultipleSoundPlayer
 
MultipleSoundPlayer_RESOURCE_FILES = English.lproj
 
MultipleSoundPlayer_HEADERS =
 
MultipleSoundPlayer_OBJC_FILES = \
	MultipleSoundPlayer_main.m \
	SoundPlayerController.m

ADDITIONAL_TOOL_LIBS += -lSndKit                                                                                                                
MultipleSoundPlayer_MAIN_MODEL_FILE = MultipleSoundPlayer
 
-include GNUmakefile.preamble
 
-include GNUmakefile.local
 
include $(GNUSTEP_MAKEFILES)/application.make
 
-include GNUmakefile.postamble
