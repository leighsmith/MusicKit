#ifndef __MK_Shapev_H___
#define __MK_Shapev_H___
/* Shapev.
 *
 * Eric J. Graves and David A. Jaffe
 * (c) 1992 Eric J. Graves & Stanford University
 *
 */

#import "Shape.h"
#import <MusicKit/MKWaveTable.h>

@interface Shapev:Shape
{
    MKWaveTable *vibWaveform; /* Waveform used for vibrato. */
    double svibAmp0;  /* Vibrato, on a scale of 0 to 1, when modWheel is 0. */
    double svibAmp1;  /* Vibrato, on a scale of 0 to 1, when modWheel is 127.*/
    double svibFreq0; /* Vibrato freq in Hz. when modWheel is 0. */
    double svibFreq1; /* Vibrato freq in Hz. when modWheel is 1. */
    double rvibAmp;   /* Random vibrato. On a scale of 0 to 1. */
    int modWheel;     /* MIDI modWheel. Controls vibrato frequency and amp */
    id svib,nvib,onep,add;
}

+ patchTemplateFor:aNote;

@end

#endif
