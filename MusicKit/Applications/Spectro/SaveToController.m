/*
 * You may freely copy, distribute and reuse the code in this example.  
 * NeXT disclaims any warranty of any kind, expressed or implied, as to 
 * its fitness for any particular use.
 */

#import "SaveToController.h"
#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>

@implementation SaveToController

#define LINEAR_ROW 0
#define MULAW_ROW 1
#define COMPRESSED_ROW 2

static int _dataFormatToRow(int dataFormat)
{
    int format_row;

    switch (dataFormat) {
    case SND_FORMAT_LINEAR_16:
    case SND_FORMAT_EMPHASIZED:
	format_row = LINEAR_ROW;
	break;
    case SND_FORMAT_MULAW_8:
	format_row = MULAW_ROW;
	break;
    case SND_FORMAT_COMPRESSED:
    case SND_FORMAT_COMPRESSED_EMPHASIZED:
	format_row = COMPRESSED_ROW;
	break;
    default:
	return LINEAR_ROW; /* Try to convert unsupported formats to linear */
    }
    return format_row;
}

static int _rowToDataFormat(int row)
{
    int dataFormat;
    switch (row) {
    case LINEAR_ROW:
	dataFormat = SND_FORMAT_LINEAR_16;
	break;
    case MULAW_ROW:
	dataFormat = SND_FORMAT_MULAW_8;
	break;
    case COMPRESSED_ROW:
	dataFormat = SND_FORMAT_COMPRESSED;
	break;
    default:
	return -1;
    }
    return dataFormat;
}

/*
 * Note that the Sound object's convertToSampleFormat: method will convert
 * to or from any sampling rate.  However, to minimize confusion for
 * casual users, we restrict the choices to the three which arise
 * naturally on the NeXT Computer.
 */
static const double supportedRates[3] 
	= { SND_RATE_CODEC, SND_RATE_LOW, SND_RATE_HIGH };

static double _rowToSamplingRate(int row)
{
    if (row < 0 || row > 2) row = 2;
    return supportedRates[row];
}

static int deq(double d1, double d2)
/* Return 1 if d1 and d2 are "equal" to within one int step */
{
    return ((abs(d1-d2)<=1.0) ? 1 : 0);
}

static int _samplingRateToRow(double srate)
{
    int i;
    for (i=0; i<3; i++)
      if (deq(srate,supportedRates[i]))
	return i;
    return 2; /* Try to convert unsupported rates to 44.1 KHz */
}

- soundTemplate
/* 
 * Create an empty sound conveying the requested format
 */
{
    [newSound release];
    newSound = [[Snd alloc] initWithFormat: newDataFormat
			      channelCount: newChannelCount
				    frames: 0
			      samplingRate: newSamplingRate];
	
    return newSound;
}

- (void)setSound:(Snd *)nSound
{
    double samplingRate;
    int channelCount;
    int dataFormat;
    int format_row;
    int srate_row;
    int size;

    sound = nSound;

    newSamplingRate = samplingRate = [sound samplingRate];
    newChannelCount = channelCount = [sound channelCount];
    newDataFormat = dataFormat = [sound dataFormat];
    size = [sound dataSize];

    format_row = _dataFormatToRow(dataFormat);
    srate_row = _samplingRateToRow(samplingRate);
	/*sb: added next line 19/6/99, because if original sampling
	 * rate was not one of the standard ones, the new rate
	 * would not be set unless the user physically set a new value.
	 */
	if (srate_row == 2) newSamplingRate = 44100;

    [newChnMtx selectCellAtRow:channelCount-1 column:0];
    [newFmtMtx selectCellAtRow:format_row column:0];
    [newFsMtx selectCellAtRow:srate_row column:0];
}

- revert:sender
{
    [self setSound:sound];
    return self;
}

- setNewChn:sender
{
    newChannelCount = 1+[sender selectedRow];
    return self;
}

- setNewFmt:sender
{
    newDataFormat = _rowToDataFormat([sender selectedRow]);
    return self;
}

- setNewFs:sender
{
    newSamplingRate = _rowToSamplingRate([sender selectedRow]);
    return self;
}

@end
