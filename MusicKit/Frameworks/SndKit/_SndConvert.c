/******************************************************************************
LEGAL:
This framework and all source code supplied with it, except where specified, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/
#ifndef WIN32
#import <libc.h>
#else
#import <wtypes.h>
#import <Winsock.h>
#import <malloc.h>
#import <stdio.h>
#endif

#import <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */

#ifndef USE_NEXTSTEP_SOUND_IO
#import "sounderror.h"
#endif
//#import <MKPerformSndMIDI/SndFormats.h>
#import "SndFunctions.h"
#import "SndResample.h"

/* forward decl */
int SndConvertSoundInternal(const SndSoundStruct *fromSound, SndSoundStruct **toSound,BOOL largeFilter, BOOL interpFilter, BOOL fast);

int SndConvertSound(const SndSoundStruct *fromSound, SndSoundStruct **toSound)
/* fastest conversion, non-interpolated */
{
	return SndConvertSoundInternal(fromSound, toSound, FALSE, FALSE, TRUE);
}

int SndConvertSoundGoodQuality(const SndSoundStruct *fromSound, SndSoundStruct **toSound)
/* medium conversion, small filter, uses interpolation */
{
	return SndConvertSoundInternal(fromSound, toSound, FALSE, TRUE, FALSE);
}

int SndConvertSoundHighQuality(const SndSoundStruct *fromSound, SndSoundStruct **toSound)
/* slow, accurate conversion, large filter, uses interpolation */
{
	return SndConvertSoundInternal(fromSound, toSound, TRUE, TRUE, FALSE);
}

