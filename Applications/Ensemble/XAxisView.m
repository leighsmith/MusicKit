#import "XAxisView.h"
#import <math.h>

static float labelInterval(float valueRange, float width, float labelWidth,
							int *precision)
{
	float interval, logInterval;
	interval = (valueRange/width)*labelWidth*1.1;
	logInterval = (float)rint(log10((double)interval)+.5);
	interval = pow(10.0, logInterval);
	*precision = (logInterval < 0) ? -logInterval : 0;
	while (width*interval/valueRange > labelWidth*3.0) {
		interval *= 0.5;
		if (interval < 5) *precision += 1;
	}
	return interval;
}

@implementation XAxisView

- initFrame:(NXRect const *)theFrame
{
	[super initFrame:theFrame];
	[self setClipping:NO];
	needNewUserPath = YES;
	font = [Font newFont:"Helvetica" size:12 matrix:NX_IDENTITYMATRIX];
	[self setMaxDisplayValue:20.0];
	lineGray = NX_BLACK;
	backgroundGray = NX_LTGRAY;
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

- setMinDisplayValue:(float)value
{
	minValue = value;
	if ((maxValue-minValue) != 0.0)
		resolution = pow(10.0,floor(log10((maxValue-minValue)/bounds.size.width)));
	needNewUserPath = YES;
	return self;
}

- setMaxDisplayValue:(float)value
{
	maxValue = value;
	if ((maxValue-minValue) != 0.0)
		resolution = pow(10.0,floor(log10((maxValue-minValue)/bounds.size.width)));
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

- (float)valueForX:(float)x
{
	float val = minValue + (maxValue-minValue)*x/bounds.size.width;
	return (float)((int)(val/resolution))*resolution;
}

- (float)xForValue:(float)value
{
	return 
		floor(bounds.size.width * (value-minValue)/(maxValue-minValue)+1.0)-0.5;
}

- (int)majorTicks
{
	return majorTicks;
}

- (int)minorTicks
{
	return minorTicks;
}

- (float)firstMajorTick
{
	return firstMajorTick;
}

- (float)majorTickInterval
{
	return majorTickInterval;
}

- createUserPath
{
	float majorValueInterval, majorValue,
		   minorValue, minorInterval, valuePerPixel, x, maxx,
		   minval = minValue, maxval = maxValue, valdiff;
	int minorDivs, tick, oi = 0, ci = 0;
	char s[32];
	char **l, **end;
	float *f, w;
	int precision;
	float majorTickHeight, minorTickHeight;
	float width = bounds.size.width - (constrained ? 3.0 : 0.5);
	
	if (maxval == minval) {
		minval -= 1.0;
		maxval += 1.0;
	}
	valdiff = maxval - minval;
	
	sprintf(s,"%.2f", maxValue);
	majorValueInterval = 
		labelInterval(valdiff, width, [font getWidthOf:s], &precision);
	valuePerPixel = valdiff / width;
	majorTickInterval = majorValueInterval / valuePerPixel;
	minorDivs = (majorTickInterval>64.0) ? 5 : ((majorTickInterval>32.0) ? 2 : 1);
	majorValue = ceil(minval/majorValueInterval)*majorValueInterval;
	minorInterval = majorTickInterval / minorDivs;
	tick = ceil(minval/(majorValueInterval/minorDivs));
	minorValue = tick * (majorValueInterval / minorDivs);
	x = (minorValue - minval) / valuePerPixel + (constrained ? 1.0 : 0.0);
	firstMajorTick = (majorValue - minval) / valuePerPixel + (constrained ? 1.0 : 0.0);
	maxx = width + 1.0;
	majorTickHeight = bounds.size.height-[font pointSize]-2.0;
	majorTickHeight = MIN(majorTickHeight,12.0);
	minorTickHeight = majorTickHeight * .618;
	
	if (showLabels) {
		sprintf(s,"%.*f", precision, maxValue);
		labelWidth = [font getWidthOf:s];
	}
	else labelWidth = 0.0;
	
	minorTicks = (int)ceil(valdiff / (majorValueInterval / minorDivs)) + 1;
	majorTicks = (int)ceil(valdiff / majorValueInterval) + 1;
	
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
			sprintf(*l++, "%.*f", precision, majorValue);
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
	minorTicks = 0;
	
    while (x <= (maxx+.01)) {
		if ((tick++ % minorDivs) == 0) {
			cArray[ci++] = floor(x+1.0)-0.5;
			cArray[ci++] = bounds.size.height - majorTickHeight;
			oArray[oi++] = dps_moveto;
			cArray[ci++] = 0.0;
			cArray[ci++] = majorTickHeight;
			oArray[oi++] = dps_rlineto;
			if (showLabels) {
				w = [font getWidthOf:*l++];
				*f = x - w*.5 - 1.0;
				if (constrained)
					*f = MIN(MAX(*f,1.0),width-w+1.0);
				f++;
			}
			majorTicks++;
		}
		else {
			cArray[ci++] = floor(x+1.0)-0.5;
			cArray[ci++] = bounds.size.height - minorTickHeight;
			oArray[oi++] = dps_moveto;
			cArray[ci++] = 0.0;
			cArray[ci++] = minorTickHeight;
			oArray[oi++] = dps_rlineto;
		}
		x += minorInterval;
		minorTicks++;
    }

    /* fill bbox */
    bbox[0] = 0.0;
    bbox[1] = 0.0;
    bbox[2] = bounds.size.width;
    bbox[3] = bounds.size.height;
	needNewUserPath = NO;
	return self;
}

- setFrame:(const NXRect *)rect
{
	[super setFrame:rect];
	if ((maxValue-minValue) != 0.0)
		resolution = pow(10.0,floor(log10((maxValue-minValue)/bounds.size.width)));
	needNewUserPath = YES;
	return self;
}

- sizeTo:(NXCoord)width :(NXCoord)height
{
	[super sizeTo:width:height];
	if ((maxValue-minValue) != 0.0)
		resolution = pow(10.0,floor(log10((maxValue-minValue)/bounds.size.width)));
	needNewUserPath = YES;
	return self;
}

- drawLines:(const NXRect *)rect
{
	float *c = cArray;
	float *end = c + minorTicks*4;
	int i = 0, n = 0;
	float x1 = MAX(rect->origin.x,(constrained ? 1.0 : 0.0));
	float x2 = MIN(rect->origin.x+rect->size.width,bounds.size.width-1.0);

	PSsetlinewidth(2.0);
	PSmoveto(x1,bounds.size.height-1.0);
	PSlineto(x2,bounds.size.height-1.0);
	PSstroke();
	
	x1 -= 1.0;
	x2 += 1.0;
	while (*c < x1) {
		if (c+4 < end) c += 4; else break;
		i++;
	}
	while ((c < end) && (*c <= x2)) {
		n++;
		c += 4;
	}

	PSsetlinewidth(1.0);
    DPSDoUserPath(cArray+i*4, n*4, dps_float,
				  oArray+i*2, n*2, bbox, dps_ustroke);
	return self;
}	

- drawLabels:(const NXRect *)rect
{
	char **l = labelArray;
	char **end = l + majorTicks;
	float *f = labelPositions;
	float x1 = rect->origin.x;
	float x2 = rect->origin.x+rect->size.width;
	while (l < end) {
		if (!((*f+labelWidth < x1) || (*f > x2))) {
			PSmoveto(*f, 2.0);
			PSshow(*l);
		}
		l++;
		f++;
	}
	return self;
}

- fillBackground:(const NXRect *)rect
{
	PSsetgray(backgroundGray);
	if (!constrained) {
		/* Ensure that the label's area outside our bounds is filled if necessary */
		NXRect r = *rect;
		float w = labelWidth*0.5;
		if (bounds.size.width-(r.origin.x+r.size.width) < 1.0)
			r.size.width += w;
		if (r.origin.x == 0.0) {
			r.origin.x -= w;
			r.size.width += w;
			NXRectFill(&r);		
		}
	}
	else NXRectFill(rect);		
	return self;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
	if (rectCount==1)
		[self fillBackground:&(rects[0])];
	else {
		[self fillBackground:&(rects[1])];
		[self fillBackground:&(rects[2])];
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
