////////////////////////////////////////////////////////////////////////////////
//
// playsndfaders - a simple SndKit streaming architecture exerciser / sound
// player with added fader control toys
//
// Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
//                  substantially based on "playsnd" example by SKoT McDonald
//                  skot@tomandandy.com
// September 2001
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>
#import <unistd.h>

// Version info
#define V_MAJ  1
#define V_MIN  0
#define V_TINY 2

static int iReturnCode = 0;

////////////////////////////////////////////////////////////////////////////////
// PrintError
////////////////////////////////////////////////////////////////////////////////

void PrintError(char* msg, int iPossibleReturnCode)
{
   fprintf(stderr,"%s\n",msg); 
   if (iReturnCode == 0)
      iReturnCode = iPossibleReturnCode;
}

////////////////////////////////////////////////////////////////////////////////
// ShowHelp
////////////////////////////////////////////////////////////////////////////////

void ShowHelp(void)
{
  printf("Options:\n");
  printf(" -f N  fade-in from silence over first N seconds\n");
  printf(" -F N  fade-out to silence over last N seconds\n");
  printf(" -A N  set constant amplitude of sound to N (usually 0 to 1)\n");
  printf(" -B N  set constant balance of sound to N (-1.0 to 1.0)\n");
  printf(" -z N  zig-zag the balance from left to right and back, N times over the duration of the sound, starting in the left channel\n");
  printf(" -r    use reverb (freeverb) module\n");
  printf(" -O N  offset playback time by N seconds (can be non-integral)\n");
//  printf(" -o N  offset playback time by N samples\n");
//  printf(" -E N  playback duration, in seconds\n");
  printf(" -d N  playback duration, in samples\n");
  printf(" -b N  playback start point, in samples\n");
  printf(" -v    show author/version info\n");
  printf(" -h    show this help\n");
  printf(" -t    turn on time information output\n");
}
 
////////////////////////////////////////////////////////////////////////////////
// main
////////////////////////////////////////////////////////////////////////////////