int SndConvertSoundInternal(const SndSoundStruct *fromSound, SndSoundStruct **toSound,BOOL largeFilter, BOOL interpFilter, BOOL fast)
{
	static double ONE_OVER_TWO_SIXTEEN = 1.0/65536.0;
	static double ONE_OVER_TWO_EIGHT = 1.0/256.0;
	int cc1,cc2;
	int df1,df2;
	int ds1,ds2; /*dataSize of toSound should really be 0. If it is fragmented, should I SndFree? */
	int sr1,sr2;
	int dl1,dl2;
	double factor;
    int inCount, outCount;
    int width;
	short *outPtr; /* output from resample is always 16 bit */
	void *inPtr; /* input to this routine can be any valid format */

	int i = 0;
	
	int allocedSize;
	
	if (!fromSound) return SND_ERR_NOT_SOUND;
	if (!*toSound) return SND_ERR_NOT_SOUND;
	if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	if ((*toSound)->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
	
	sr1 = fromSound->samplingRate;	sr2 = (*toSound)->samplingRate;
	cc1 = fromSound->channelCount;	cc2 = (*toSound)->channelCount;
	ds1 = fromSound->dataSize;		ds2 = (*toSound)->dataSize;
	df1 = fromSound->dataFormat;	df2 = (*toSound)->dataFormat;
	dl1 = fromSound->dataLocation;	dl2 = (*toSound)->dataLocation;
	
	if (df2 == SND_FORMAT_INDIRECT)
		df2 = (((SndSoundStruct *)(*((SndSoundStruct **)
				((*toSound)->dataLocation))))->dataFormat);
	if (sr1 == sr2 && cc1 == cc2 && df1 == df2)
		return SndCopySound(toSound,fromSound);
	if (df1 == SND_FORMAT_INDIRECT) {
		df1 = ((SndSoundStruct *)(*((SndSoundStruct **)
				dl1)))->dataFormat;
		ds1 = SndSampleCount(fromSound) * cc1 * SndSampleWidth(df1);
	}

	if ((float)((float)cc2/(float)cc1) != (int)(cc2/cc1)
		&& (float)((float)cc1/(float)cc2) != (int)(cc1/cc2)) {
		printf("Can't convert from %d to %d channels (output must be multiple or divisor of input)\n",cc1,cc2);
		return SND_ERR_UNKNOWN;
	}

	SndFree(*toSound);
	factor = (double)sr2/(double)sr1;
	/* Here we allocate enough room for the new number of channels, and data
	 * format, but will adjust the supposed data size to reflect the INPUT data.
	 * This allows us to expand the number of channels etc. later, without having to
	 * create a new sound.
	 */
	allocedSize = (factor * (double)ds1 * (float)((float)cc2 / (float)cc1) * 
		MAX(SndSampleWidth(SND_FORMAT_LINEAR_16),
			MAX(SndSampleWidth(df1), SndSampleWidth(df2)))
			/ (float)SndSampleWidth(df1)) + 1;
	
	SndAlloc(toSound,
		allocedSize,
		df2,
		(int)(sr1 * factor + 0.5),
		cc2,
		(fromSound->dataFormat != SND_FORMAT_INDIRECT) ? 
			fromSound->dataLocation - sizeof(SndSoundStruct) + 4 :
			fromSound->dataSize - sizeof(SndSoundStruct) + 4);
	
	if (cc1 < cc2) {
		(*toSound)->dataSize = (int)(factor * (double)ds1) + 1;
		(*toSound)->channelCount = cc1;
	}

	memmove((*toSound)->info,fromSound->info,
			(*toSound)->dataLocation - sizeof(SndSoundStruct) + 4);

	if (sr1 != sr2) {	
		SndGetDataPointer(*toSound, (char **)(&outPtr), &inCount, &width);
//		printf("Out count: %d, oc * df: %d, alloced size: %d\n",inCount,inCount * 2, allocedSize);
		if (fromSound->dataFormat != SND_FORMAT_INDIRECT) {
			SndGetDataPointer(fromSound, (char **)(&inPtr), &inCount, &width);
			inCount /= cc1;		/* to get sample frames */
			}
		else {
			width = SndSampleWidth(df1);
			inCount = ds1 / cc1 / width;
			inPtr = NULL; /* because we hand the routine a SndSoundStruct */
		}
//		printf("inCount used: %d\n",inCount);
//		outCount = inCount * factor + 1;
		outCount = factor * (ds1 / (float)cc1 / (float)SndSampleWidth(df1)) + 1;
//		printf("outCount used: %d\n",outCount);

		{
			/* (BOOL)interpFilter = interpolate within filter
				* (BOOL)linearInterp: 1 = fastmode
				* (BOOL)largeFilter: 1 = use large filter
				* char *filterFile: NULL = use internal
				*/
			char *filterFile = NULL;
			BOOL linearInterp = fast;
			int outCountReal;
			outCountReal = resample(factor, outPtr, inCount, outCount, MIN(cc1,cc2),
							interpFilter, linearInterp, largeFilter, filterFile, fromSound, 0);
			(*toSound)->dataFormat = SND_FORMAT_LINEAR_16; /* this is the output format */
			(*toSound)->channelCount = MIN(cc1,cc2); /* channel count is reduced if nec */
//			printf("Completed resample. OutCount = %d\n", outCountReal);
			(*toSound)->dataSize = outCountReal * (*toSound)->channelCount 
						* 2; /* 2 is SND_FORMAT_LINEAR_16 */
			SndSwapHostToSound(outPtr, outPtr, outCountReal, (*toSound)->channelCount, SND_FORMAT_LINEAR_16);
		}
	} else {
	/* here I just copy the sound data into outSound. It will have its channels expanded
	 * after this...
	 */
		if (df1 != SND_FORMAT_INDIRECT)
			memmove((char *)(*toSound) + (*toSound)->dataLocation, (char *)fromSound + dl1,
				fromSound->dataSize);
		else {
			int count = 0;
			SndSoundStruct *theStruct;
			char *startLocation = (char *)(*toSound) + dl2;
			SndSoundStruct **ssList = (SndSoundStruct **)dl1;
			while ((theStruct = ssList[i++]) != NULL) {
				memmove(startLocation + count,
					(char *)theStruct + theStruct->dataLocation,
					theStruct->dataSize);
				count += theStruct->dataSize;
			}
		}
	}
	/* now check channel count -- if we need to increase the number of channels from 1 to
	 * 2, or 4, we have hopefully got enough data malloced in *toSound to duplicate pairs
	 * of samples.
	 */
	/* endian-wise, I simply avoid floats and doubles, re-casting as longs and long longs
	 * which should side step the issue nicely.
	 */
	if (cc2 > (*toSound)->channelCount) {
		int c,j,k,origChans,df;
		SndGetDataPointer((*toSound), (char **)(&outPtr), &outCount, &width);
		outCount /= (*toSound)->channelCount;		/* to get sample frames */
		origChans = (*toSound)->channelCount;
		df = (*toSound)->dataFormat; /* if we have changed rate, always linear 16, otherwise 'real' output format */
		k = cc2 / (*toSound)->channelCount; /* multiply factor - num of new channels per original one */
		for (i = outCount-1; i >= 0 ; i--) { /* main slog backwards through the sound */
			for (j = 0; j < k; j++) { /* the number of new channels to create */
				for (c = 0; c < (*toSound)->channelCount; c++) { /* the origin channel */
					if (df == SND_FORMAT_MULAW_8 || df == SND_FORMAT_LINEAR_8)
						((char *)outPtr)[k * (i + c) + j] = ((char *)outPtr)[i * origChans + c];
					else if (df == SND_FORMAT_LINEAR_16)
						((short *)outPtr)[k * (i + c) + j] = ((short *)outPtr)[i * origChans + c];
					else if (df == SND_FORMAT_LINEAR_32)
						((long int *)outPtr)[k * (i + c) + j] = ((long int *)outPtr)[i * origChans + c];
					else if (df == SND_FORMAT_FLOAT)
						((long int *)outPtr)[k * (i + c) + j] = ((long int *)outPtr)[i * origChans + c];
/* cast as long ints, assuming they are same size (32 bit == 4 bytes) as floats */
/*						((float *)outPtr)[k * (i + c) + j] = ((float *)outPtr)[i * origChans + c]; */
					else if (df == SND_FORMAT_DOUBLE)
/* cast as long longs, assuming they are same size (64 bit == 8 bytes) as doubles */
						((long long *)outPtr)[k * (i + c) + j] = ((long long *)outPtr)[i * origChans + c];
/*						((double *)outPtr)[k * (i + c) + j] = ((double *)outPtr)[i * origChans + c]; */
				}
			}
		}
		(*toSound)->channelCount = cc2;
		(*toSound)->dataSize = outCount * cc2 * width;
	}
	
	if ((*toSound)->channelCount > cc2) {	/* channel reduction will already be done by 
											 * resample routine if the sampling rate was changed */
		int k;
		int df = (*toSound)->dataFormat;
#ifdef __LITTLE_ENDIAN__
		SndSwappedFloat swFloat;
		SndSwappedDouble swDouble;
#endif
		int nChansIn = (*toSound)->channelCount;
		int chansToSum = nChansIn / cc2;
		int passes = cc2;/*convenience name*/
		int m,n;
		long sum;
		float sumFloat;
		double sumDouble;

		SndGetDataPointer((*toSound), (char **)(&outPtr), &outCount, &width);
		outCount /= (*toSound)->channelCount;		/* to get sample frames */
		k = cc2 / (*toSound)->channelCount;

		for (i = 0; i < outCount; i++) {
			for (m = 0;m < passes; m++) { /*m and n take us through 1 chnl indep sample*/
				sum = 0;
				sumFloat = 0.0;
				sumDouble = 0.0;
				for (n = 0; n < chansToSum; n++) { /* fairly inefficient. Should pre-swap data
												    * for types which need it.
													*/
					switch(df) {
						case SND_FORMAT_LINEAR_8: /* endian ok */
							sum += ((signed char *)outPtr)[i * nChansIn + n];
							break;
						case SND_FORMAT_MULAW_8: /* endian ok */
							sum += SndiMulaw(((unsigned char *)outPtr)[i * nChansIn + n]);
							break;
						case SND_FORMAT_LINEAR_32:
#ifndef __LITTLE_ENDIAN__
							sumDouble += (long int)(((signed long int *)outPtr)
								[i * nChansIn + n]);
#else
							sumDouble += (long int)((long)ntohl(((signed long int *)outPtr)
								[i * nChansIn + n]));
#endif
							break;
						case SND_FORMAT_FLOAT:
#ifndef __LITTLE_ENDIAN__
							sumFloat += (float)(((float *)outPtr)[i * nChansIn + n]);
#else
							swFloat = ((SndSwappedFloat *)outPtr)[i * nChansIn + n];
							sumFloat += (float)SndSwapSwappedFloatToHost(swFloat);
#endif
							break;
						case SND_FORMAT_DOUBLE:
#ifndef __LITTLE_ENDIAN__
							sumDouble += (double)(((double *)outPtr)[i * nChansIn + n]);
#else
							swDouble = ((SndSwappedDouble *)outPtr)[i * nChansIn + n];
							sumDouble += (double)SndSwapSwappedDoubleToHost(swDouble);
#endif
							break;
						default:
						case SND_FORMAT_LINEAR_16:
#ifndef __LITTLE_ENDIAN__
							sum += ((SND_HWORD *)outPtr)[i * nChansIn + n];
#else
							sum += (short)ntohs(((short *)outPtr)[i * nChansIn + n]);
#endif
							break;
					}
				} /* summing several channels into 1 channel */
				switch(df) {
					case SND_FORMAT_FLOAT:
#ifdef __LITTLE_ENDIAN__
						((SndSwappedFloat *)outPtr)[i * cc2 + m] = (SndSwappedFloat)
							SndSwapHostToSwappedFloat((float)(sumFloat / chansToSum));
#else
						((float *)outPtr)[i * cc2 + m] = (float)(sumFloat / chansToSum);
#endif
						break;
					case SND_FORMAT_DOUBLE:
#ifdef __LITTLE_ENDIAN__
						((SndSwappedDouble *)outPtr)[i * cc2 + m] = (SndSwappedDouble)
							SndSwapHostToSwappedDouble((double)(sumDouble / chansToSum));
#else
						((double *)outPtr)[i * cc2 + m] = (double)(sumDouble / chansToSum);
#endif
						break;
					default:
					case SND_FORMAT_LINEAR_16:
#ifdef __LITTLE_ENDIAN__
						((signed short *)outPtr)[i * cc2 + m] = 
							(short)htons((signed short)(sumDouble / chansToSum));
#else
						((signed short *)outPtr)[i * cc2 + m] =
							(signed short)(sumDouble / chansToSum);
#endif
						break;
					case SND_FORMAT_LINEAR_8: /* endian ok */
						((signed char *)outPtr)[i * cc2 + m] =
							(signed char)(sumDouble / chansToSum);
						break;
					case SND_FORMAT_MULAW_8: /* endian ok */
						((unsigned char *)outPtr)[i * cc2 + m] = (unsigned char)SndMulaw((short)(sumDouble / chansToSum));
						break;
					case SND_FORMAT_LINEAR_32:
#ifdef __LITTLE_ENDIAN__
						((signed long int *)outPtr)[i * cc2 + m] = 
							(short)htonl((signed long int)(sumDouble / chansToSum));
#else
						((signed long int *)outPtr)[i * cc2 + m] = 
							(signed long int)(sumDouble / chansToSum);
#endif
				} 
			} /* passes through chnl indep sample */
		}

		(*toSound)->channelCount = cc2;
		(*toSound)->dataSize = outCount * cc2 * width;
	}

	df1 = (*toSound)->dataFormat; /* allow for current df to have been changed by rate change */
#define LOOP_THRU_SOUND for (i = outCount - 1; i>=0; i--)

	if (df2 > df1) { /* df2 takes up more space than df1, or is at least higher quality */
		SndGetDataPointer((*toSound), (char **)(&outPtr), &outCount, &width);

		if (df2 == SND_FORMAT_LINEAR_8 && df1 == SND_FORMAT_MULAW_8) {
			LOOP_THRU_SOUND {
			((signed char *)outPtr)[i] = (signed char)((short)SndiMulaw(((unsigned char *)outPtr)[i]) * ONE_OVER_TWO_EIGHT);
			}
		}
		else if (df2 == SND_FORMAT_LINEAR_16 && df1 == SND_FORMAT_MULAW_8) {
			LOOP_THRU_SOUND {
			((signed short *)outPtr)[i] = (signed short)
				htons((signed short)SndiMulaw(((unsigned char *)outPtr)[i]));
			}
		}
		else if (df2 == SND_FORMAT_LINEAR_32 && df1 == SND_FORMAT_MULAW_8) {
			LOOP_THRU_SOUND {
			((signed int *)outPtr)[i] = (signed int)
				htonl((signed short)SndiMulaw(((unsigned char *)outPtr)[i]) << 16);
			}
		}
		else if (df2 == SND_FORMAT_FLOAT && df1 == SND_FORMAT_MULAW_8) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedFloat *)outPtr)[i] = (SndSwappedFloat)
				SndSwapHostToSwappedFloat((float)SndiMulaw(((unsigned char *)outPtr)[i]));

#else
			((float *)outPtr)[i] = (float)SndiMulaw(((unsigned char *)outPtr)[i]);
#endif
			}
		}
		else if (df2 == SND_FORMAT_DOUBLE && df1 == SND_FORMAT_MULAW_8) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedDouble *)outPtr)[i] = (SndSwappedDouble)
				SndSwapHostToSwappedDouble((double)SndiMulaw(((unsigned char *)outPtr)[i]));
