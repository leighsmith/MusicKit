#import <Foundation/NSObject.h>
#import <libc.h>

@interface _MKList:NSObject

{
	id *theList;
}
-(void)init;
-(void)dealloc;
-(id)objectAtIndex:(int)indx;
-(id *)baseAddress;

@end
