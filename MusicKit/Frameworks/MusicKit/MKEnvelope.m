/*
  $Id$  
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    Julius sez:

    Tau has a precise meaning.  It is the "time constant".  During tau seconds
    you get 1/e of the way to where you're going, or about .37th of the way.
    Setting it to 0.2 means you are going 5 time constants in 1 second.  You
    determined empirically that 5 or 6 time constants "really gets there".
    Still, it is an exponential approach that never quite reaches its target.
    The formula

         exp(-t/tau) = epsilon

    Can be solved for t to find out how many time constants will get you
    to within epsilon times the inital distance.  For example, epsilon = 0.001
    gives t around 7.  This means it takes 7 time constants to traverse 99.999%
    of the distance.

    If we redefine the meaning of tau, we have to give it another name, such
    as "relaxation time".  We can never call it the time constant.

    That's why we call it "smoothing".

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.3  2000/04/02 16:50:32  leigh
  Cleaned up doco

  Revision 1.2  1999/07/29 01:16:36  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  01/07/90/daj - Changed comments and flushed false conditional comp.
  01/09/90/daj - Fixed minor bug in setStickPoint: -- error checking wasn't
		 correct.
  03/19/90/daj - Added MKSetEnvelopeClass() and MKGetEnvelopeClass().
  03/21/90/daj - Added archiving.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/27/90/daj - Changed to zone API.
  09/02/90/daj - Changed MAXDOUBLE references to noDVal.h way of doing things
  02/18/91/daj - Added error checking to _MKGetEnvelopeNth().
  08/28/91/daj - Added lookupYForXAsymptotic:
*/
#define MK_INLINE 1
#import "_musickit.h"
#import "_scorefile.h"

#import "EnvelopePrivate.h"
@implementation  MKEnvelope

+  new
  /* This is how you make up an empty seg envelope */
{
    self = [super allocWithZone:NSDefaultMallocZone()];
    [self init];
    return self;
}

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKEnvelope class])
      return;
    [MKEnvelope setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}


-init
{
    stickPoint = MAXINT;
    samplingPeriod = 1.0;
    defaultSmoothing = MK_DEFAULTSMOOTHING;
    return self;
}

static void putArray(int pointCount,NSCoder *aTypedStream,double *arr) /*sb: originally converted as NSArchiver, not NSCoder */
{
    BOOL aBool;
    if (arr) {
	aBool = YES;
	[aTypedStream encodeValueOfObjCType:"c" at:&aBool];
	[aTypedStream encodeArrayOfObjCType:"d" count:pointCount at:arr];
    } else {
	aBool = NO;
	[aTypedStream encodeValueOfObjCType:"c" at:&aBool];
    }
}

static void getArray(int pointCount,NSCoder *aTypedStream, /*sb: originally converted as NSArchiver, not NSCoder */
		     double **arrPtr)
{
    BOOL aBool;
    [aTypedStream decodeValueOfObjCType:"c" at:&aBool];
    if (aBool) {
	double *arr; /* We do it like this because read: can be called 
			  multiple times. */
	_MK_MALLOC(arr,double,pointCount);
	[aTypedStream decodeArrayOfObjCType:"d" count:pointCount at:arr];
	if (!*arrPtr)
	  *arrPtr = arr;
	else free(arr);
    } 
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSString *str;
    /*[super encodeWithCoder:aCoder];*/ /*sb: unnec */
    str = MKGetObjectName(self);
    [aCoder encodeValuesOfObjCTypes:"ddii@",&defaultSmoothing,&samplingPeriod,
		 &stickPoint,&pointCount,&str];
    putArray(pointCount,aCoder,xArray);
    putArray(pointCount,aCoder,yArray);
    putArray(pointCount,aCoder,smoothingArray);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    /*[super initWithCoder:aDecoder];*/ /*sb: unnec */
    if ([aDecoder versionForClassName:@"Envelope"] == VERSION2) {
	NSString *str;
	[aDecoder decodeValuesOfObjCTypes:"ddii@",&defaultSmoothing,&samplingPeriod,
		    &stickPoint,&pointCount,&str];
	if (str) {
	    MKNameObject(str,self);
	}
	getArray(pointCount,aDecoder,&xArray);
	getArray(pointCount,aDecoder,&yArray);
	getArray(pointCount,aDecoder,&smoothingArray);
    }
    return self;
}