#else
				((double *)outPtr)[i] = (double)SndiMulaw(((unsigned char *)outPtr)[i]);
#endif
			}
		}

		else if (df2 == SND_FORMAT_LINEAR_16 && df1 == SND_FORMAT_LINEAR_8) {
			LOOP_THRU_SOUND {
			((signed short *)outPtr)[i] = (signed short)htons((short)(((signed char*)outPtr)[i]) << 8);
			}
		}
		else if (df2 == SND_FORMAT_LINEAR_32 && df1 == SND_FORMAT_LINEAR_8) {
			LOOP_THRU_SOUND {
			((signed int *)outPtr)[i] = (signed int)htonl((int)(((signed char*)outPtr)[i]) << 24);
			}
		}
		else if (df2 == SND_FORMAT_FLOAT && df1 == SND_FORMAT_LINEAR_8) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedFloat *)outPtr)[i] = (SndSwappedFloat)
				SndSwapHostToSwappedFloat((float)(((int)((unsigned char *)outPtr)[i]) << 8));

#else
			((float *)outPtr)[i] = (float)(((int)((unsigned char *)outPtr)[i]) << 8);
#endif
			}
		}
		else if (df2 == SND_FORMAT_DOUBLE && df1 == SND_FORMAT_LINEAR_8) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedDouble *)outPtr)[i] = (SndSwappedDouble)
				SndSwapHostToSwappedDouble((double)((int)(((unsigned char *)outPtr)[i]) << 8));
