// Holds all characteristics of a String, Tuning, dimensions, arrangement etc.
@interface GuitarString: NSObject
{
   float openTuning; // of each string (note and cents), or in Hz
   float positionToFretboardEdge;  // allow for doubled or tripled courses and uneven versions of each
   float gauge; // thickness of each string (Normalised value)
}

@end