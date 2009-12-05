/*
  $Id$
  Defined In: The MusicKit

  Description:
    This class manages replies from the MusicKit thread back to the AppKit thread.
    
  Original Author: Leigh M. Smith

  Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
/* AppProxy.m created by leigh on Thu 30-Mar-2000 */

#import "_MKAppProxy.h"

@implementation _MKAppProxy

/*
#define MSGTYPE_USER 1

typedef struct _mainThreadUserMsg {
    msg_header_t header;
    id toObject;
    SEL aSelector;
    int argCount;
    id arg1;
    id arg2;
} mainThreadUserMsg;
*/

// The following method handles Port messages received by the App thread. 
- (void) handlePortMessage: (NSPortMessage *) portMessage
{
    NSLog(@"Handling port Message not as a wakeup call");

#if 0
    switch (msg->msg_id) {
    case MSGTYPE_USER:
        sendObjcMsg(myMsg->toObject,myMsg->aSelector,myMsg->argCount,myMsg->arg1, myMsg->arg2);
        break;
    default:
        break;
    }
#endif
}

// From NSConnection experiments
#if 0
+ (void)connectWithPorts:(NSArray *)portArray
{
  NSAutoreleasePool *pool;
  NSConnection *serverConnection;
  _MKAppProxy *serverObject;

  pool = [[NSAutoreleasePool alloc] init];

  serverConnection = [NSConnection
        connectionWithReceivePort:[portArray objectAtIndex:0]
        sendPort:[portArray objectAtIndex:1]];

  serverObject = [[self alloc] init];
  [(id)[serverConnection rootProxy] setServer:serverObject];
  [serverObject release];

  [[NSRunLoop currentRunLoop] run];
  [pool release];
  [NSThread exit];

  return;
}
#endif

@end
