/******************************************************************************
LEGAL:
This framework and all source code supplied with it, except where specified, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#import <MKPerformSndMIDI/PerformSound.h>
#import "SndEndianFunctions.h"
#import "Snd.h"
#import "SndView.h"
#ifndef USE_NEXTSTEP_SOUND_IO
#import "sounderror.h"
#endif
#import "SndStreamManager.h"
#import "SndAudioBuffer.h"
#import "SndStreamClient.h"
#import "SndStreamRecorder.h"
#import "SndStreamMixer.h"
#import "SndAudioProcessorChain.h"
#import "SndAudioProcessorReverb.h"
#import "SndAudioProcessor.h"
#import "SndPerformance.h"
#import "SndPlayer.h"
#import "SndAudioFader.h"
#import "SndBreakpoint.h"
#import "SndEnvelope.h"
#import "SndAudioBufferQueue.h"
