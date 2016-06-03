Description
===========

MusicKit
The MusicKit is an object-oriented software system for building music,
sound, signal processing, and MIDI applications. It has been used in
such diverse commercial applications as music sequencers, computer
games, and document processors. Professors and students in academia have
used the MusicKit in a host of areas, including music performance,
scientific experiments, computer-aided instruction, and physical
modeling. The MusicKit was the first to unify the MIDI and Music V
paradigms, thus combining interaction with generality (Music V, written
by Max Mathews and others at Bell Labs four decades ago, was the first
widely available LDQUOcomputer music compilerRDQUO).

The NeXT MusicKit was first demonstrated at the 1988 NeXT product
introduction and was bundled in NeXT software releases 1.0 and 2.0.
Beginning with NeXT's 3.0 release, the MusicKit was no longer part of
the standard NeXT software release. Instead, it was being distributed
and supported as Version 4.0 by the Center for Computer Research in
Music and Acoustics (CCRMA) of Stanford University. Versions 5.0 to
5.4.1 were then supported by tomandandy music, porting to several more
[popular operating systems](#platforms).

The [MusicKit Distribution](#downloads) is a comprehensive package that
includes [on-line documentation](#onlinedoco), [programming
examples](#examples), [utilities, applications](#applications) and
sample score documents. The MusicKit is dependent on the SndKit
distribution, originally written by Stephen Brandon, and both Framework
collections are available at the same distribution site. The SndKit was
written to be a complete open source implementation of NeXTs SoundKit.
The re-write started and almost finished before the SoundKit itself was
released in source code form.

Source code is available for everything, with the exception of the NeXT
hardware implementation of the low-level sound and DSP drivers. This
means researchers and developers may study the source or even customize
the Music Kit and DSP tools to suit their needs. Enhancements can be
committed to the [Subversion repository](#fixes) to have them
incorporated for future releases. Commercial software developers may
freely incorporate and adapt the software to accelerate development of
software products.

Feature List {#features}
------------

The following is a partial list of the highlights of the MusicKit
provided by David Jaffe on his [web-page](#otherlinks):

-   Extensible, high-level object-oriented frameworks that are a
    super-set of Music V and MIDI paradigms.

-   Applicable to composers writing real-time computer
    music applications.

-   Applicable to programmers writing cross-platform
    audio/music applications.

-   Written in Objective C and C, using Apple's OpenStep/Cocoa API.

-   Using the Python to Objective C bridge
    [PyObjC](http://www.sourceforge.net/projects/pyobjc) enables
    applications and utilities to be written in
    [Python](http://www.python.org), an interpreted
    object-oriented language.

-   Functionally comparable (although architecturally dissimilar) to
    JMSL (Java Music Specification Language).

-   Representation system capable of depicting phrase-level structure
    such as legato transitions.

-   General time management/scheduling mechanism, supporting
    synchronization to MIDI time code.

-   Efficient real-time synthesis and sound processing, including option
    for quadraphonic sound.

-   Complete support for multiple MIDI inputs and outputs.

-   On NeXT machines, digital sound I/O from the DSP port with support
    for NeXT serial port devices.

-   Fully-dynamic DSP resource allocation system with dynamic linking
    and loading, on multiple DSPs.

-   Non-real time mode, where the DSP returns data to the application or
    writes a sound file.

-   Suite of [applications](#applications), including Ensemble MDASH an
    interactive algorithmic composition and performance environment
    (including a built-in sampler), and ScorePlayer MDASH a Scorefile
    and standard MIDI file player.

-   Library of instruments, including FM, wavetable, physical modeling
    and waveshaping synthesis.

-   Library of unit generators for synthesis and sound processing.

-   Documentation, programming examples, utilities, including a sound
    file mixer, sample rate converter, etc.

-   ScoreFile, a textual scripting language for music.

-   Connectable audio processing modules (LDQUOpluginsRDQUO) including
    standard audio effects such as reverb. Support for Apple AudioUnits.

-   Sound data held in a specifiable variety of formats, i.e 8, 16, 24
    bit or floating point. Allows trading off sample data size vs.
    processing time.

-   MP3 file reading and writing. Decoding of MP3 can be done in a
    background thread after reading, or on-the-fly during playback,
    allowing selection of memory consumption versus processor load.

-   MP3 and Ogg/Vorbis streaming of audio output to web servers using
    the [libshout](&libshoutweb;) library. The libshout library license
    is LGPL, not GPL and so do not compromise the MusicKit
    [license](#license)

References at Other Sites {#otherlinks}
-------------------------

The MusicKit is listed on the following web sites and open source
portals:

-   [![](Images/sourceforge.eps){width="50" height="30"}
    sourceforge.net](&mksfweb;) hosts the Subversion repository, news,
    mail lists and web site.

-   [![](Images/freshmeat.eps){width="25" height="15"}
    freshmeat.net](http://www.freshmeat.net/projects/musickit/)

-   [![](Images/advogato.eps){width="25" height="15"}
    advogato.org](http://www.advogato.org/proj/MusicKit%20and%20SndKit/)

-   [CCRMA's
    MusicKit site.](http://ccrma-www.stanford.edu/CCRMA/Overview/hardsoftware.html)

-   [David Jaffe's (the original author)
    MusicKit site.](http://www.jaffe.com/mk97.html)

MusicKit Mail-lists {#maillist}
-------------------

-   Announcements of new releases are sent to the
    <musickit-announceMKLISTS> mail list. Subscribe to the list by
    visiting
    <http://lists.sourceforge.net/mailman/listinfo/musickit-announce>.

-   Discussions on development of the MusicKit and notices of updates
    committed to the Subversion source repository are sent to
    <musickit-developerMKLISTS> mail list. Subscribe to the list by
    visiting
    <http://lists.sourceforge.net/mailman/listinfo/musickit-developer>.

-   Discussions on writing applications using the MusicKit (not
    developing it) are sent to <musickit-usersMKLISTS> mail list.
    Subscribe to the list by visiting
    <http://lists.sourceforge.net/mailman/listinfo/musickit-users>.

Don't assume nothing is being done if you don't hear anything for a
while! The maintainers are usually adding fixes/code, but full releases
are less frequent. The [Subversion repository](#fixes) can be used to
track all updates and obtain them as they are committed by developers.

Further Documentation {#furtherdoco}
=====================

-   Thorough documentation of classes, applications, usage and concepts
    are found under the directory `
    Documentation
    ` in the source distribution.

-   The file [`
    Documentation/MusicKit_ChangeLog.txt
    `](&mkurl;/MusicKit_ChangeLog.txt) lists changes for VMKVERTUPLE and
    is generated from the Subversion logs.

Online Documentation {#onlinedoco}
--------------------

-   [README in PDF](&mkurl;/MusicKit_README.pdf) MDASH This README
    document in the Adobe Portable Document Format (e.g Acrobat).

-   [MusicKit and SndKit Concepts](&mkurl;/Concepts)
    [(PDF version)](&mkurl;/MusicKitConcepts.pdf) MDASH Thorough
    documentation of the MusicKit and SndKit in operation.

-   [MusicKit Tutorials](&mkurl;/TutorialClasses)
    [(PDF version)](&mkurl;/MusicKitTutorials.pdf) MDASH Tutorial
    exercises by David A. Jaffe, used in his lecture series.

-   [Class Documentation](&mkurl;/Frameworks) MDASH Documentation for
    each module, C function and Objective-C class.

### Published Papers {#PublishedPapers}

Conference papers and lecture slides in PDF or HTML are listed in the
[bibliography](#bibliography).

Contributors, History and Acknowledgements {#history}
==========================================

(As best as LMS has determined from written acknowledgements)
-   The MusicKit was designed and implemented by David A. Jaffe, and the
    DSP computer-music and array-processing software was designed and
    implemented by Julius O. Smith III while at NeXT. The SoundKit
    (forerunner of the SndKit) was designed and implemented by
    Lee Boynton. Their original design appeared in JaffeBoynton89.

-   Michael McNabb brought wave table synthesis to the MusicKit and
    designed and built a number of `UnitGenerator` and `SynthPatch`
    subclasses and contributed the Ensemble application.

-   Douglas Fulton was responsibile for the documentation and made
    substantial design improvements in clarifying general protocol and
    the identity and mechanisms of the classes.

-   Gregg Kellogg wrote the DSP, Sound, and MIDI device drivers for the
    NeXT which were then maintained by Doug Mitchell.

-   John Strawn wrote most of the matrix and array processing macros.

-   Dana Massie contributed speech coding, sampling-rate conversion, and
    signal conditioning modules for the Sound Kit.

-   Doug Keislar helped with testing, developer support, and demos.

-   Mike Minnick helped finish the DSP array processing tools and wrote
    most of the programming examples.

-   Roger Dannenberg influenced both the MusicKit noteTag design and the
    design of the performance mechanism (using a data flow discrete
    simulation model).

-   Andy Moorer helped shape the `Envelope` strategy, suggested the
    unit-generator memory-argument scheme, and provided consultation.

-   The software of William Schottstaedt and others at CCRMA
    (Stanford University) served as a model for some of the mechanisms
    in the MusicKit.

-   James A. Moorer, Perry Cook, Rob Poor made code and design
    contributions also.

-   Following NeXT's release of the source to Stanford in 1994, David
    did the port to Intel NeXTStep and the MPU-401 MIDI and DSP drivers.
    There were some other bug fix contributors (acknowledged in
    code comments).

-   Stephen Brandon did the initial OpenStep port in early 1998 and the
    majority of the conversion work. The MusicKit now uses the SndKit,
    written by Stephen, rather than the SoundKit for its
    sound processing.

-   Leigh M. Smith, <> fixed bugs and ported the MusicKit and MIDI
    drivers to Intel and PowerPC Rhapsody in late 1998 and reorganised
    the packages and documentation for MacOS X-Server V1.2 and in 2000,
    to various developer previews of MacOS X. The frameworks were ported
    to Windows 98/NT using DirectMusic in 1999. A [sourceforge
    project](&mksfweb;) was created in 2000.

-   DirectSound interface code for Windows, MP3 encoding, much of the
    initial sound stream design and FX architecture was contributed by
    SKoT McDonald.

-   Keith Hamel tested and helped in bug fixes for the MacOS X version.

-   Matt Rice and Denis Crowdy both made valuable contributions to the
    Linux/portaudio port.

-   Kim Shrier added FreeBSD support.

Supported Platforms {#platforms}
===================

The MusicKit currently runs on the platforms described in
[table\_title](#supportedplatforms):

  Platform                                            MIDI     Sound   DSP
  ------------------------------------------------- --------- ------- -----
  OpenStep 4.2/m68k (NeXT)                              Y        Y      Y
  OpenStep 4.2/Intel (with ISA 56k card)                Y        Y      Y
  Windows XP (using GNUstep)                         Partial     Y      N
  MacOS X-Server V1.0-1.2                               Y        Y      N
  MacOS X                                               Y        Y      N
  Linux/Unix (Using GNUstep, portaudio/portmusic)    Partial     Y      N

  : MusicKit Supported Platforms

Portability
-----------

All the platform specific stuff is located in the `MKPerformSndMIDI`
framework. The MusicKit and SndKit interface to `MKPerformSndMIDI` using
a C API which was originally modelled after some NeXT API (although that
is now history, particularly for streaming audio). There are several
versions of `MKPerformSndMIDI` underneath
`MusicKit/Frameworks/PlatformSpecific`. You only compile one, all the
versions are intended to produce one framework named
`MKPerformSndMIDI.framework` which the MusicKit and SndKit link to.

The two versions under most active development are
`MKPerformSndMIDI_MacOSX` and `MKPerformSndMIDI_portaudio`. The latter
uses the multiplatform [portaudio](http://www.portaudio.com) and
[portmidi](http://portmedia.sourceforge.net/) library to map to the
platform specific API and this is the means to interface with Linux and
Windows platforms.

MacOS X support {#macosx}
---------------

While there is now MacOS X support in portaudio, historically
`MKPerformSndMIDI_MacOSX` existed before it and I've personally
continued to use it to ensure MacOS X support is first class. All MIDI
access is done using CoreMIDI API calls and all sound I/O is done using
CoreAudio.

AudioUnits are supported. `SndAudioUnitProcessor` allows loading and
using existing AudioUnits as a `SndAudioProcessor`, so you will be able
to plug other developers AudioUnits into your SndKit sound processing
stream. The source for AudioUnit processing is located in
`MusicKit/Frameworks/PlatformSpecific/AudioUnits`.

One AudioUnit issue is whether a SndKit program can function as an
AudioUnit. In theory this should be possible once Cocoa apps can draw
their own AudioUnit GUI, however this depends on Apple.

Linux support {#linux}
-------------

Linux/Unix support using the [GNUstep](http://www.gnustep.org) library
is partially completed and looking for more volunteers. A performance
framework (`MKPerformSndMIDI_portaudio.framework`) using the
[portaudio](http://www.portaudio.com) library has been completed,
porting the MusicKit to Intel Linux. Streaming sound I/O and MIDI output
works, but MIDI input needs further work, please help! Potentially other
Unix platforms will work (SGI, Solaris, FreeBSD, AIX etc) if they are
supported in the portaudio library and GNUstep.

### Installing GNUStep {#installinggnustep}

Install GNUStep on your system in the usual fashion, according to the
[build guide](http://wiki.gnustep.org/index.php/User_Guides). You may
find binary packages are available on some Linux distributions such as
[Debian](http://www.debian.org). The following versions of GNUStep
packages are known to work:

[gnustep-make-GSMAKEVERTUPLE.tar.gz](&gnustepdownload;/gnustep-make-&gsmakevertuple;.tar.gz).

:   Install the library using:

    <div class="informalexample">

        tar xzvf gnustep-make-GSMAKEVERTUPLE.tar.gz
        cd gnustep-make-GSMAKEVERTUPLE
        sh ./configure --enable-import
        sudo make install

    </div>

    > **Note**
    >
    > We continue to use `#import` since it has been reinstated
    > according to [this email
    > exchange](http://gcc.gnu.org/ml/gcc/2003-03/msg00269.html). Older
    > `gcc` versions may produce spurious warnings.

[gnustep-base-GSBASEVERTUPLE.tar.gz](&gnustepdownload;/gnustep-base-&gsbasevertuple;.tar.gz).

:   Install the library using:

    <div class="informalexample">

        tar xzvf gnustep-base-GSBASEVERTUPLE.tar.gz
        cd gnustep-base-GSBASEVERTUPLE
        sh ./configure
        sudo make install

    </div>

[gnustep-gui-GSGUIVERTUPLE.tar.gz](&gnustepdownload;/gnustep-gui-&gsguivertuple;.tar.gz).

:   Install the library using:

    <div class="informalexample">

        tar xzvf gnustep-gui-GSGUIVERTUPLE.tar.gz
        cd gnustep-gui-GSGUIVERTUPLE
        sh ./configure --disable-gsnd
        sudo make install

    </div>

Windows support {#windows}
---------------

While other means of using the MusicKit on Windows is possible, the
current recommended approach is using [MinGW](http://www.mingw.org), the
LDQUOMinimal Gnu for WindowsRDQUO, together with
[GNUstep](http://www.gnustep.org) and the `MKPerformSndMIDI_portaudio`
framework.

Currently the GNUstep AppKit support on Windows is incomplete, so your
success running GUI applications will vary. However the MusicKit and
SndKit run fine.

These instructions document the success I have had in getting MinGW,
GNUstep, SndKit and MusicKit and all the supporting libraries compiled
and running on a Windows XP system. Instead of repeating instructions
for installation of each package that is better described by the
package's documentation, I have listed the order and version number of
each package that needs installing and the location of the documentation
file. Please report problems you may encounter in getting things to
build.

### Install MinGW and friends

-   Install the minimal command line GNU system by running
    `MSYS-1.0.10.exe`.

-   Install complier, libraries and headers by running
    `MinGW-3.2.0-rc-3.exe`. Install into the `C:/msys/mingw` location.

    When installing MSYS, ensure that the user name or at least the home
    directory is a single name without a space, as this tends to break
    `configure`. This is further described in GNUstep's
    `gnustep/core/make/Documentation/README.MinGW`

-   Install the [Subversion version control
    system](http://subversion.tigris.org) and other development tools
    with the MSYS developer tool kit `msysDTK-1.0.1.exe`.

### Install libraries supporting GNUstep

-   [zlib-1.2.2.tar.gz](http://www.gzip.org/zlib)

-   [libtiff
    V3.7.2.tar.gz](ftp://ftp.remotesensing.org/pub/libtiff/tiff-3.7.2.tar.gz)
    ./configure --disable-cxx CPPFLAGS=-I/usr/local/include
    LDFLAGS=-L/usr/local/lib

-   You need at least [libiconv
    V1.9.2](http://ftp.gnu.org/gnu/libiconv/libiconv-1.9.2.tar.gz) in
    order to compile (with gcc-3.4.2) on MinGW.

-   [libxml2 V2.6.19](ftp://xmlsoft.org/libxml2-2.6.19.tar.gz).

    <div class="informalexample">

        ./configure --with-iconv=/usr/local --with-zlib=/usr/local

    </div>

-   [libxslt V1.1.14](ftp://xmlsoft.org/libxslt-1.1.14.tar.gz)

-   [ffcall
    V1.10](ftp://ftp.gnustep.org/pub/gnustep/libs/ffcall-1.10.tar.gz)

    <div class="informalexample">

        ./configure --prefix=$GNUSTEP_SYSTEM_ROOT
        make
        make install

    </div>

### Install GNUstep

Read the instructions in `gnustep/core/make/Documentation/README.MinGW`.
I installed GNUstep from the head of the Subversion tree. If you are
working from the head of the Subversion tree also use:

<div class="informalexample">

    . /usr/GNUstep/System/Library/Makefiles/GNUstep.sh

</div>

instead of

<div class="informalexample">

    . /usr/GNUstep/System/Makefiles/GNUstep.sh

</div>

Configure `gnustep-base`

<div class="informalexample">

    ./configure CPPFLAGS=-I/usr/local/include LDFLAGS=-L/usr/local/lib

</div>

Configure the `gnustep-gui` (until `libtiff` can install into the
GNUstep tree):

<div class="informalexample">

    ./configure --with-tiff-library=/usr/local/lib --with-tiff-include=/usr/local/include

</div>

### Installation of Libraries Supporting SndKit

In addition to [installing the common support libraries](#support), the
following steps need to be performed:

-   The Microsoft [DirectX 9.0b
    SDK](http://www.microsoft.com/downloads/details.aspx?displaylang=en&familyid=bc7ddedd-af62-493d-8055-5e57bab71e1a) (free)
    needs to be installed for DirectSound operation.

-   The lame project needs
    [patches](http://sourceforge.net/tracker/index.php?func=detail&aid=809315&group_id=290&atid=300290)
    to compile under MinGW. These patches may soon be incorporated into
    a lame distribution newer than LAMEVERTUPLE.

-   The libshout project needs
    [patches](http://www.xiph.org/archives/icecast-dev/0660.html) to
    compile under MinGW. These patches may soon be incorporated into a
    libshout distribution newer than LIBSHOUTVERTUPLE.

### MIDI on Windows

The `MKPerformSndMIDI_portaudio` framework supports MIDI. The
downloadable sound (DLS) capability of DirectMusic (providing a MIDI
oriented sample playback API to PC soundcards) is also supported when
playing to a DirectMusic software synthesiser. There is minimal but
usable support for downloading new DLS instruments to the software
synthesiser. Eventually this functionality will be managed by
[portmusic](http://www-2.cs.cmu.edu/~music/portmusic/) cross platform in
`MKPerformSndMIDI_portaudio.framework`

Supported Programming Languages {#SupportedLanguages}
===============================

While the MusicKit and SndKit have been written in Objective C, this
does not limit the system's use to that language. In particular, the
dynamic binding of Objective C enables quite straightforward bridging to
interpreters. This enables a relatively slow but LDQUOfriendlyRDQUO (i.e
interactive) interpreter to benefit from the speed, multi-threading and
feature set of the MusicKit and SndKit architectures.

Examples included in the distribution which are written in other
languages include:

`scoreinfo`

:   A command-line tool written in Python to list MIDI channels
    (`MK_midiChan`) used by each part in MIDI or Scorefiles. This
    requires [Python](http://www.python.org) and
    [PyObjC](http://www.sourceforge.net/projects/pyobjc) to
    be installed.

Version numbering of the MusicKit {#VersionNumbering}
=================================

Version numbering of the MusicKit is as follows.

All versions are numbered in the popular standard GNU nomenclature
V.R.P, referred here as a *version tuple*, referring to Version,
Revision and Patch respectively. Version refers to major milestones in a
project, such as a complete rewrite or major internal conversion, major
functional improvement etc. Revision, refers to a minor milestone that
can include new functionality that may break external interfacing
software, forcing them to be updated (minimally a recompile). Patch,
refers to a singular bug fix to correct operation which does not cause
an incompatible change or introduce new behaviour.

Each framework has it's own version tuple. This is encoded in the
framework and is used by the dynamic loader to verify the correct
versions of applications link against the correct versions of
frameworks. However, to allow new framework with patches to be installed
into operational sites without forcing recompiles of the application,
the version tuple encoded in the framework is of the form V.R. Therefore
a new patched framework can be installed over the top of the old same
numbered framework with the knowledge it will continue to work.

Subversion Branch Structure
---------------------------

Different software projects adopt different procedures for dealing with
*branching* of the code base. The MusicKit project currently has few
branches, however this description is an attempt to define a policy for
developers to conform to and to therefore be able to use when retrieving
from the Subversion tree. For example, some projects use branches for
the LDQUObleeding-edgeRDQUO or experimental development, with the
LDQUOheadRDQUO or LDQUOtrunkRDQUO of the code tree being stable.
Successful experiments are then merged back into the head of the main
branch of the tree.

The head of the MusicKit can be considered unstable, but should be
considered to represent a concensus of development strategies. As
explained above, any diverging approaches or experiments will be handled
in sub-branch. Likewise, any patches to an existing release other than
next impending release will be found in a sub-branch.

This can be counter intuitive. For example, when 5.4.1 is the most
recent patch, it is found at the head of the tree. If however,
eventually 5.5.0 was released, and then a patch needed to be made to
5.4.1, to be named 5.4.2, this would need to be made in a sub-branch at
5.4.1. In practice, the amount of branching has proven to be nearly
zero. If indeed it starts to become necessary to simultaneously support
an existing release and an developmental release, this will probably be
at the release of a new version (i.e 5.5.0) and we can properly branch
there. Comments are welcome!

License
=======

Original MusicKit License {#OriginalMKLicense}
-------------------------

The source code as distributed by Stanford (V4.2) included the following
usage message:

> The Music Kit software is distributed free of charge. Copyright
> remains with the owner indicated in each file. The software may be
> freely incorporated into any NeXTStep commercial application, any
> academic application, or any musical composition.
>
> We would appreciate your acknowledging the use of the Music Kit in any
> academic paper, music program notes and application documentation that
> use the Music Kit.

License for MusicKit Post-4.2 Code {#CurrentMKLicense}
----------------------------------

In regard of version VMKVERTUPLE (consitituting all changes and
modifications, porting efforts and documentation beyond V4.2), the
current license follows.

The MusicKit software is distributed free of charge. Copyright remains
with the owner indicated in each file and copyright of the modifications
to each file remains with the contributor of the changes. The software
in this distribution may be freely incorporated into any commercial
application, any academic application, and public domain application or
any musical composition so long as the attribution of authorship of the
software is retained in the original source and documentation files.

By sharing your contributions back to the public domain, this helps
others as well as yourself. It is not intended that your changes be
enforced to be returned to the public domain, but it is hoped that
common sense will prevail and that everyone will realise that reward
does not mean avoiding openness.

We (the contributors to the MusicKit) would appreciate you acknowledging
the use of the MusicKit in any academic paper, music program notes and
application documentation that use the MusicKit or SndKit.

Downloading and Installing the Distribution {#downloads}
===========================================

The MusicKit can be installed from a binary distribution package or
compiled from the source code distribution tarball. In either case,
certain libraries must be preinstalled for the MusicKit to operate.

Installing Supporting Libraries {#support}
-------------------------------

The following libraries need to be installed prior to compiling the
MusicKit source or before attempting to link against the MusicKit
frameworks. These supporting libraries may be installable using
[fink](http://www.sourceforge.net/projects/fink), or they can be
individually downloaded and compiled as described below. Certain
libraries may be optionally omitted (reducing functionality of the
MusicKit) if necessary. These are noted below.

> **Note**
>
> If installing on GNUstep, be sure that `PKG_CONFIG_PATH` is set to
> point to whereever you install the libraries listed below. For
> example, if you do install these in `/usr/local/lib`,
> `PKG_CONFIG_PATH` should be set to `/usr/local/lib/pkgconfig`. See
> `pkg-config` for details.

[libogg-OGGVERTUPLE.tar.gz](&oggdownload;). Status: optional - disables `SndAudioProcessorMP3Encoder` if omitted.; [libvorbis-VORBISVERTUPLE.tar.gz](&vorbisdownload;). Status: optional - disables `SndAudioProcessorMP3Encoder` if omitted.

:   The [Ogg/Vorbis](&oggvorbisweb;) libraries provide patent-free
    Vorbis encoding/decoding of PCM audio to and from Ogg format
    bitstreams for use by [libshout](#libshout). Newer versions than
    OGGVERTUPLE for Ogg and VORBISVERTUPLE for Vorbis will probably
    just work.

    Install the library using:

    <div class="informalexample">

        tar xzvf libogg-OGGVERTUPLE.tar.gz
        cd libogg-OGGVERTUPLE
        sh ./configure
        sudo make install
        cd ..
        tar xzvf libvorbis-VORBISVERTUPLE.tar.gz
        cd libvorbis-VORBISVERTUPLE
        sh ./configure
        sudo make install

    </div>

[libsndfile-LIBSNDFILEVERTUPLE.tar.gz](&libsndfiledownload;). Status: optional - disables `Snd` file I/O and `SndAudioProcessorRecorder` if omitted.

:   The [libsndfile](&libsndfileweb;) sound file I/O library provides
    sound file format conversion. Newer versions than LIBSNDFILEVERTUPLE
    will probably just work.

    Install the library using:

    <div class="informalexample">

        tar xzvf libsndfile-LIBSNDFILEVERTUPLE.tar.gz
        cd libsndfile-LIBSNDFILEVERTUPLE
        sh ./configure
        sudo make install

    </div>

[lame-LAMEVERTUPLE.tar.gz](&lamedownload;). Status: optional - disables `SndAudioProcessorMP3Encoder` if omitted.

:   The [LAME](&lameweb;) library provides MP3
    encoding/decoding capability. Newer versions than LAMEVERTUPLE will
    probably just work.

    Install the library using:

    <div class="informalexample">

        tar xzvf lame-LAMEVERTUPLE.tar.gz
        cd lame-LAMEVERTUPLE
        sh ./configure
        sudo make install

    </div>

[icecast-LIBSHOUTVERTUPLE.tar.gz](&libshoutdownload;). Status: optional - disables `SndAudioProcessorMP3Encoder` if omitted.

:   The libshout library (part of the IceS distribution) of the
    [icecast](&libshoutweb;) project provides the capability to stream
    MP3 or Ogg/Vorbis encoded audio to a broadcast server.

    Install the library using:

    <div class="informalexample">

        tar xzvf icecast-LIBSHOUTVERTUPLE.tar.gz
        cd icecast-LIBSHOUTVERTUPLE
        sh ./configure --without-python --disable-dependency-tracking
        make
        sudo make install

    </div>

[pa\_snapshot\_vPORTAUDIOVERTUPLE.tar.gz](&portaudiodownload;). Status: Needs to be installed on Windows, Linux and other Unixen except for MacOS X, OpenStep/NeXTStep systems.

:   At the moment, the portaudio Subversion repository version is the
    only version that works on MinGW and so `MKPerformSndMIDI_portaudio`
    uses the upcoming VPORTAUDIOVERTUPLE release. Either fetch the
    Subversion snapshot, or using Subversion, checkout the portaudio
    version PORTAUDIOVERTUPLE development branch. On Linux/BSD/SGI etc
    do:

    <div class="informalexample">

        cvs -d:pserver:anonymous@www.portaudio.com:/home/cvs co -r v19-devel portaudio
        cd portaudio
        ./configure --without-oss --libdir=$GNUSTEP_SYSTEM_ROOT/Libraries
         --includedir=$GNUSTEP_SYSTEM_ROOT/Local/Libraries/Headers
        sudo make install

    </div>

    On Windows XP do:

    <div class="informalexample">

        cvs -d:pserver:anonymous@www.portaudio.com:/home/cvs co -r v19-devel portaudio
        cd portaudio
        ./configure --libdir=$GNUSTEP_SYSTEM_ROOT/Libraries
         --includedir=$GNUSTEP_SYSTEM_ROOT/Local/Libraries/Headers
        --with-winapi=directx
        --with-dxdir=/c/DXSDK
        sudo make install

    </div>

[libmp3hip-HIPVERTUPLE.tar.gz](&hipdownload;/libmp3hip-&hipvertuple;.tar.gz). Status: optional - disables `SndMP3` if omitted.

:   The libmp3hip library of the [LAME](&libshoutweb;) project provides
    the MP3 decoding

    Install the library using:

    <div class="informalexample">

        tar xzvf libmp3hip-HIPVERTUPLE.tar.gz
        cd libmp3hip-HIPVERTUPLE
        sh ./configure
        make
        sudo make install

    </div>

Installing MusicKit Binaries {#binaries}
----------------------------

Binaries for the compiled frameworks for various operating systems
reside on sourceforge as `.dmg` (Apple), or `.rpm` (Linux) packages. The
files include the version number, choose the most recent release:

[MK-MKVERTUPLE.b.MOX.dmg](&mkdownload;/MK-&mkvertuple;.b.MOX.dmg)

:   The MacOS X frameworks (including the SndKit), applications, command
    line tools and documentation.

[ZilogSCCMIDI.b.tar.gz](&mkdownload;/ZilogSCCMIDI.b.tar.gz)

:   The MacOS X-Server V1.2 MIDI driver binary for SCC UARTs in
    8500/8600/9500/9600/G3/G4 PowerMacs.

    > **Note**
    >
    > This driver is not needed and will not work on MacOS X, only MacOS
    > X-Server V1.2.

### Installation Locations {#installation}

The Installer program will let you choose a directory in which to place
the binaries. If you are on a stand-alone machine, you should be logged
in (or running Installer) as root and choose LDQUO`/`RDQUO for the
installation directory (the default).

The frameworks and applications are installed into the appropriate
platform locations given in [table\_title](#installlocations).

  Platform                          Frameworks install location           Applications install location
  -------------------------- ----------------------------------------- -----------------------------------
  OpenStep 4.2 (m68k,ix86)          `/LocalLibrary/Frameworks`                    `/LocalApps`
  MacOS X-Server V1.0-1.2           `/Local/Library/Frameworks`                   `/Local/Apps`
  MacOS X                              `/Library/Frameworks`                     `/Applications`
  GNUStep (on Unixen)         `/usr/GNUstep/Local/Library/Frameworks`   `/usr/GNUstep/Local/Applications`
  GNUStep (on Windows)         `C:\GNUstep\Local\Library\Frameworks`     `C:\GNUstep\Local\Applications`

  : MusicKit Install locations

Command line tools and manual pages will install into the `/usr/local`
hierarchy on Unix type machines, specifically `/usr/local/bin`.
Locations for command line Windows tools have yet to be determined.

If you are the system administrator for a NFS shared network, you
probably want to choose a local directory which can be exported and
create symbolic links into that directory on the networked machines.
Alternatively, if you have a single server that exports `/Local*` and
`/usr/local`, simply install the package there and you're done.

Installing From The Source Tarball {#sources}
----------------------------------

The source distribution is located at:

[MK-MKVERTUPLE.s.tar.gz](&mkdownload;/MK-&mkvertuple;.s.tar.gz)

:   The source to `MusicKit`, `SndKit`, `MKDSP`, `MKPerformSndMIDI`,
    `MKUnitGenerators` and `MKSynthPatches` frameworks and all utilites,
    applications, documentation and example code.

    This is the most recent revision and patch. Some older revisions are
    located at the [sourceforge site](&mkdownload;) for
    regression testing.

[ZilogSCCMIDI.s.tar.gz](&mkdownload;/ZilogSCCMIDI.s.tar.gz)

:   The MacOS X-Server V1.0-1.2 MIDI driver source.

    > **Note**
    >
    > This is not needed for MacOS X.

[DriverKitHeadersForMOXS\_V1.2.tar.gz](&mkdownload;/DriverKitHeadersForMOXS_V1.2.tar.gz)

:   NeXTStep V3.3 headers required to compile the
    [driver](#ZilogDriverSource) on MacOS X-Server V1.2.

    > **Note**
    >
    > This is not needed for MacOS X.

Retrieving Sources From The Subversion Repository {#RetrieveSubversion}
-------------------------------------------------

The bleeding edge source is obtainable from the
[Subversion](http://subversion.tigris.org) repository on
[sourceforge](http://www.sourceforge.net) and is described in detail by
[this sourceforge page](&mksvnweb;).

Compiling The Sources {#compilation}
---------------------

The MusicKit installation process is now practically the same as most
[`autoconf`](http://www.gnu.org/software/autoconf/) configured software.
Trivially, the following commands will compile and install the MusicKit.

<div class="informalexample">

    ./configure
    make
    sudo make install

</div>

If you are installing dependent libraries into a non-standard place such
as `/sw` if using [fink](http://www.finkproject.org/) on MacOS X, you
can use the standard `configure` method to specify the compilation and
linking flags:

<div class="informalexample">

    ./configure CPPFLAGS=-I/sw/include LDFLAGS=-L/sw/lib
    make
    sudo make install

</div>

There are a couple of subtle variations to this, explained below.

### Building on GNUstep {#buildingongnustep}

On GNUstep systems, `make` is responsible for building the MusicKit
sources. From the top level of the source tree, executing `make` should
build `Frameworks`, `Examples` and `Applications`. Note that the
applications and tools built may differ from the MacOS X set due to
missing `GNUmakefile` definitions, but we aim to produce the same files
on all platforms.

At the time of writing, GNUstep isn't able to build frameworks which
depend on earlier built frameworks automatically. This requires
installing each MusicKit framework individually, in order, in a similar
fashion to the frameworks of GNUstep themselves. Also, the environment
variables required by GNUstep for building must be defined while having
root permissions in order to install. This is achieved with the
following commands:

<div class="informalexample">

    % ./configure
    % sudo sh
    # . /usr/GNUstep/System/Library/Makefiles/GNUstep.sh
    # cd Frameworks/PlatformDependent/MKPerformSndMIDI_portaudio
    # make install
    # cd ../../SndKit
    # make install
    # cd ../MKDSP_Native
    # make install
    # cd ../MusicKit
    # make install
    # cd ../..
    # make install

</div>

### Building on MacOS X {#buildingonmacosx}

On MacOS X, to benefit from the Xcode IDE (the IDE, plus zero-linking),
`make` will just run the `xcodebuild` command line tool which does the
actual building using the `MusicKit.xcodeproj` project. If `configure`
determined some libraries were unavailable, they will be omitted from
the CONFIGURED\_LIBS variable passed on the command line when
`xcodebuild` is run by `make`. Since `xcodebuild
install` builds and then installs, the `sudo make install` suffices,
typing a preceding `make` is not actually necessary.

The MusicKit project can also be built within the Xcode IDE GUI. However
`configure` must be run before building with Xcode, in order to
configure headers to selectively compile sources based on library
availability. In addition, the default configuration is to assume if the
Xcode GUI is being used, then the MusicKit is being developed, not just
installed and that all libraries have been installed. If all of the
libraries are not available, the build setting CONFIGURED\_LIBS must be
changed for the SndKit to remove those libraries which are not
installed. In practice, the user must manually modify CONFIGURED\_LIBS
build setting in the SndKit target to match the setting in `Makefile`.

To build on MacOS 10.6, currently the MusicKit and SndKit frameworks
must be built for the i386 32 bit architecture. This requires the
supporting libraries to also be built as i386 binaries. Assuming the
support libraries are built with an i386 architecture binary,
`configure` needs to be instructed to test the library linking with the
i386 architecture, using the -arch flag:

<div class="informalexample">

    ./configure CFLAGS="-arch i386"
    make

</div>

> **Note**
>
> The `MKUnitGenerators` and `MKSynthPatches` frameworks won't compile
> on platforms other than OpenStep or NeXTStep because the Motorola
> `asm56000` and `lnk56000` tools are missing.

### Installing a MIDI driver {#mididriver}

If necessary, compile and install an appropriate MIDI driver.

To compile the MacOS X-Server V1.2 Zilog SCC MIDI driver, some header
files are missing. You can get them from the Darwin distribution of the
SoundKit, copy them from a NeXTStep 3.3/OpenStep 4.2 system, or as a
convience, they are made available for [download](#DriverKitHeaders).

MacOS X Developer release includes source for a generic USB MIDI driver
at `/Developer/Examples/CoreAudio/MIDI/SampleUSBDriver`. There is also a
driver binary for the MIDIMan MIDISPORT USB interfaces for MacOS X
available for download from [MIDIMan's web page](http://www.midiman.com)
and other vendors may well have drivers available for their hardware.

Building the Documentation {#buildingdoco}
--------------------------

The documentation for the MusicKit and SndKit are now authored in
[DocBook](http://www.docbook.org) XML format. This is then rendered to
HTML, PDF, Apple HelpViewer and potentially other formats. In order to
convert the documentation to these usual output formats, tools such as
[openjade](http://openjade.sourceforge.net), [TeX](http://www.tug.org/),
[doxygen](http://doxygen.sourceforge.net) need to be installed in
addition to DocBook itself. The `configure` command will check for these
tools. The `make` command will attempt to build and install as much of
the documentation as possible based on which tools have been installed.
This is invoked by:

<div class="informalexample">

    make documentation
    sudo make installdocs

</div>

Included Applications and Example Code {#appsandexs}
======================================

Applications in the distribution {#applications}
--------------------------------

-   ScorePlayer (David Jaffe)

-   WaveEdit (David Jaffe)

    WaveEdit is an application that makes it possible to display, edit
    and listen to wave tables.

-   Ensemble (Michael McNabb)

    Ensemble combines elements of a sequencer, a voicing application and
    an algorithmic composition application.

-   EnvelopeEd (Fernando Lopez Lezcano)

-   PianoRoll (Jonathan Knudsen)

-   HosePlayer (Perry Cook)

-   SlideFlute (Perry Cook)

-   edsnd (Lee Boynton)

-   Reich-o-Matic (Brad Garton)

-   Looching (Brad Garton)

-   ResoLab (Perry Cook)

-   ClariNot (Perry Cook)

-   ResonSound (David Jaffe)

    Real time processing of sound from the DSP serial port.

-   PatchCord (Leigh Smith)

    A system exclusive librarian and patch editor.

Example code in the distribution {#examples}
--------------------------------

There are two kinds of programming examples. Programs with names
entirely in lowercase, such as `playscorefile`, are command-line
programs. Programs with names beginning with an uppercase letter, such
as PlayNote, are applications (i.e. graphic-interface programs).

The complete set of programs is listed below. For further information on
a given programming example, see the README file in its directory.

`playpart`

:   Create notes algorithmically and play them.

`playscorefile`

:   Read a scorefile into a `MKScore` and play it on the DSP.

`playscorefile2`

:   Read a scorefile and play it on the DSP as it is read.

`playscorefilemidi`

:   Play scorefile through MIDI out.

`mixscorefiles`

:   Mix any number of scorefiles and write the result out.

`process_soundfiles_dsp`

:   Process a sound file through the DSP (non-real-time). Includes
    `MKSynthPatch`es for resonating and enveloping sounds.

`mixsounds`

:   Soundfile mixer that shows how to make your own
    `MKInstrument` (non-real-time).

`exampleSynthPatch`

:   Demonstrates how to build a `MKSynthPatch` and play it.

`exampleUnitGenerator`

:   Demonstrates how to build a `MKUnitGenerator`.

`example1`

:   Simple `MKNote` and `MKScore` generation.

`example2`

:   Demonstration of playing `MKNote`s.

`example3`

:   Simple algorithmic melody generation.

`example4`

:   Simple algorithmic melody generation using `MKPart`.

`example5`

:   Demonstration of `MKUnitGenerator`s.

<!-- -->

Metronome

:   Simple note playing.

MidiFilePlayback

:   Play MIDI files with samples using `MKSamplePlayerInstrument`.

MidiEcho

:   Take MIDI in, generate echoes, and send to MIDI output.

MidiLoop

:   Take MIDI input and send it right out MIDI again.

MidiPlay

:   Take MIDI input and play the DSP.

MidiRecord

:   Read MIDI input into a `MKScore` obj, write a scorefile.

PerformerExample

:   Adjust algorithmically-generated music playing on DSP.

PlayNote

:   Click a button to play and adjust notes on the DSP.

QuintProcessor

:   Interactive application for the Ariel QuintProcessor.

SineGen

:   Interactively adjust the frequency of a sine wave.

What works? {#works}
===========

The frameworks (SndKit, MusicKit) have been exercised fairly extensively
and are quite stable.

MIDI recording and playback of scores and computed parts works on all
supported platforms. The application ScorePlayer, the examples
MidiFilePlayback and `playscorefilemidi`, and the utility `playscore`
demonstrate these capabilities.

Sound recording and playback is also stable. The applications Spectro
and TwoWaves, and the commands `playsnd`, `recsnd` demonstrate Sound
recording/performance.

What doesn't work? / What needs doing? {#notworking}
======================================

-   The current tasks to be done (tickets) are listed on the sourceforge
    MusicKit [Trac
    Manager](http://www.sourceforge.net/apps/trac/musickit).

-   DSP on non-56K DSP systems. Stephen mentioned he got sound out
    under OS4.2. However none of the DSP drivers have been ported from
    NeXTStep V3.3 (as they are all ISA bus cards and I don't know of a
    PCI 56K card with published interface specs).

    A more fruitful avenue seems to be to convert the unit generators to
    the MPEG Layer 4 structured audio language
    [SAOL](http://www.saol.net) ScheirerVercoe99 and modify the MKDSP
    framework to download to a supporting card or do the emulation using
    the native processor. If emulating with the native processor, it
    would then be possible to use Apples AltiVec vector libraries for
    increased performance.

-   For this current revision the `.nib`s have been upgraded to work
    with MacOS X and MacOS X-Server and will not load with OpenStep 4.2.
    The `.nib`s which are compatible with OpenStep 4.2 are now named
    `nibname-openstep.nib`. At the moment you will need to manually
    symbolically link these to compile for OpenStep 4.2. Eventually
    Apple's InterfaceBuilder will produce XML based nibs which should
    reduce the compatibility issue.

API Changes in MusicKit V5.X frameworks {#mkV5changes}
=======================================

The changes from Version 4 to Version 5 of the MusicKit mostly consists
of conversion to the OpenStep specification from the older NeXTStep API.

Frameworks replace libraries
----------------------------

Libraries have now been replaced as the following frameworks:

-   MusicKit.framework

-   MKDSP.framework

-   MKPerformSndMIDI.framework

-   MKSynthPatches.framework

-   MKUnitGenerators.framework

Include Files
-------------

The root hierarchical include file is now `#import`ed as
`<MusicKit/MusicKit.h>` replacing `<musickit/musickit.h>`.

Unit generator headers are included from `MKUnitGenerators.framework`,
not `musickit/unitgenerators`.

Class naming conventions
------------------------

All the public MusicKit classes are now prefixed with `MK` to match the
Foundation/AppKit model, ie `MKNote`, `MKOrchestra` replaces `Note` and
`Orchestra`. In a similar manner to the changes in other frameworks when
OpenStep-ified, as well as method name changes, there are object
allocation changes, generally +new is now an appropriate name returning
an autoreleased instance, i.e +score for `MKScore`, +note for `MKNote`
etc. `NSString`s replace `char *` where ever possible.

Class Specific Changes
----------------------

### `MKMidi`

-   +new has been renamed +midi in keeping with OpenStep conventions.

-   allocFromZone:onDevice: and allocFromZone:onDevice:hostName have
    been replaced with corresponding -initOnDevice: and
    -initOnDevice:hostName: instance methods and +midiOnDevice:,
    +midiOnDevice:hostName: class methods to support OpenStep
    allocation conventions.

-   The methods -noteSenders and -noteReceivers don't return a copy of
    the array. The parent object is expected to copy it.

Contributing Fixes {#fixes}
==================

Please! Changes are maintained via an [open Subversion
system](&mksvnweb;). If you send me <> changes I will incorporate them
and check them in. If you are planning to do major work, I can register
you as a developer to provide write access to the Subversion server.

If you make a MusicKit program that you'd like us to consider for
distribution as part of the MusicKit, DSP and SndKit Distribution,
please send it to the following address: <>. We are interested in
applications, unit generators, synth patches, etc. If you do not have
e-mail access, you can send media to the address of the author at the
start of this document.

If you have discovered a bug, please report it via the sourceforge bug
tracker.

Supporting The MusicKit Project by Donations {#Donations}
============================================

The MusicKit project is run by volunteers who donate their development
time, equipment and personal money instead of working on paying jobs.
While we prefer contributions of development time and of code, monetary
donations allow us in a very real sense to continue to develop the
MusicKit for the benefit of all your projects, including commercial
projects.

Please consider donating to the MusicKit project to keep releases and
bug fixes regularly delivered. You can make online donations via [the
sourceforge donations
system](http://sourceforge.net/project/project_donations.php?group_id=9881).

The MusicKit Project developers are also available for contracting work
to add substantial features to the MusicKit, to consult on integration
of MusicKit technologies into other projects and to work on other
complimentary projects. Please direct questions to the project
administrator <>.

BIBLIOGRAPHY READINGLIST
[![ SourceForge Logo ](Images/sourceforge.eps){width="50" height="30"}
SourceForge kindly hosts the MusicKit.](http://sourceforge.net)
