// Should definitely be the Model, so will we need a Controller?
@interface Segment: NSObject
{
  MIDIContinuousController *pickController;
  id pickPosition1;   // Nearest the Bridge
  pickValue1;
  id pickPosition2;   // Nearest the Neck
  pickValue2;
  MIDIContinuousController *panPosition;
  panSpread;
  MIDIContinuousController *reverb;
  programNumber;
  volume
  transpose
  quantize;
  BOOL fingerPick;
  velocitySensitivity;
  velocityOffset;
  triggerLevel;
}

- encode;			// create a segment worth of MIDI message

/*
ARRANGE SEGMENT
Byte  1: #F0      -- SYSEX
Byte  2: #00      -- ID header
Byte  3: #20      -- 1st byte of manufacturer's ID
Byte  4: #2D      -- 2nd byte of manufacturer's ID
Byte  5: #0C      -- model  ID : AXON NGC77 5.xx
Byte  6: #00      -- device ID : single, else not evaluated
Byte  7: #02      -- address high; ARRANGE SEGMENT
Byte  8: #nn      -- address mid; segment number (0..12)
Byte  9: #xx      -- address low
Byte 10: data.l   -- lower 7 bits
Byte 11: data.h   -- upper 1 bit
Byte 12: #F7      -- EOX

#xx: #02: PROGRAM NO.
#xx: #00: BANK MSB
#xx: #01: BANK LSB
#xx: #03: VOLUME
#xx: #04: TRANSPOSE
#xx: #05: QUANTIZE
#xx: #06: PAN POS
#xx: #07: PAN SPREAD
#xx: #08: REVERB
#xx: #20: FINGER PICK
#xx: #0C: VELOCITY SENS
#xx: #21: VELOCITY OFFS
#xx: #22: TRIGGER LEVEL
#xx: #0D: PICK CONTROL
#xx: #0E: P1 POSITION
#xx: #0F: P1 VALUE
#xx: #10: P2 POSITION
#xx: #11: P2 VALUE
*/
