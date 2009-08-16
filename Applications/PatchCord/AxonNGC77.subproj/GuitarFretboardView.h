// A visual mimic object
// Should create a palette entry when I'm done.
// Ideally should take parameters in real-world coords and convert as needed.
// These are more general than the NGC so should eventually be in another directory.
// Guitar body display is done by another object

@interface GuitarFretboardView: NSView
{
    NSArray Strings;                  //  holds attributes of each  GuitarString instance
    (BOOL) displayHighestStringUp;    // orientation of the fretboard.
    (BOOL) displayHighestFretIsLeft;  // orientation of the fretboard.

// What about rational (fretlet) arrangements?
// Number of frets
// tuning of each fret (note and cents)

    NSImage fretboardPattern;         // repeated and patterned as need be (EPS file)
    float scaleLength;
    float widthAtNut;
    float widthAtSoundHole;           // Allows a fanned neck like an Oud.
    id delegate;                      // (notification) when user selected a note on a string using mouse

}

- showNote: (pitch which includes optional microtonality) onString: 1-Number of strings
- showHeadstock: (BOOL);
- setWidthAtNut: (float) width;
- setWidthAtSoundHole: (float) width;
- setScaleLength: (float) length;

@end