#else
			((double *)outPtr)[i] = (double)((int)(((unsigned char *)outPtr)[i]) << 8);
#endif
			}
		}

		else if (df2 == SND_FORMAT_LINEAR_32 && df1 == SND_FORMAT_LINEAR_16) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed int *)outPtr)[i] = (signed int)
				htonl((signed int)ntohs(((signed short *)outPtr)[i]) << 16);
#else
			((signed int *)outPtr)[i] = (signed int)((signed short *)outPtr)[i] << 16;
#endif
			}
		}
		else if (df2 == SND_FORMAT_FLOAT && df1 == SND_FORMAT_LINEAR_16) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedFloat *)outPtr)[i] = (SndSwappedFloat)
				SndSwapHostToSwappedFloat(ntohs(((signed short *)outPtr)[i]));
#else
			((float *)outPtr)[i] = (float)((signed short *)outPtr)[i];
#endif
			}
		}
		else if (df2 == SND_FORMAT_DOUBLE && df1 == SND_FORMAT_LINEAR_16) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedDouble *)outPtr)[i] = (SndSwappedDouble)
				SndSwapHostToSwappedDouble(ntohs(((signed short *)outPtr)[i]));
#else
			((double *)outPtr)[i] = (double)((signed short *)outPtr)[i];
