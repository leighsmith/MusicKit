
#import <Foundation/Foundation.h>

int computeNotes(void);

int main (int argc, const char *argv[])
{
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

   computeNotes();
   [pool release];
   exit(0);       // insure the process exit status is 0
   return 0;      // ...and make main fit the ANSI spec.
}
