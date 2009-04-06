// Reverb model implementation
//
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#include "revmodel.h"
#include "stdio.h"
#include "string.h"

sndreverb_revmodel::sndreverb_revmodel()
{
}


void sndreverb_revmodel::processreplace(float *inputL, float *inputR, float *outputL, float *outputR, long numsamples, int skip)
{
	float outL,outR,input;

	while(numsamples-- > 0)
	{
		outL = outR = 0;
		input = (*inputL + *inputR) * gain;

		// Accumulate comb filters in parallel
		for(int i=0; i<numcombs; i++)
		{
			outL += combL[i].process(input);
			outR += combR[i].process(input);
		}

		// Feed through allpasses in series
		for(int i=0; i<numallpasses; i++)
		{
			outL = allpassL[i].process(outL);
			outR = allpassR[i].process(outR);
		}

		// Calculate output REPLACING with anything already there
		*outputL = outL*wet1 + outR*wet2 + *inputL*dry;
		*outputR = outR*wet1 + outL*wet2 + *inputR*dry;

		// Increment sample pointers, allowing for interleave (if any)
    outputL += skip;
    outputR += skip;
    inputL  += skip;
    inputR  += skip;
	}
/*
  int i,j;
	float outL,outR,input;
  
//  memset(outputL, 0, sizeof(float) * numsamples * 2); 
//  processmix(inputL, inputR, outputL, outputR, numsamples, skip);
//  return;

  if (bufferLength != numsamples) {
    bufferLength = numsamples;
    if (outputAccumL) delete outputAccumL;
    if (outputAccumR) delete outputAccumR;  
    if (inputMix)     delete inputMix;
    outputAccumL = new float[bufferLength];
    outputAccumR = new float[bufferLength];
    inputMix     = new float[bufferLength];
  }
  memset(outputAccumL, 0, sizeof(float) * bufferLength); 
  memset(outputAccumR, 0, sizeof(float) * bufferLength); 

	for (i = 0, j = 0; i < numsamples; i++, j+=skip)
	{
		inputMix[i] = (inputL[j] + inputR[j]) * gain;
  }
	// Accumulate comb filters in parallel
  
	for(int i=0; i<numcombs; i++)
	{
		combL[i].processBuffer(inputMix, outputAccumL, numsamples, 1);
		combR[i].processBuffer(inputMix, outputAccumR, numsamples, 1);
    
//		outL += combL[i].process(input, out);
//		outR += combR[i].process(input);
	}

		// Feed through allpasses in series
    
  for(int i = 0; i < numallpasses; i ++)
	{
    allpassL[i].processBufferReplacing(outputAccumL, outputAccumL, numsamples, 1);
    allpassR[i].processBufferReplacing(outputAccumR, outputAccumR, numsamples, 1);
//			outL = allpassL[i].process(outL);
//			outR = allpassR[i].process(outR);
	}

	for (i = 0, j = 0; i < numsamples; i++, j += skip)
	{
		// Calculate output REPLACING anything already there
		outputL[j] = outputAccumL[i] * wet1 + outputAccumR[i] * wet2 + inputL[j] * dry;
		outputR[j] = outputAccumR[i] * wet1 + outputAccumL[i] * wet2 + inputR[j] * dry;
	}

*/
}

void sndreverb_revmodel::processmix(float *inputL, float *inputR, float *outputL, float *outputR, long numsamples, int skip)
{
	float outL,outR,input;

	while(numsamples-- > 0)
	{
		outL = outR = 0;
		input = (*inputL + *inputR) * gain;

		// Accumulate comb filters in parallel
		for(int i=0; i<numcombs; i++)
		{
			outL += combL[i].process(input);
			outR += combR[i].process(input);
		}

		// Feed through allpasses in series
		for(int i=0; i<numallpasses; i++)
		{
			outL = allpassL[i].process(outL);
			outR = allpassR[i].process(outR);
		}

		// Calculate output MIXING with anything already there
		*outputL += outL*wet1 + outR*wet2 + *inputL*dry;
		*outputR += outR*wet1 + outL*wet2 + *inputR*dry;

		// Increment sample pointers, allowing for interleave (if any)
    outputL += skip;
    outputR += skip;
    inputL  += skip;
    inputR  += skip;
	}
}

//ends
