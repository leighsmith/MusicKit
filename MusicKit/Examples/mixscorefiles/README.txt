This example program mixes any number of scorefiles. 
It parses and evaluates each input file and merges its output with that of the other input files. 
The scorefiles may be in either optimized (.playscore) or text (.score) form.

The program allows the option of specifying a particular portion of each file to be used as well as a time offset.

Let's imagine that you have two scorefiles called file1.score and file2.score. To mix them, you say, to the shell: 

	mixscorefiles -i file1.score -i file2.score -o outputFile.score

You may also specify that only a portion of a file be selected. 
You do this with the -f ("first") and -l ("last") switches. Finally, you can shift the times with a -s switch. 

For example, to select the notes between time .2 and 2 (inclusive) and shift them by 1, do the following: 

	mixscorefiles -i file1.score -f .2 -l 2 -s 1 -o outputFile.score

The -f, -s and -l arguments apply to the preceeding file in the list.
Consider the following example:

	mixscorefiles -i file1.score -f .2 -i file2.score -f 1 -o outputFile.score

This means "mix file1.score from .2 to the end of the file with file2.score from 1 to the end of the file
and write the result into the outputFile.score".

Example scorefiles you can use with this program may be found on the directory /Local/Library/Music/Scores. 

There are some special considerations when mixing scorefiles.  If you mix two scorefiles, each of which uses
the DSP to its fullest, and you mix the results so they are overlapping, the result will not be playable,
because it would require more synthesis power than the DSP can provide.  In this case, you can use playscore
to write each file out as a soundfile and then use the mixsounds programming example to mix them.  

Beware of parts that allocate SynthPatches in the header (using the setSynthPatchCount: parameter of the info
statement). Such parts claim the SynthPatces for the entire performance.  For example, consider a file that
uses the DSP to its fullest and allocates all its SynthPatches in the header.  Even if you mix this file onto
itself such that there are no overlaps, the Music Kit will try and allocate all the SynthPatches before the
performance and the allocation will fail.  If you have an optimized (.playscore) scorefile and would like to
see how its header is constructed, you can use the "convertscore" utility, which lives on /usr/local/bin.

EXAMPLE

Try this:

mixscorefiles -i /Local/Library/Music/Scores/Emma.score -i /Local/Library/Music/Scores/Emma.score -s 2.5 -o round.score 

Then edit round.score and remove parameter "synthPatchCount:1," from each part info statement.  Then play it
with playscore or ScorePlayer.
