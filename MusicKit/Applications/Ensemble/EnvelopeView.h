#ifndef __MK_EnvelopeView_H___
#define __MK_EnvelopeView_H___
#import <appkit/appkit.h>

@interface EnvelopeView:View
{
	id envelope;
    id delegate;
	double *x;
	double *y;
	double minY, maxY;
	int arraySize;
	int nPoints;
	id inRangeFields;
	id outRangeFields;
	id xAxisView;
	id yAxisView;
	float *points;
	unsigned char *ops;
	float *gridPoints;
	unsigned char *gridOps;
	int nGridPoints;
	int gridArraySize;
	float bbox[4];
	int stickPoint;
	int selectedPoint;
	BOOL stickPointSelected;
	BOOL userPathInvalid;
	BOOL gridPathInvalid;
	BOOL stickPointEnabled;
}

- setDelegate:anObject;
- setEnvelope:anEnvelope;
- takeInputRangeFrom:sender;
- takeOutputRangeFrom:sender;
- setStickPointEnabled:(BOOL)flag;

@end

@interface EnvelopeViewDelgate:Object
- envelopeModified:sender;
@end

#endif
