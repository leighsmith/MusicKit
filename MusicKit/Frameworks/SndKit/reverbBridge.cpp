/*
 *  reverbBridge.cpp
 *  SndKit
 *
 *  Created by skot on Wed Mar 28 2001.
 *  Copyright (c) 2001 __CompanyName__. All rights reserved.
 *
 *
 *  language bridge for now to Freeverb.
 */

#include "revmodel.h"
#include "reverbBridge.h"

void* reverbCreate(void)
{
  return (void*) (new sndreverb_revmodel);
}
void reverbDestroy(void* reverbobj)
{
  delete ((sndreverb_revmodel*)reverbobj);
}

void  reverbProcessReplacing(void *r, float* inL, float* inR, float* outL, float *outR, int length, int skip)
{
  ((sndreverb_revmodel*) r)->processreplace(inL, inR, outL, outR, length, skip);
}

void setRoomSize(void *r, float value) 
{
  ((sndreverb_revmodel*) r)->setroomsize(value);
}

float	getRoomSize(void *r) 
{
  return ((sndreverb_revmodel*) r)->getroomsize();
}

void	setDamp(void *r,float value)
{
  ((sndreverb_revmodel*) r)->setdamp(value);
}

float	getDamp(void *r)
{
  return ((sndreverb_revmodel*) r)->getdamp();
}

void	setWet(void *r,float value)
{
  return ((sndreverb_revmodel*) r)->setwet(value);
}

float	getWet(void *r)
{
  return ((sndreverb_revmodel*) r)->getwet();
}

void setDry(void *r,float value)
{
  ((sndreverb_revmodel*) r)->setdry(value);
}

float	getDry(void *r)
{
  return ((sndreverb_revmodel*) r)->getdry();
}

void setWidth(void *r,float value)
{
  ((sndreverb_revmodel*) r)->setwidth(value);
}

float	getWidth(void *r)
{
  return ((sndreverb_revmodel*) r)->getwidth();
}

void setMode(void *r,float value)
{
  ((sndreverb_revmodel*) r)->setmode(value);
}

float	getMode(void *r)
{
  return ((sndreverb_revmodel*) r)->getmode();
}