int main (int argc, const char * argv[])
{    
    BOOL   bTimeOutputFlag    = FALSE;
    BOOL   useReverb          = FALSE;
    long   startTimeInSamples = 0;
    double durationInSamples  = -1;
    float  timeOffset         = 0.0f;
    int    i = 1;
    const char  *soundFileName      = NULL;
    // fader initialisation
    double fadeInTime         = 0;
    double fadeOutTime        = 0;
    float  amplitude          = 1;
    float  balance            = 0;
    int    numzigzags         = 0;
    
    if (argc == 1) {
      printf("Use: playsndfaders [options] <soundfile>\nType playsnd -h for more help.\n");
      return 0;
    }
    
    for (i = 1; i < argc; i++) {
      if (argv[i][0] == '-') {
        switch (argv[i][1]) {
        case 'O':
          i++;
          if (i < argc) timeOffset = atof(argv[i]);
          else          PrintError("No time offset in seonds value given after option -O",-1);
          break;
        case 't': bTimeOutputFlag = TRUE;                       break;
        case 'r': useReverb       = TRUE;                       break;
        case 'v': printf("playsndfaders %i.%i.%i  skot@tomandandy.com/stephen@brandonitconsulting.co.uk  Sep 2001\n",V_MAJ,V_MIN,V_TINY); break;
        case 'h': ShowHelp(); break;
        case 'd': 
          i++;
          if (i < argc) durationInSamples = atoi(argv[i]);
          else          PrintError("No end time in samples given after option -e",-1);
          break;
        case 'b':
          i++;
          if (i < argc) startTimeInSamples = atoi(argv[i]);
          else          PrintError("No start time in samples given after option -b",-1);
          break;
        case 'f':
          i++;
          if (i < argc) fadeInTime = atof(argv[i]);
          else          PrintError("No fade-in time in seconds given after option -f",-1);
          break;
        case 'F':
          i++;
          if (i < argc) fadeOutTime = atof(argv[i]);
          else          PrintError("No fade-out time in seconds given after option -F",-1);
          break;
        case 'A':
          i++;
          if (i < argc) amplitude = atof(argv[i]);
          else          PrintError("No amplitude scaler given after option -A",-1);
          break;
        case 'B':
          i++;
          if (i < argc) balance = atof(argv[i]);
          else          PrintError("No balance given after option -B",-1);
          break;
        case 'z':
          i++;
          if (i < argc) numzigzags = atoi(argv[i]);
          else          PrintError("No number of zigzags given after option -z",-1);
          break;

        default: fprintf(stderr, "Ignoring unrecognized option -%c\n",argv[i][1]);
        }
      }
      else if (soundFileName == NULL)
        soundFileName = argv[i];
      else {
        printf("Regrettably, playsnd doesn't support playing multiple files yet (no tech reason why not...).\n");
        printf("  This file will not be played: %s\n",argv[i]);
      }
    }
    if (soundFileName == NULL)
      PrintError("No soundfile name given", -2);
 
    // Reason why we finally exit here instead of eariler - allow all error msgs to 
    // be displayed before exit
    if (iReturnCode != 0)  
      return iReturnCode;
    
    // Finally: do the actual sound playing!  
    else  
    {
      NSAutoreleasePool *pool     = [NSAutoreleasePool new];
      Snd               *s        = [Snd new]; 
      NSString          *filename = nil, *extension = nil;
      NSFileManager     *fm       = [NSFileManager defaultManager];
      BOOL               bFileExists = FALSE, bIsDir = FALSE; 
    
      filename  = [fm stringWithFileSystemRepresentation:soundFileName
                                                  length:strlen(soundFileName)];
      extension = [filename pathExtension];
      
      bFileExists = [fm fileExistsAtPath: filename isDirectory: &bIsDir];      
      if (!bFileExists || bIsDir) {
        NSArray *ext = [Snd soundFileExtensions];
        int i, c = [ext count];
        
        for (i = 0; i < c; i++) {
          NSString *temp = [filename stringByAppendingPathExtension: [ext objectAtIndex: i]];
          if ([fm fileExistsAtPath: temp]) {
            bFileExists = TRUE;
            filename = temp;
            break;
          }
        } 
      }

      if (![fm fileExistsAtPath: filename]) {
        PrintError("Can't find sound file",-2);
      }
      else {
        int waitCount = 0;
        int maxWait;
        SndPlayer  *player = [SndPlayer defaultSndPlayer];
        SndStreamManager *manager;
        SndStreamMixer *mixer;
        SndAudioProcessorChain *pchain;
        SndAudioFader *fader;

        [s readSoundfile: filename];

        /* It's best to do all this setting up of the faders before telling the
         * snd to play, since there's a chance that buffers might start to be
         * filled and played before the faders are set up if they are done
         * afterwards.
         */
        manager = [SndStreamManager defaultStreamManager];
        mixer = [manager mixer];
        pchain = [mixer audioProcessorChain];
        fader = [pchain postFader];

        if (amplitude != 1) {
          [fader setAmp:amplitude atTime:0];
        }
        if (balance != 0) {
          [fader setBalance:balance atTime:0];
        }
        if (fadeInTime > 0) {
          [fader rampAmpFrom:0 to:1 startTime:0 endTime:fadeInTime];
        }
        if (fadeOutTime > 0) {
          [fader rampAmpFrom:1 to:0 startTime:[s duration]-fadeOutTime endTime:[s duration]];
        }
        if (numzigzags) {
          double dur = [s duration] / numzigzags;
          for (i = 0 ; i < numzigzags ; i++) {
            [fader rampBalanceFrom:-1 to:1 startTime:i*dur endTime:(i+0.5)*dur];
            [fader rampBalanceFrom:1 to:-1 startTime:(i+0.5)*dur endTime:(i+1)*dur];
          }
        }

        maxWait = [s duration] + 5 + timeOffset;
        [player setRemainConnectedToManager: FALSE];

        /* the following statement evaluates to nothing if snds don't need byte
         * swapping on the current architecture (ie big endian like PPC). Still,
         * always remember to put it in to preserve platform independence (eg for
         * folks on Win32/Intel or Linux/Intel).
         */
        [s swapSndToHost];

        if (useReverb) {
            [pchain addAudioProcessor:[[[SndAudioProcessorReverb alloc] init] autorelease]];
        }
        
        [s playInFuture: timeOffset beginSample: startTimeInSamples sampleCount: durationInSamples];

        if (bTimeOutputFlag) printf("Sound duration: %.3f\n",[s duration]);

        // wait for manager to go active... man, this is dodgey and should be fixed!!!!
        while (![[SndStreamManager defaultStreamManager] isActive] && waitCount < maxWait) {
            sleep(1);
            waitCount++;
            if (bTimeOutputFlag)  printf("Time: %i\n",waitCount);
        }
        // Wait for stream manager to go inactive, signalling the sound has finished playing
        while ([[SndStreamManager defaultStreamManager] isActive] && waitCount < maxWait) {
          sleep(1);
          if (bTimeOutputFlag)  printf("Time: %i\n",i+1);
          waitCount++;
        }
        if (waitCount >= maxWait) {
          fprintf(stderr,"Aborting wait for stream manager shutdown - taking too long.\n");
          fprintf(stderr,"(snd dur:%.3f, maxwait:%i)\n",[s duration],maxWait);
        }
      }
      [pool release];
    }
    return iReturnCode;
}

////////////////////////////////////////////////////////////////////////////////
