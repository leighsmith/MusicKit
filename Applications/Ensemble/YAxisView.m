#import "YAxisView.h"
#import <math.h>

static float labelInterval(float valueRange, float height, float fontSize, 
							int *precision)
{
	float interval, logInterval;
	BOOL negative = (valueRange < 0);
	if (negative) valueRange = -valueRange;
	interval = (valueRange/height)*fontSize*1.1;
	logInterval = (float)rint(log10((double)interval)+.5);
	interval = pow(10.0, logInterval);
	while (height*interval/valueRange > fontSize*4.0) {
		interval *= 0.5;
		logInterval -= 1;
	}
	*precision = (logInterval < 0) ? -logInterval : 0;
	return (negative) ? -interval : interval;
}

static int getPrecision(double value, int maxPrecision)
{
	int precision = 0;
	while ((precision < maxPrecision) &&
		   (fabs(value-rint(value)) > .05)) {
		value *= 10.0;
		precision += 1;
	}
	return precision;
}


@implementation YAxisView

- initFrame:(NXRect const *)theFrame
{
	[super initFrame:theFrame];
	[self setClipping:NO];
	needNewUserPath = YES;
	font = [Font newFont:"Helvetica" size:12 matrix:NX_IDENTITYMATRIX];
	[self setMaxDisplayValue:20.0];
	lineGray = NX_BLACK;
	backgroundGray = NX_LTGRAY;
	autoTicks = YES;
	minorDivs = 2;
	majorTicks = 2;
	minorTicks = (majorTicks-1)*minorDivs + 1;
	showLabels = YES;
	constrained = YES;
	return self;
}

- free
{
	if (cArray) free(cArray);
	if (oArray) free(oArray);
	return [super free];
}

- setFontSize:(float)size
{
	font = [Font newFont:"Helvetica" size:size matrix:NX_IDENTITYMATRIX];
	return self;
}

- setLineGray:(float)gray
{
	lineGray = gray;
	return self;
}

- setBackgroundGray:(float)gray
{
	backgroundGray = gray;
	return self;
}

- (float)lineGray
{
	return lineGray;
}

- (float)backgroundGray
{
	return backgroundGray;
}

- setShowLabels:(BOOL)flag
{
	showLabels = flag;
	return self;
}

- setConstrained:(BOOL)flag
{
	constrained = flag;
	return self;
}

- setAutoTicks:(BOOL)flag
{
	autoTicks = flag;
	return self;
}

- setMajorTicks:(int)numTicks
{
	majorTicks = numTicks;
	minorTicks = (majorTicks-1)*minorDivs + 1;
	autoTicks = NO;
	needNewUserPath = YES;
	return self;
}

- setMinorDivs:(int)numDivs
{
	minorDivs = numDivs;
	minorTicks = (majorTicks-1)*minorDivs + 1;
	autoTicks = NO;
	needNewUserPath = YES;
	return self;
}

- setMinDisplayValue:(float)value
{
	minValue = MIN(value,maxValue-.000001);
	if ((maxValue-minValue) != 0.0)
		resolution = pow(10.0,floor(log10((maxValue-minValue)/bounds.size.height)));
	needNewUserPath = YES;
	return self;
}

- setMaxDisplayValue:(float)value
{
	maxValue = MAX(value,minValue+.000001);
	if ((maxValue-minValue) != 0.0)
		resolution = pow(10.0,floor(log10((maxValue-minValue)/bounds.size.height)));
	needNewUserPath = YES;
	return self;
}

- (float)minDisplayValue
{
	return minValue;
}

- (float)maxDisplayValue
{
	return maxValue;
}

- (float)valueForY:(float)y
{
	float val = minValue + (maxValue-minValue)*y/bounds.size.height;
	return (float)((int)(val/resolution))*resolution;
}

- (float)yForValue:(float)value
{
	return 
		floor(bounds.size.height * (value-minValue)/(maxValue-minValue)+1.0)-0.5;
}

- (int)majorTicks
{
	return majorTicks;
}

- (int)minorDivs
{
	return minorDivs;
}

- (float)majorTickInterval
{
	return majorTickInterval;
}

- (float)firstMajorTick
{
	return firstMajorTick;
}

