#          allpass.cpp comb.cpp reverbBridge.cpp revmodel.cpp #SndMeter.m
#.SUFFIXES: .cpp

#shared_obj/ix86/linux-gnu/gnu-gnu-gnu/%.o : ../%.cpp
%.o : ../%.cpp
	$(CC) -c $(ALL_CPPFLAGS) $(ALL_OBJCFLAGS) -o $(GNUSTEP_OBJ_DIR)/$@ $<


include $(GNUSTEP_MAKEFILES)/common.make

all: $(GNUSTEP_OBJ_DIR) $(GNUSTEP_OBJ_DIR)/subproject.o

build-headers:

clean:
	-rm -Rf $(GNUSTEP_OBJ_DIR) *.o

install:

OBJECTS = allpass.o comb.o \
              reverbBridge.o revmodel.o
CPP_OBJECTS = $(addprefix $(GNUSTEP_OBJ_DIR)/,$(OBJECTS))

$(GNUSTEP_OBJ_DIR):
	$(MKDIRS) $(GNUSTEP_OBJ_DIR)

$(GNUSTEP_OBJ_DIR)/subproject.o: $(OBJECTS)
	$(CC) -nostdlib -r -o $@ $(CPP_OBJECTS)
