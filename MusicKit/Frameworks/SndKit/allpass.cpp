// Allpass filter implementation
//
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#include "allpass.h"

sndreverb_allpass::sndreverb_allpass()
{
	bufidx = 0;
}

void sndreverb_allpass::setbuffer(float *buf, int size) 
{
	buffer = buf; 
	bufsize = size;
}

void sndreverb_allpass::mute()
{
	for (int i=0; i<bufsize; i++)
		buffer[i]=0;
}

void sndreverb_allpass::setfeedback(float val) 
{
	feedback = val;
}

float sndreverb_allpass::getfeedback() 
{
	return feedback;
}

//ends