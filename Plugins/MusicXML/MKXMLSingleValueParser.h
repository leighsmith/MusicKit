/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLParser.h"
@class NSString;

@interface MKXMLSingleValueParser : MKXMLParser
{
    NSMutableString *content;
    NSString *name;
}

- (id) initWithStack:(NSMutableArray *)stack parent:(id)parent name:(NSString *)name info:(void *)info;


@end
