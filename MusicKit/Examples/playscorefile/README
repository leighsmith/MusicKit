This directory contains an example program to play a scorefile on the
DSP from standard input.  The program allows you to set the SynthPatch
class to be used for each Part, choosen from a predefined set of
SynthPatches.  All of the NeXT-supplied SynthPatches are loaded.
You can also create your own classes and link them into the example. 

playscorefile reads the scorefile first and then plays it.  For
substantially large scorefiles, it can be annoyingly long to read the
file before playing it. An alternative implementation is to read the
scorefile as you play it. See the programing example "playscorefile2"
to see how to do this.

playscorefile decides which DSP instrument (SynthPatch) to use, as
well as other configuration information based on the 'info' statements
in the scorefile. (This is not required by the Music Kit, but it is a
reasonable convention supported by this example program.) The set of
SynthPatches linked to playscorefile is specified in the LDFLAGS line
in the Makefile. You may change this line to link other SynthPatches.

In particular, the following scorefile info statement parameters are used

   headroom 
   samplingRate
   tempo

The following part info statement parameters are used

   synthPatch
   synthPatchCount

To run the program with the file /NextLibrary/Music/Scores/Examp7.score:

	playscorefile <  /NextLibrary/Music/Scores/Examp7.score
	
If you do not get the results you expect, you may want to turn on
tracing of various Music Kit information. You do this by specifying a
numeric argument after -t. The bits are defined in
<musickit/errors.h>.  For example,

	playscorefile -t 32 <  /NextLibrary/Music/Scores/Examp7.score

will print out voice allocation statistics.

To add your own SynthPatch class to playscorefile, you must do the following:

1. Create the SynthPatch class.
2. Add it to the Makefile. 
3. Remake the example.

For an example of how to make your own synthpatch, see exampsynthpatch.


