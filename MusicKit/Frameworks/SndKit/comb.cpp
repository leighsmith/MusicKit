// Comb filter implementation
//
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#include "comb.h"

sndreverb_comb::sndreverb_comb()
{
	filterstore = 0;
	bufidx = 0;
}

void sndreverb_comb::setbuffer(float *buf, int size) 
{
	buffer = buf; 
	bufsize = size;
}

void sndreverb_comb::mute()
{
	for (int i=0; i<bufsize; i++)
		buffer[i]=0;
}

void sndreverb_comb::setdamp(float val) 
{
	damp1 = val; 
	damp2 = 1-val;
}

float sndreverb_comb::getdamp() 
{
	return damp1;
}

void sndreverb_comb::setfeedback(float val) 
{
	feedback = val;
}

float sndreverb_comb::getfeedback() 
{
	return feedback;
}

void sndreverb_comb::processBuffer(float *input, float *output, long bufferlength, int skip)
{
  int i;
  
  for (i = 0; i < bufsize; i += skip)
    output[i] += process(input[i]);
}


// ends
