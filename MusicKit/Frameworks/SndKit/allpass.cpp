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

/*
inline float sndreverb_allpass::process(float input)
{
	float output;
	float bufout;
	
	bufout = buffer[bufidx];
	undenormalise(bufout);
	
	output = -input + bufout;
	buffer[bufidx] = input + (bufout*feedback);

	if(++bufidx>=bufsize) bufidx = 0;

	return output;
}
*/

void	sndreverb_allpass::processBufferReplacing(float *input, float *output, long bufferLength, int skip)
{
  long i;
//  float bufout;
  
  for (i = 0; i < bufferLength; i += skip) 
    output[i] = process(input[i]);
}

//ends