#endif
			}
		}

		else if (df2 == SND_FORMAT_FLOAT && df1 == SND_FORMAT_LINEAR_32) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedFloat *)outPtr)[i] = (SndSwappedFloat)
				SndSwapHostToSwappedFloat(ntohl(((signed int *)outPtr)[i]));
#else
			((float *)outPtr)[i] = (float)(((signed int *)outPtr)[i] * ONE_OVER_TWO_SIXTEEN);
#endif
			}
		}
		else if (df2 == SND_FORMAT_DOUBLE && df1 == SND_FORMAT_LINEAR_32) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedDouble *)outPtr)[i] = (SndSwappedDouble)
				SndSwapHostToSwappedDouble(ntohl(((signed int *)outPtr)[i]));
#else
			((double *)outPtr)[i] = (double)(((signed int *)outPtr)[i] * ONE_OVER_TWO_SIXTEEN);
#endif
			}
		}

		else if (df2 == SND_FORMAT_DOUBLE && df1 == SND_FORMAT_FLOAT) {
			LOOP_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedDouble *)outPtr)[i] = (SndSwappedDouble)
				SndSwapHostToSwappedDouble((float)SndSwapSwappedFloatToHost(
				((SndSwappedFloat *)outPtr)[i]));
#else
			((double *)outPtr)[i] = (double)(((float *)outPtr)[i]);
