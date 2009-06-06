/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

enum allpassFilterStructure {direct_form_1, direct_form_2};

typedef struct _allpass1Vars {
    pp input;
    pp output;
    word b0;
    word s;
    unsigned int filterStructure;
} allpass1Vars;

extern void allpass1(allpass1Vars *a);




