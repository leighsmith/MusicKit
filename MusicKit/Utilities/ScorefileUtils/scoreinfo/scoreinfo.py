#!/usr/bin/python
# $Id$
#
# Print a summary of a score or MIDI file including number of parts,
# name, tempo, synthPatches etc.
#
# A demonstration of a python script bridging to the MusicKit.
#
# Inspired by the pyobjc Hello World example by Steve Majewski <sdm7g@Virginia.EDU>
#

# You can look up these classes and methods in the Cocoa docs.
# A quick guide to runtime name mangling:
#
#      ObjC 		becomes 	  Python
#    [ obj method ]   			obj.method()
#    [ obj method: arg ]  		obj.method_(arg)
#    [ obj method: arg1 withOtherArgs: arg2 ] 
#				obj.method_withOtherArgs_( arg1, arg2 )

import sys
import string
import pyobjc
rt = pyobjc.runtime	# shorthand -- runtime gets used a lot!

def main():

    pool = rt.NSAutoreleasePool()

    # Load MusicKit Framework
    rt.NSBundle.bundleWithPath_('/Library/Frameworks/MusicKit.framework').load()

    # need to read these from params.h
    MK_tempo = 148
    MK_title = 145
    MK_synthPatch = 141
    MK_midiChan = 143

    # create a score object, read the MIDI or scorefile in
    score = rt.MKScore.new()

    extension = string.split(sys.argv[1], '.')
    if extension.pop() == 'midi':
        score.readMidifile_(sys.argv[1])
    else:
        score.readScorefile_(sys.argv[1])

    scoreInfoNote = score.infoNote()

    if scoreInfoNote.isParPresent_(MK_title):
	print 'Title: ', scoreInfoNote.parAsString_(MK_title)

    if scoreInfoNote.isParPresent_(MK_tempo):
	print 'Tempo: ', scoreInfoNote.parAsDouble_(MK_tempo)

    parts = score.parts()
    print 'Parts: ', parts.count();

    for part in parts:
        partInfoNote = part.infoNote()
        notes = part.notes()
        if not notes.count():
            continue
        if partInfoNote.isParPresent_(MK_title):
            print 'title: ', string.ljust(partInfoNote.parAsString_(MK_title), 30),
        if partInfoNote.isParPresent_(MK_synthPatch):
            print 'synthPatch: ', partInfoNote.parAsString_(MK_synthPatch),
        # collect all MIDI channels used per part
        channelsUsedInPart = []
        for note in notes:
            if note.isParPresent_(MK_midiChan):
                midiChan = note.parAsInt_(MK_midiChan)
                if midiChan not in channelsUsedInPart:
                    channelsUsedInPart.append(midiChan)
        else:
            print 'MIDI channels: ', channelsUsedInPart
        
    # partPerformer.noteSender().connect_(midi.channelNoteReceiver_(midiChan))



if __name__ == '__main__' : main()