#endif
			}
		}
		
		else {
			printf("Sorry, format unsupported for conversion\n");
			SndFree(*toSound);
			return SND_ERR_BAD_FORMAT;
		}
		(*toSound)->dataFormat = df2;
		/* that should be all the common ones. Maybe aLaw too? */
		(*toSound)->dataSize = outCount * SndSampleWidth(df2);
	}
#define LOOP_FORWARD_THRU_SOUND for (i = 0 ; i < outCount; i++)
	if (df2 < df1) { /* df2 takes up less space than df1, or is lower quality */
		SndGetDataPointer((*toSound), (char **)(&outPtr), &outCount, &width);

		if (df1 == SND_FORMAT_LINEAR_8 && df2 == SND_FORMAT_MULAW_8) {
			LOOP_FORWARD_THRU_SOUND {
			((unsigned char *)outPtr)[i] = (unsigned char)
				((int)SndMulaw(((signed char *)outPtr)[i] * 256));
			}
		}
		else if (df1 == SND_FORMAT_LINEAR_16 && df2 == SND_FORMAT_MULAW_8) {
			LOOP_FORWARD_THRU_SOUND {
			((unsigned char *)outPtr)[i] = (unsigned char)
#ifdef __LITTLE_ENDIAN__
				SndMulaw((signed short)ntohs(((signed short *)outPtr)[i]));
#else
				SndMulaw(((signed short *)outPtr)[i]);
#endif
			}
		}
		else if (df1 == SND_FORMAT_LINEAR_32 && df2 == SND_FORMAT_MULAW_8) {
			LOOP_FORWARD_THRU_SOUND {
			((unsigned char *)outPtr)[i] = (unsigned char)
#ifdef __LITTLE_ENDIAN__
				SndMulaw((float)((signed int)ntohl(((signed int *)outPtr)[i]) * ONE_OVER_TWO_SIXTEEN));
#else
				SndMulaw(((signed int *)outPtr)[i] * ONE_OVER_TWO_SIXTEEN);
#endif
			}
		}
		else if (df1 == SND_FORMAT_FLOAT && df2 == SND_FORMAT_MULAW_8) {
			LOOP_FORWARD_THRU_SOUND {
			((unsigned char *)outPtr)[i] = (unsigned char)
#ifdef __LITTLE_ENDIAN__
				SndiMulaw((float)SndSwapSwappedFloatToHost(((SndSwappedFloat *)outPtr)[i]));
#else
				SndiMulaw(((float *)outPtr)[i]);
#endif
			}
		}
		else if (df1 == SND_FORMAT_DOUBLE && df2 == SND_FORMAT_MULAW_8) {
			LOOP_FORWARD_THRU_SOUND {
			((unsigned char *)outPtr)[i] = (unsigned char)
#ifdef __LITTLE_ENDIAN__
				SndiMulaw((double)SndSwapSwappedDoubleToHost(((SndSwappedDouble *)outPtr)[i]));
#else
				SndiMulaw(((double *)outPtr)[i]);
#endif
			}
		}

		else if (df1 == SND_FORMAT_LINEAR_16 && df2 == SND_FORMAT_LINEAR_8) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed char*)outPtr)[i] = (signed short)ntohs(((signed short *)outPtr)[i]) >> 8;
#else
			((signed char*)outPtr)[i] = (((signed short *)outPtr)[i]) >> 8;
#endif
			}
		}
		else if (df1 == SND_FORMAT_LINEAR_32 && df2 == SND_FORMAT_LINEAR_8) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed char *)outPtr)[i] = (signed int)ntohl(((signed int *)outPtr)[i]) >> 24;