- createUserPath
{
	float majorValueInterval, majorValue,
		   minorValue, minorInterval, valuePerPixel, y, maxy, valdiff;
	int tick, oi = 0, ci = 0;
	char **l, **end;
	float *f;
	int precision;
	float majorTickWidth, minorTickWidth, height = bounds.size.height;
	char s[32];
	labelHeight = [font pointSize];
	
	if (constrained) height -= 3.0;
	
	valdiff = maxValue - minValue;
	
	if (autoTicks) {
		majorValueInterval = labelInterval(valdiff, height, labelHeight, &precision);
		valuePerPixel = valdiff / height;
		majorTickInterval = majorValueInterval / valuePerPixel;
		minorDivs = (majorTickInterval>60.0) ? 5 : ((majorTickInterval>30.0) ? 2 : 1);
		majorValue = ceil(minValue/majorValueInterval)*majorValueInterval;
		minorInterval = majorTickInterval / minorDivs;
		tick = ceil(minValue/(majorValueInterval/minorDivs));
		minorValue = tick * (majorValueInterval / minorDivs);
		y = (minorValue - minValue) / valuePerPixel;
		firstMajorTick = (majorValue - minValue) / valuePerPixel;
		if (constrained) y += 1.0;
		maxy = height + 1.0;
		minorTicks = (int)ceil(valdiff / (majorValueInterval / minorDivs)) + 1;
		majorTicks = (int)floor(valdiff / majorValueInterval) + 1;
	}
	else {
		float w = [font getWidthOf:"4"];
		int n = (int)((bounds.size.width-5.0)/w) - 3;
		int precision1 = getPrecision(maxValue, n - floor(log10(maxValue)));
		int precision2 = getPrecision(minValue, n - floor(log10(minValue)));
		precision = MAX(precision1, precision2);
		majorValueInterval = valdiff / (majorTicks-1);
		valuePerPixel = valdiff / height;
		majorTickInterval = majorValueInterval / valuePerPixel;
		majorValue = minValue;
		minorInterval = majorTickInterval / minorDivs;
		tick = 0;
		y = constrained ? 1.0 : 0;
		maxy = height + 1.0;
		minorTicks = (majorTicks-1)*minorDivs + 1;
	}
	
	if (showLabels) {
		float w;
		sprintf(s,"%.*f", precision, -MAX(fabs(maxValue),fabs(minValue)));
		w = [font getWidthOf:s] + 1.0;
		labelWidth = MAX(labelWidth,w);
		if (labelWidth >= bounds.size.width-2.0) {
			showLabels = NO;
			labelWidth = 0;
		}
	}
	else labelWidth = 0;

	majorTickWidth = bounds.size.width-labelWidth-1.0;
	majorTickWidth = MIN(majorTickWidth,12.0);
	minorTickWidth = majorTickWidth * .6;

	if (showLabels) {
		if (majorTicks > labelArraySize) {
			int i;
			labelArray = 
				NXZoneRealloc([self zone], (void *)labelArray, 
								sizeof(char *)*majorTicks);
			labelPositions = 
				NXZoneRealloc([self zone], (void *)labelPositions, 
							sizeof(float)*majorTicks);
			for (i=labelArraySize; i<majorTicks; i++)
				labelArray[i] = NXZoneMalloc([self zone], sizeof(char)*32);
			labelArraySize = majorTicks;
		}
		l = labelArray;
		end = l + majorTicks;
		while (l < end) {
			if (precision > 0)
				sprintf(*l++, "%.*f", precision, majorValue);
			else
				sprintf(*l++, "%d", (int)floor(majorValue+.5));
			majorValue += majorValueInterval;
		}
	}		
	
	if (cArray) NXZoneFree([self zone],cArray);
	if (oArray) NXZoneFree([self zone],oArray);

    cArray = (float *)NXZoneMalloc([self zone], 4*(minorTicks)*sizeof(float));
    oArray = (char *)NXZoneMalloc([self zone], (2*(minorTicks))*sizeof(char));

	l = labelArray;
	f = labelPositions;
	majorTicks = 0;
	
    while (y <= (maxy+.01)) {
		if ((tick++ % minorDivs) == 0) {
			cArray[ci++] = bounds.size.width - majorTickWidth;
			cArray[ci++] = floor(y+1.0)-0.5;
			oArray[oi++] = dps_moveto;
			cArray[ci++] = majorTickWidth;
			cArray[ci++] = 0.0;
			oArray[oi++] = dps_rlineto;
			if (showLabels) {
				*f = y - labelHeight*.4;
				if (constrained)
					*f = MIN(MAX(*f,1.0),height-labelHeight+1.0);
				f++;
			}
			majorTicks++;
		}
		else {
			cArray[ci++] = bounds.size.width - minorTickWidth;
			cArray[ci++] = floor(y+1.0)-0.5;
			oArray[oi++] = dps_moveto;
			cArray[ci++] = minorTickWidth;
			cArray[ci++] = 0.0;
			oArray[oi++] = dps_rlineto;
		}
		y += minorInterval;
    }

	minorTicks = ci/4;

    /* fill bbox */
    bbox[0] = 0.0;
    bbox[1] = 0.0;
    bbox[2] = bounds.size.width+1.0;
    bbox[3] = bounds.size.height+1.0;
	needNewUserPath = NO;
	return self;
}

