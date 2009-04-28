This directory contains an example program to play a scorefile on the
DSP from standard input.  The program allows you to set the SynthPatch
class to be used for each Part, choosen from a predefined set of
SynthPatches.  You can also create your own classes and link them into
the example.

playscorefile2 reads the scorefile as it is played.  This has the
advantage that it reduces the start-up time for substantially large
scorefiles, as compared to reading the scorefile before it is played.
However, this puts a greater load on the host CPU, and thus may cause
timing inacuracies in the performance.  In such cases you may need to
read the scorefile first.  See the programing example "playscorefile"
to see how to do this.

playscorefile2 decides which DSP instrument (SynthPatch) to use, as
well as other configuration information based on the 'info' statements
in the scorefile. (This is not required by the Music Kit, but it is a
reasonable convention supported by this example program.)  The set of
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
2. Add it to the Makefile
3. Remake the example.

For an example of how to make your own synthpatch, see exampsynthpatch.