#else
			((signed char *)outPtr)[i] = (int)(((signed int *)outPtr)[i]) >> 24;
#endif
			}
		}
		else if (df1 == SND_FORMAT_FLOAT && df2 == SND_FORMAT_LINEAR_8) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((unsigned char *)outPtr)[i] = (unsigned char)
				(((int)SndSwapSwappedFloatToHost(((SndSwappedFloat *)outPtr)[i])) >> 8);
#else
			((unsigned char *)outPtr)[i] = (unsigned char)
				(((int)((float *)outPtr)[i]) >> 8);
#endif
			}
		}
		else if (df1 == SND_FORMAT_DOUBLE && df2 == SND_FORMAT_LINEAR_8) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((unsigned char *)outPtr)[i] = (unsigned char)
				(((int)SndSwapSwappedDoubleToHost(((SndSwappedDouble *)outPtr)[i])) >> 8);
#else
			((unsigned char *)outPtr)[i] = ((int)(((double *)outPtr)[i]) >> 8);
#endif
			}
		}

		else if (df1 == SND_FORMAT_LINEAR_32 && df2 == SND_FORMAT_LINEAR_16) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed short *)outPtr)[i] = (signed short)
				htons((int)ntohl(((signed int *)outPtr)[i]) >> 16);
#else
			((signed short *)outPtr)[i] = ((signed int *)outPtr)[i] >> 16;
#endif
			}
		}
		else if (df1 == SND_FORMAT_FLOAT && df2 == SND_FORMAT_LINEAR_16) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed short *)outPtr)[i] = (signed short)
				htons(SndSwapSwappedFloatToHost(((SndSwappedFloat *)outPtr)[i]));
#else
			((signed short *)outPtr)[i] = ((float *)outPtr)[i];
#endif
			}
		}
		else if (df1 == SND_FORMAT_DOUBLE && df2 == SND_FORMAT_LINEAR_16) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed short *)outPtr)[i] = (signed short)
				htons(SndSwapSwappedDoubleToHost(((SndSwappedDouble *)outPtr)[i]));
#else
			((signed short *)outPtr)[i] = ((double *)outPtr)[i];
#endif
			}
		}

		else if (df1 == SND_FORMAT_FLOAT && df2 == SND_FORMAT_LINEAR_32) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed int *)outPtr)[i] = (signed int)
				htonl(SndSwapSwappedFloatToHost(((SndSwappedFloat *)outPtr)[i]) * 65536);
#else
			((signed int *)outPtr)[i] = ((float *)outPtr)[i] * 65536;
#endif
			}
		}
		else if (df1 == SND_FORMAT_DOUBLE && df2 == SND_FORMAT_LINEAR_32) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((signed int *)outPtr)[i] = (signed int)
				htonl(SndSwapSwappedDoubleToHost(((SndSwappedDouble *)outPtr)[i]) * 65536);
#else
			((signed int *)outPtr)[i] = ((double *)outPtr)[i] * 65536;
#endif
			}
		}

		else if (df1 == SND_FORMAT_DOUBLE && df2 == SND_FORMAT_FLOAT) {
			LOOP_FORWARD_THRU_SOUND {
#ifdef __LITTLE_ENDIAN__
			((SndSwappedFloat *)outPtr)[i] = (SndSwappedFloat)
				SndSwapHostToSwappedFloat((float)
				SndSwapSwappedDoubleToHost(((SndSwappedDouble *)outPtr)[i]));
#else
			((float *)outPtr)[i] = ((double *)outPtr)[i];
#endif
			}
		}
		
		else {
			printf("Sorry, format unsupported for conversion\n");
			SndFree(*toSound);
			return SND_ERR_BAD_FORMAT;
		}
		(*toSound)->dataFormat = df2;
		/* that should be all the common ones. Maybe aLaw too? */
		(*toSound)->dataSize = outCount * SndSampleWidth(df2);
	}
//	printf("alloced size: %d official size: %d\n", allocedSize, (*toSound)->dataSize);
	if ((*toSound)->dataSize < allocedSize) /* only decrease space if necessary */
		*toSound = realloc(*toSound,(*toSound)->dataSize + (*toSound)->dataLocation);
	return SND_ERR_NONE;
}
