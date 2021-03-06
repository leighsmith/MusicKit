MIXSOUNDS

This directory contains "mixsounds", an example program that mixes
soundfiles based on a scorefile description of the mix.  mixsounds
allows you to set the amplitude scaling of each soundfile and to
change that scaling over time by applying an amplitude envelope. It
allows you to resample (change the pitch of) a file.  It also allows
you to specify that only a portion of a file be used in the mix.
There is no limit to the number of soundfiles that may be mixed
together. Also, the same soundfile may be mixed several times and may
overlap with itself.  The soundfiles may have different sampling rates
and different formats.  However, the output must be 16 bit linear.
The mix is done on the main CPU, rather than the DSP.  The more files
you mix, the longer it will take the program to run.  Note also that
if you mix many large files, you will need a fair degree of swap
space--keep some room free on the disk off of which you booted.

mixsounds is also an illustration of how to make your own Music Kit
Instrument subclass to "realize Notes" in some novel fashion. In this
case, Notes are soundfile mix specifications. They are "realized" by
being mixed into the output file.

To run the program with the file testMix.score as input and writing to the file
testMix.snd type the following to a shell:

        mixsounds testMix.score testMix.snd
        
This file mixes three of the sounds on /NextLibrary/Music/Sounds together into 
a new sound.

You can then play the result, testMix.snd, with the SoundPlayer Demo or the
sndplay command-line program.


SCOREFILE SEMANTICS AND AN EXAMPLE

Mixsounds responds to only two Music Kit noteTypes, noteDur and
noteUpdate with no noteTag.  noteUpdates are used only to set
defaults.  Since many processing algorithms are applied before a mix,
noteUpdates in the middle of a file may not take effect until the next
note.

Mixsounds recognizes the following parameters:

        filename       - The sound file to be read, specified as a string.
        timeOffset     - Time offset into the file to begin reading. E.g.
                                a time offset of 1 means begin 1 second into
                                the file. Note that timeOffset is computed 
				before any pitch change.
        dur            - Duration of the file to use. E.g. a dur of .5
                                means to use only .5 seconds of the file.
                                Note that dur is computed before any pitch 
				change. A dur of 0 means "the whole thing".
        amp            - The amplitude scaling to be applied to the file.
	ampEnv	       - The amplitude envelope. The X values are in seconds.
				The Y values are scaled by the amp parameter.  
				The resulting amplitude is the file amplitude
				multipled by amp multiplied by ampEnv.
				Note that the way ampEnv is applied depends
				on ampEnvTimeScale.
	ampEnvTimeScale - If this parameter is 0 or not present, ampEnv is
				applied before any pitch change. Thus, the
				times in the envelope refer to the times in the
				original file. If this parameter is 1, ampEnv 
				is applied after any pitch change.  If this 
				parameter is 2, ampEnv times are scaled to 
				exactly fit the	selected file segment.
	freq1	       - New assumed fundamental frequency. Must be 
				accompanied by freq0.
	freq0	       - Old assumed fundamental frequency. Must be
				accompanied by freq1.
	bearing	       - This parameter is relevant only when mixing a mono
				file into a stereo mix.  It represents the
				right/left panning of the signal and is in the
				range (-45:45).

An example will help clarify how these parameters work. First let's write out
one of the example .score files as a .snd file. We use the command-line utility
playscore. To a shell, type the following:

        playscore -w Examp1.aiff Examp1.score

Now, here's the contents of testMix2.score, which mixes Examp1.aiff with itself
and other example soundfiles.

        part p1; /* We use only one part. The part is not relevant in this 
                    program because we mix all parts together in the output
                    file. */

	envelope aEnv = [(0,1)(1.9,1)(2,0)];

        BEGIN;
        /* First, here's an 'echo' effect. We use the first 2 seconds of 
	   Examp1.aiff */
        p1 (2) soundFile:"Examp1.aiff" amp:.1 ampEnv:aEnv;
        t +.5;
        p1 (2) soundFile:"Examp1.aiff" amp:.05 ampEnv:aEnv;
        t +.5;
        p1 (2) soundFile:"Examp1.aiff" amp:.025 ampEnv:aEnv;
        t +.5;
        p1 (2) soundFile:"Examp1.aiff" amp:.01 ampEnv:aEnv;
        t + 4;
        p1 (0) soundFile:"/Next/Library/Sounds/Frog.snd" amp:.1;
        /* A duration of 0 means 'the whole thing' */

ADDING AN ENVELOPE TO A FILE

Envelopes are simple Music Kit envelopes, where the time is in seconds.
Example:

        part p1;
        BEGIN;
        p1 (8) soundFile:"Examp1.aiff" amp:.1 ampEnv:[(0,0)(1,1)(2,.1)(8,0)]
		timeOffset:.4;
	/* Note that the times in the ampEnv applied BEFORE the file has
           been adjusted as specifed in the timeOffset.  For example, in 
	   this case, the envelope (and the sound) begin .4 seconds into
	   the file and the envelope goes to zero 8.4 seconds into the file.
	   See ampEnvTimeScale above.
	*/
	END;

CHANGING THE PITCH OF A FILE

This is a little tricky because it also changes the length of the
file.  The important thing to rememeber is that the duration and
timeOffset parameters, as well as the amplitude envelope are applied
before the pitch/time change is made, by default.  For example, if a
file is raised an octave, it gets twice as short.

Example:

        part p1;
        BEGIN;
        p1 (8) soundFile:"Examp1.aiff" amp:.1 freq0:440 freq1:880; /* 8va */
	END;

HINTS

Keep in mind that to prevent overflow distortion, the sum of the
amplitudes of all files that overlap at any one time must be less than
1. A good rule of thumb is to set each file's amp parameter to the
reciprocal of the total number of files that overlap at any one time.
A simple program called "maxamp" is provided to check the maximum amplitude.

Also remember that you will get a click if a soundfile enters or
leaves the mix when its amplitude is not 0. To avoid clicks, you must
select carefully the portion of the soundfile you use.

Mixsounds was written by David Jaffe, with Michael McNabb adding the
enveloping and pitch transposition, the latter based on code provided
by Julius Smith.  The source to the pitch transposition is not currently
available.

EXTENDING MIXSOUNDS

To add your own processing routines and parameters, copy the mixsounds
directory, open the file MixInstrument.m and search for "###".  Follow
directions in that file.  If you are using mixsounds with Common Music,
you must also create a Common Music "part declaration".  An example
is given in this directory as cm-part.lisp.

USING MIXSOUNDS WITH COMMON MUSIC

Common Music supports Mixsounds.  However, this version of Mixsounds contains
parameters not in the original version so a special Common Music file is 
needed.  See cm-part.lisp on this directory.  Substitute this file for the
common-music/mk/mixsounds.lisp file and make common music.  Alternatively,
chage the name of the part in cm-part.lisp and use the new part name.
An example file to access mixsounds from common music is given in 
common-music-example.lisp.

BUGS

mixsounds can eat up swap space if you try to mix a large number of
file on top of one another or if you have very long files and are
changing pitch.  This is because mixsounds does its operations in
memory (with the exception of writing out the final mix.)  It would be
*very* nice to fix this problem, but it's not trivial.