static id theSubclass = nil;

BOOL MKSetEnvelopeClass(id aClass)
{
    if (!_MKInheritsFrom(aClass,[MKEnvelope class]))
      return NO;
    theSubclass = aClass;
    return YES;
}

id MKGetEnvelopeClass(void)
{
    if (!theSubclass)
      theSubclass = [MKEnvelope class];
    return theSubclass;
}

- copyWithZone:(NSZone *)zone
  /* Returns a copy of the receiver with its own copy of arrays. */
{
    MKEnvelope *newObj = NSCopyObject(self, 0, zone);
    newObj->xArray = NULL;
    newObj->yArray = NULL;
    newObj->smoothingArray = NULL;
    [newObj setPointCount:pointCount xArray:xArray orSamplingPeriod:
     samplingPeriod  yArray:yArray smoothingArray:smoothingArray orDefaultSmoothing:defaultSmoothing];
    [newObj setStickPoint:stickPoint];
    return newObj;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

- (int)	pointCount
  /* Returns the number of points in the Envelope. */
{
    return pointCount;
}

- (void)dealloc
    /* Frees self. Removes the name, if any, from the name table. */
{
    if (xArray != NULL)
	free(xArray);
    if (yArray != NULL)
	free(yArray);
    if (smoothingArray != NULL)
	free(smoothingArray);
    MKRemoveObjectName(self);
    [super dealloc];
}

-(double)defaultSmoothing
  /* If the defaultSmoothing is used (no smoothing points) returns the time constant,
     else MK_NODVAL */
{
    if (smoothingArray) 
      return MK_NODVAL;
    return defaultSmoothing;
}

- (int)	stickPoint
  /* Returns stickPoint or MAXINT if none */
{
    return stickPoint;
}

- setStickPoint:(int) sp
  /* Sets stick point. A stick point of MAXINT means no stick point. 
     Returns nil if sp is out of bounds, else self. Stick point is 0-based. */
{
    if ((sp == MAXINT) || (sp >= 0 && sp < pointCount)) {
	stickPoint = sp;
	return self;
    }
    return nil;
}

-  setPointCount:(int)n 
 xArray:(double *) xPtr 
 yArray:(double *)yPtr 
{
  if (smoothingArray != NULL)
    _MK_REALLOC(smoothingArray,double,n);
  if (n > pointCount) {
    int i;
    for (i=n; i<pointCount; i++)
      smoothingArray[i] = 1.0;
  }
  return [self setPointCount:n 
	  xArray:xPtr
	  orSamplingPeriod:samplingPeriod /* Old value */
	  yArray:yPtr
	  smoothingArray:smoothingArray /* old value */
	  orDefaultSmoothing:defaultSmoothing]; /* old value */
}

-  setPointCount:(int)n 
 xArray:(double *) xPtr 
 orSamplingPeriod:(double)period 
 yArray:(double *)yPtr 
 smoothingArray:(double *)smoothingPtr 
 orDefaultSmoothing:(double)smoothing
  /* Allocates arrays and fills them with values.
     xP or smoothingP may be NULL, in which case the corresponding constant
     value is used. If yP is NULL, the y values are unchanged. */
{
    if (yPtr) {
	if (yArray != NULL)
	  free(yArray);
	_MK_MALLOC(yArray,double,n);
	memmove( yArray,yPtr, n * sizeof(double)); /* Copy yPtr to yArray */
    }
    if (xPtr == NULL)
      samplingPeriod = period;
    else  {
	if (xArray != NULL)
	  free(xArray);
	_MK_MALLOC(xArray,double,n);
	memmove(xArray, xPtr, n * sizeof(double));
    }
    if (smoothingPtr == NULL)
	defaultSmoothing = smoothing;
    else {
	if (smoothingArray != NULL)
	  free(smoothingArray);
	_MK_MALLOC(smoothingArray,double,n);
	memmove(smoothingArray, smoothingPtr, n * sizeof(double));
    }
    pointCount = n;
    return self;
}

- (double)samplingPeriod
  /* If the samplingPeriod is used (no X points) returns the time step, 
     else MK_NODVAL. */
{
    if (xArray != NULL)
      return MK_NODVAL;
    else return samplingPeriod;
}

- (double *)smoothingArray
  /* Returns a pointer to the array of smoothing values or NULL if there are none. 
     The array is not copied. */
{
    if ((pointCount <= 0) && (smoothingArray == NULL)) 
      return NULL;
    return smoothingArray;
}

-(double)releaseDur
{
    if (((stickPoint == MAXINT) || (stickPoint > pointCount - 1)))
      return 0;
    if (xArray) 
      return xArray[pointCount - 1] - xArray[stickPoint];  
    return samplingPeriod * ((pointCount - 1) - stickPoint);
}

-(double)attackDur
{
    int highPt = (((stickPoint == MAXINT) || (stickPoint > pointCount - 1)) ?
		  (pointCount - 1) : stickPoint);
    if (xArray)
      return xArray[highPt] - xArray[0];
    return highPt * samplingPeriod;
}

- (double *)xArray
  /* Returns a pointer to the array of x values or NULL if there are none. 
     The array is not copied. */
{
    if ((pointCount <= 0) && (xArray == NULL)) 
      return NULL;
    return xArray;
}

- (double *)yArray
  /* Returns a pointer to the array of x values or NULL if there are none. 
     The array is not copied. */
{
    if ((pointCount <= 0) && (yArray == NULL)) 
      return NULL;
    return yArray;
}

MKEnvStatus _MKGetEnvelopeNth(MKEnvelope *self,int n,double *xPtr,double *yPtr,
			      double *smoothingPtr)
    /* Private function. Used by AsympUG. Assumes n > 0. */
{
	if (n >= self->pointCount || (!self->yArray) || 
	    ((!self->xArray) && (self->samplingPeriod == 0)))
  	    return MK_noMorePoints;
	/* Originally, I had the above test in getNth:x:y:smoothing:.  But I
	   realized that it's possible to change an envelope while an Asymp
	   is working on it.  This could cause horrible things to happen so
	   I decided to put the check back in. - daj */
	*xPtr = (self->xArray) ? self->xArray[n] : (n * self->samplingPeriod);
	*yPtr = self->yArray[n]; 
	*smoothingPtr = ((self->smoothingArray) ? self->smoothingArray[n] :
			 self->defaultSmoothing);
	return ((n == (self->pointCount-1)) ? MK_lastPoint :
		(n == self->stickPoint) ? MK_stickPoint : 
		MK_noEnvError);
}

- (MKEnvStatus)	getNth:(int)n x:(double *)xPtr y:(double *)yPtr 
 smoothing:(double *)smoothingPtr
  /* Get Nth point of X and Y. 
     If the point is the last point, MK_lastPoint. Otherwise,
     if the point is the stickpoint, MK_stickPoint is returned.
     If the point is out of bounds, returns MK_noMorePoints. 
     If some other error occurs, returns MK_noMorePoints.
     Otherwise, returns MK_noEnvError. */
{
        if (n < 0)
	    return MK_noMorePoints;
	return _MKGetEnvelopeNth(self,n,xPtr,yPtr,smoothingPtr);
}


-writeScorefileStream:(NSMutableData *)aStream
  /* Writes on aStream the following:
     Writes itself in the form:
     (0.0, 0.0, 1.0)(1.0,2.0,1.0)|(1.0,1.0,1.0)
     Returns nil if yArray is NULL, otherwise self. */
{
    int i;
    double xVal;
    double *yP,*xP,*smoothingP;
    if (yArray == NULL) {
	[aStream appendData:[@"[/* Empty envelope. */]" dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	return nil;
    }
    if (xArray == NULL) 
      for (i = 0, xVal = 0, yP = yArray, smoothingP = smoothingArray; i < pointCount; xVal += samplingPeriod) {
	  if (smoothingP == NULL)
	    if (i == 0) 
	      [aStream appendData:[[NSString stringWithFormat:@"(%.5f, %.5f, %.5f)", xVal,*yP++,
		      defaultSmoothing] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	    else
	      [aStream appendData:[[NSString stringWithFormat:@"(%.5f, %.5f)", xVal,*yP++] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	  else
	    [aStream appendData:[[NSString stringWithFormat:@"(%.5f, %.5f, %.5f)", xVal,*yP++,*smoothingP++] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	  if (i == stickPoint)
	    [aStream appendData:[@" | " dataUsingEncoding:NSNEXTSTEPStringEncoding]];
#         if _MK_LINEBREAKS	  
	  if ((++i % 5 == 0) && i < pointCount)
	    [aStream appendData:[@"\n\t" dataUsingEncoding:NSNEXTSTEPStringEncoding]]; 
#         else
	  i++;
#         endif
      }
    else 
      for (i = 0, xP = xArray, yP = yArray, smoothingP = smoothingArray; i < pointCount; ) {
	  if (smoothingP == NULL)
	    if (i == 0)
	      [aStream appendData:[[NSString stringWithFormat:@"(%.5f, %.5f, %.5f)", *xP++,*yP++,defaultSmoothing] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	    else
	      [aStream appendData:[[NSString stringWithFormat:@"(%.5f, %.5f)", *xP++,*yP++] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	  else [aStream appendData:[[NSString stringWithFormat:@"(%.5f, %.5f, %.5f)", *xP++,*yP++,*smoothingP++] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	  if (i == stickPoint)
	    [aStream appendData:[@" | " dataUsingEncoding:NSNEXTSTEPStringEncoding]];
#         if _MK_LINEBREAKS	  
	  if ((++i % 5 == 0) && i < pointCount)
	    [aStream appendData:[@"\n\t" dataUsingEncoding:NSNEXTSTEPStringEncoding]]; 
#         else
	  ++i;
#         endif
      }
    return self;
}

-_writeBinaryScorefileStream:(NSMutableData *)aStream
  /* Writes on aStream the following:
     Writes itself in the form:
     (0.0, 0.0, 1.0)(1.0,2.0,1.0)|(1.0,1.0,1.0)
     Returns nil if yArray is NULL, otherwise self. */
{
    int i;
    double xVal;
    double *yP,*xP,*smoothingP;
    if (yArray == NULL) {
	_MKWriteChar(aStream,'\0');
	return nil;
    }
    if (xArray == NULL) 
      for (i = 0, xVal = 0, yP = yArray, smoothingP = smoothingArray; 
	   i < pointCount; xVal += samplingPeriod) {
	  if (smoothingP == NULL) {
	      _MKWriteChar(aStream,(i == 0) ? '\3' : '\2');
	      _MKWriteDouble(aStream,xVal);
	      _MKWriteDouble(aStream,*yP++);
	      if (i == 0) 
		_MKWriteDouble(aStream,defaultSmoothing);
	  }
	  else {
	      _MKWriteChar(aStream,'\3');
	      _MKWriteDouble(aStream,xVal);
	      _MKWriteDouble(aStream,*yP++);
	      if (i == 0) 
		_MKWriteDouble(aStream,*smoothingP++);
	  }
	  if (i == stickPoint)
	    _MKWriteChar(aStream,'\1');
	  i++;
      }
    else 
      for (i = 0, xP = xArray, yP = yArray, smoothingP = smoothingArray; 
	   i < pointCount; ) {
	  if (smoothingP == NULL) {
	      _MKWriteChar(aStream,(i == 0) ? '\3' : '\2');
	      _MKWriteDouble(aStream,*xP++);
	      _MKWriteDouble(aStream,*yP++);
	      if (i == 0) 
		_MKWriteDouble(aStream,defaultSmoothing);
	  }
	  else {
	      _MKWriteChar(aStream,'\3');
	      _MKWriteDouble(aStream,*xP++);
	      _MKWriteDouble(aStream,*yP++);
	      _MKWriteDouble(aStream,*smoothingP++);
	  }
	  if (i == stickPoint)
	    _MKWriteChar(aStream,'\1');
	  ++i;
      }
    _MKWriteChar(aStream,'\0');
    return self;
}


-(double)lookupYForX:(double)xVal
  /* Returns, the value at xVal. xVal need not be an 
     actual point of the receiver. If xVal is out of bounds, the 
     beginning (or ending) Y point is returned in *rtnVal. If an error 
     occurs, returns MK_NODVAL */
{
    if (yArray == NULL)
      return MK_NODVAL;
    if (xArray == NULL) {
	if (xVal >= ((pointCount - 1) * samplingPeriod))
	  return yArray[pointCount - 1];
	if (xVal <= 0.0)
	  return *yArray;
	else {
	    int intPart;
	    double fractPart,doubleStep;
	    doubleStep = xVal / samplingPeriod;
	    intPart = (int)doubleStep;
	    fractPart = doubleStep - intPart;
	    return yArray[intPart] + (yArray[intPart + 1] - yArray[intPart]) * fractPart;
	}
    }
    else {
	double *xTmp,*xEnd;
	for (xTmp = xArray, xEnd = xArray + pointCount - 1;
	     *xTmp < xVal && xTmp < xEnd;
	     xTmp++)
	  ;
	if (xTmp == xArray)             /* xVal too small */
	  return *yArray;
	if (*xTmp < xVal) /* xVal too big */
	  return yArray[pointCount - 1]; 
	else {                     /* xVal just right */
	    int i = xTmp - xArray;   
	    double nextX,prevX,nextY,prevY;
	    nextX = *xTmp;
	    prevX = *(xTmp - 1);
	    nextY = yArray[i];
	    prevY = yArray[i - 1];
	    return prevY + ((xVal - prevX)/(nextX - prevX)) * 
	      (nextY - prevY);
	}
    }
    return MK_NODVAL;
}

static double asympPoint(double prevY,
			 double nextY,
			 double prevX,
			 double nextX,
			 double smoothing,
			 double thisX)
{
    #define T48COEFF 5.52620422318571
    double dy = nextY-prevY;
    double dx = nextX-prevX;
    return (prevY + dy - dy * 
	    exp( (prevX - thisX) * T48COEFF / (dx * smoothing)));
}

-(double)lookupYForXAsymptotic:(double)xVal
  /* Same as lookupYForX:, but assumes asymptotic envelopes. */ 
{
    #define T48COEFF 5.52620422318571
    if (yArray == NULL)
      return MK_NODVAL;
    if (xArray == NULL) {
	if (xVal >= ((pointCount - 1) * samplingPeriod))
	  return yArray[pointCount - 1];
	if (xVal <= 0.0)
	  return *yArray;
	else {
	    int intPart;
	    double s;
	    double fractPart,doubleStep;
	    doubleStep = xVal / samplingPeriod;
	    intPart = (int)doubleStep;
	    fractPart = doubleStep - intPart;
	    if (smoothingArray)
		s = smoothingArray[intPart + 1];
	    else s = defaultSmoothing;
	    return asympPoint(yArray[intPart],yArray[intPart+1],
			      0,fractPart,s,xVal);
	}
    }
    else {
	double *xTmp,*xEnd;
	for (xTmp = xArray, xEnd = xArray + pointCount - 1;
	     *xTmp < xVal && xTmp < xEnd;
	     xTmp++)
	  ;
	if (xTmp == xArray)             /* xVal too small */
	  return *yArray;
	if (*xTmp < xVal) /* xVal too big */
	  return yArray[pointCount - 1]; 
	else {                     /* xVal just right */
	    int i = xTmp - xArray;   
	    double s;
	    double nextX,prevX,nextY,prevY;
	    nextX = *xTmp;
	    prevX = *(xTmp - 1);
	    nextY = yArray[i];
	    prevY = yArray[i - 1];
	    if (smoothingArray)
		s = smoothingArray[i];
	    else s = defaultSmoothing;
	    return asympPoint(prevY,nextY,prevX,nextX,s,xVal);
	}
    }
    return MK_NODVAL;
}

@end

