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
  bufferLength = 0;
  inputMix     = NULL;
  outputAccumL = NULL;
  outputAccumR = NULL;

	// Tie the components to their buffers
	combL[0].setbuffer(bufcombL1,combtuningL1);
	combR[0].setbuffer(bufcombR1,combtuningR1);
	combL[1].setbuffer(bufcombL2,combtuningL2);
	combR[1].setbuffer(bufcombR2,combtuningR2);
	combL[2].setbuffer(bufcombL3,combtuningL3);
	combR[2].setbuffer(bufcombR3,combtuningR3);
	combL[3].setbuffer(bufcombL4,combtuningL4);
	combR[3].setbuffer(bufcombR4,combtuningR4);
	combL[4].setbuffer(bufcombL5,combtuningL5);
	combR[4].setbuffer(bufcombR5,combtuningR5);
	combL[5].setbuffer(bufcombL6,combtuningL6);
	combR[5].setbuffer(bufcombR6,combtuningR6);
	combL[6].setbuffer(bufcombL7,combtuningL7);
	combR[6].setbuffer(bufcombR7,combtuningR7);
	combL[7].setbuffer(bufcombL8,combtuningL8);
	combR[7].setbuffer(bufcombR8,combtuningR8);
	allpassL[0].setbuffer(bufallpassL1,allpasstuningL1);
	allpassR[0].setbuffer(bufallpassR1,allpasstuningR1);
	allpassL[1].setbuffer(bufallpassL2,allpasstuningL2);
	allpassR[1].setbuffer(bufallpassR2,allpasstuningR2);
	allpassL[2].setbuffer(bufallpassL3,allpasstuningL3);
	allpassR[2].setbuffer(bufallpassR3,allpasstuningR3);
	allpassL[3].setbuffer(bufallpassL4,allpasstuningL4);
	allpassR[3].setbuffer(bufallpassR4,allpasstuningR4);

	// Set default values
	allpassL[0].setfeedback(0.5f);
	allpassR[0].setfeedback(0.5f);
	allpassL[1].setfeedback(0.5f);
	allpassR[1].setfeedback(0.5f);
	allpassL[2].setfeedback(0.5f);
	allpassR[2].setfeedback(0.5f);
	allpassL[3].setfeedback(0.5f);
	allpassR[3].setfeedback(0.5f);
	setwet(initialwet);
	setroomsize(initialroom);
	setdry(initialdry);
	setdamp(initialdamp);
	setwidth(initialwidth);
	setmode(initialmode);

	// Buffer will be full of rubbish - so we MUST mute them
	mute();
}

void sndreverb_revmodel::mute()
{
	if (getmode() >= freezemode)
		return;

	for (int i=0;i<numcombs;i++)
	{
		combL[i].mute();
		combR[i].mute();
	}
	for (int i=0;i<numallpasses;i++)
	{
		allpassL[i].mute();
		allpassR[i].mute();
	}
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

void sndreverb_revmodel::update()
{
// Recalculate internal values after parameter change

	int i;

	wet1 = wet*(width/2 + 0.5f);
	wet2 = wet*((1-width)/2);

	if (mode >= freezemode)
	{
		roomsize1 = 1;
		damp1 = 0;
		gain = muted;
	}
	else
	{
		roomsize1 = roomsize;
		damp1 = damp;
		gain = fixedgain;
	}

	for(i=0; i<numcombs; i++)
	{
		combL[i].setfeedback(roomsize1);
		combR[i].setfeedback(roomsize1);
	}

	for(i=0; i<numcombs; i++)
	{
		combL[i].setdamp(damp1);
		combR[i].setdamp(damp1);
	}
}

// The following get/set functions are not inlined, because
// speed is never an issue when calling them, and also
// because as you develop the reverb model, you may
// wish to take dynamic action when they are called.

void sndreverb_revmodel::setroomsize(float value)
{
	roomsize = (value*scaleroom) + offsetroom;
	update();
}

float sndreverb_revmodel::getroomsize()
{
	return (roomsize-offsetroom)/scaleroom;
}

void sndreverb_revmodel::setdamp(float value)
{
	damp = value*scaledamp;
	update();
}

float sndreverb_revmodel::getdamp()
{
	return damp/scaledamp;
}

void sndreverb_revmodel::setwet(float value)
{
	wet = value*scalewet;
	update();
}

float sndreverb_revmodel::getwet()
{
	return wet/scalewet;
}

void sndreverb_revmodel::setdry(float value)
{
	dry = value*scaledry;
}

float sndreverb_revmodel::getdry()
{
	return dry/scaledry;
}

void sndreverb_revmodel::setwidth(float value)
{
	width = value;
	update();
}

float sndreverb_revmodel::getwidth()
{
	return width;
}

void sndreverb_revmodel::setmode(float value)
{
	mode = value;
	update();
}

float sndreverb_revmodel::getmode()
{
	if (mode >= freezemode)
		return 1;
	else
		return 0;
}

//ends
