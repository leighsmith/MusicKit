/*
 *  reverbBridge.h
 *  SndKit
 *
 *  Created by skot on Wed Mar 28 2001.
 *  Copyright (c) 2001 __CompanyName__. All rights reserved.
 *
 */
#ifdef __cplusplus
extern "C" {
#endif 

void* reverbCreate(void);
void reverbDestroy(void* reverbobj);
void  reverbProcessReplacing(void* r, float* inL, float* inR, float* outL, float *outR, int length, int skip);

void  setRoomSize(void *r, float value); 
float	getRoomSize(void *r);
void	setDamp(void *r,float value);
float	getDamp(void *r);
void	setWet(void *r,float value);
float	getWet(void *r);
void	setDry(void *r,float value);
float	getDry(void *r);
void	setWidth(void *r,float value);
float	getWidth(void *r);
void	setMode(void *r,float value);
float	getMode(void *r);

#ifdef __cplusplus
}
#endif
