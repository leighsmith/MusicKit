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
  return (void*) (new revmodel);
}
void reverbDestroy(void* reverbobj)
{
  delete ((revmodel*)reverbobj);
}

void  reverbProcessReplacing(void *r, float* inL, float* inR, float* outL, float *outR, int length, int skip)
{
  ((revmodel*) r)->processreplace(inL, inR, outL, outR, length, skip);
}

void setRoomSize(void *r, float value) 
{
  ((revmodel*) r)->setroomsize(value);
}

float	getRoomSize(void *r) 
{
  return ((revmodel*) r)->getroomsize();
}

void	setDamp(void *r,float value)
{
  ((revmodel*) r)->setdamp(value);
}

float	getDamp(void *r)
{
  return ((revmodel*) r)->getdamp();
}

void	setWet(void *r,float value)
{
  return ((revmodel*) r)->setwet(value);
}

float	getWet(void *r)
{
  return ((revmodel*) r)->getwet();
}

void setDry(void *r,float value)
{
  ((revmodel*) r)->setdry(value);
}

float	getDry(void *r)
{
  return ((revmodel*) r)->getdry();
}

void setWidth(void *r,float value)
{
  ((revmodel*) r)->setwidth(value);
}

float	getWidth(void *r)
{
  return ((revmodel*) r)->getwidth();
}

void setMode(void *r,float value)
{
  ((revmodel*) r)->setmode(value);
}

float	getMode(void *r)
{
  return ((revmodel*) r)->getmode();
}