- sizeTo:(NXCoord)width :(NXCoord)height
{
	if ((maxValue-minValue) != 0.0)
		resolution = pow(10.0,floor(log10((maxValue-minValue)/bounds.size.height)));
	needNewUserPath = YES;
	return [super sizeTo:width:height];
}

- drawLines:(const NXRect *)rect
{
	float *c = cArray+1;
	float *end = c + minorTicks*4;
	int i = 0, n = 0;
	float y1 = rect->origin.y;
	float y2 = rect->origin.y+rect->size.height;
	
	if (constrained) {
		y1 = MAX(y1, 1.0);
		y2 = MIN(y2, bounds.size.height-1.0);
	}

	PSsetlinewidth(2.0);
	PSmoveto(bounds.size.width, y1);
	PSlineto(bounds.size.width, y2);
	PSstroke();
	
	y1 -= 1.0;
	y2 += 1.0;
	
	while (*c < y1) {
		if (c+4 < end) c += 4; else break;
		i++;
	}
	while ((c < end) && (*c <= y2)) {
		n++;
		c += 4;
	}

	if (n) {
		PSsetlinewidth(1.0);
    	DPSDoUserPath(cArray+i*4, n*4, dps_float,
				  oArray+i*2, n*2, bbox, dps_ustroke);
	}
	return self;
}	

- drawLabels:(const NXRect *)rect
{
	char **l = labelArray;
	char **end = l + majorTicks;
	float w, *f = labelPositions;
	float y1 = rect->origin.y;
	float y2 = rect->origin.y+rect->size.height;
	while (l < end) {
		if (!((*f+labelHeight < y1) || (*f > y2))) {
			w = [font getWidthOf:*l];
			if (!constrained && ((*f < 0) || (*f+labelHeight > bounds.size.height))) {
				NXRect r;
				r.origin.x = 0.0;
				r.origin.y = *f-1.0;
				r.size.height = labelHeight+2.0;
				r.size.width = labelWidth;
				PSsetgray(backgroundGray);
				NXRectFill(&r);
				PSsetgray(lineGray);
			}
			w = [font getWidthOf:*l];
			PSmoveto(labelWidth-w, *f);
			PSshow(*l);
		}
		l++;
		f++;
	}
	return self;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
	PSsetgray(backgroundGray);
	if (rectCount==1) {
		if (constrained)
			NXRectFill(&(rects[0]));
		else {
			NXRect r = rects[0];
			r.origin.y -= labelHeight * .5;
			r.size.height += labelHeight;
			NXRectFill(&r);
		}
	}
	else {
		NXRectFill(&(rects[1]));
		NXRectFill(&(rects[2]));
	}

	if (needNewUserPath) [self createUserPath];

	PSsetgray(lineGray);
	if (rectCount==1)
		[self drawLines:&(rects[0])];
	else {
		[self drawLines:&(rects[1])];
		[self drawLines:&(rects[2])];
	}

	if (showLabels) {
		[font set];
		if (rectCount==1)
			[self drawLabels:&(rects[0])];
		else {
			[self drawLabels:&(rects[1])];
			[self drawLabels:&(rects[2])];
		}
	}
	return self;
}

@end
