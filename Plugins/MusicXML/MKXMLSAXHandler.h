/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@class MKScore;

typedef struct {
    NSMutableDictionary *  	infoDict;
    NSString *             	currentPart;
    MKScore *			score;
    NSMutableDictionary *       parts;
    double			startOfNextNote; // only accurate when inside part tags
    double			startOfLastNote;
    void *                	reserved2;
    void *                 	reserved3;
} MKXMLInfoStruct;


#ifdef GNUSTEP
#import <Foundation/GSXML.h>

@interface MKXMLSAXHandler : GSSAXHandler
#else
@interface MKXMLSAXHandler : NSObject
#endif
{
// stacks on the mill (more on still)
    NSMutableArray *oStack;
    MKXMLInfoStruct *info;
}

+ (MKScore *) parseData:(NSData *)data intoScore:(MKScore*)s;
+ (MKScore *) parseFile:(NSString *)path intoScore:(MKScore*)s;
- (MKScore *) score;
- setupWithScore:(MKScore *)s;

@end
