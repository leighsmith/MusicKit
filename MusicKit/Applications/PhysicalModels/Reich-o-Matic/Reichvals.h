#define MINLENGTH 30
#define MAXLENGTH 71
#define MAXD2LENGTH 38


#define LBREATH		49
#define SBREATH		35

#define SIXTEENTH	0.1
#define EIGHTH		2*SIXTEENTH
#define QUARTER		2*EIGHTH
#define CYCMEASURE	3*QUARTER

float Beats[4] = { SIXTEENTH, EIGHTH, EIGHTH, QUARTER };

#define CYCARRNOTES	4
#define	NCYCS		9
#define ARRNOTES	8
#define NUMFLUTES	3
#define CANONPT		4*QUARTER
#define RUNNOTES	4
#define UP			0
#define DOWN		1
#define NORUN		-1

#define LONGSECTDUR 5
#define LONGSTART	21
#define REGSECTDUR	9
#define REGSTART	34
#define RUNPROBINCR	0.035
#define RESTPROBINCR	0.02
#define AMPHIINCR	0.005
#define AMPLOINCR	0.015
#define PHASEINCR	0.01
#define SLURPROB	0.2


float Reichnotes[17][2] = {{1.000000,	0.810000}, //   Lowest C
    			{0.795000,	0.620000},
    			{0.600000,	0.500000},
    			{0.486000,	0.510000}, //  Lowest F
    			{0.310000,	0.350000}, 
    			{0.090909,	0.250000}, 
    			{1.000000,	0.180000}, //   C
     			{0.795000,	0.100000},
    			{0.600000,	0.000000},
    			{0.486000,	0.070000}, //   F
    			{0.300000,	0.000000}, 
    			{0.085000,	0.550000}, 
    			{0.470000,	1.000000}, //   C
    			{0.312000,	0.910000},
    			{0.170000,	0.750000},
    			{0.052009,	0.670000}, //  F
    			{0.340909,	0.952000}};
				      				      				     
#define NUMNOTES	17 	// from above array
