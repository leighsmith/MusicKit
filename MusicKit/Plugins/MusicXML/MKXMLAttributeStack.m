//
//  MKXMLAttributeStack.m
//  XML
//
//  Created by Stephen Brandon on Mon Apr 22 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import "MKXMLAttributeStack.h"


@implementation MKXMLAttributeStack

- (void) dealloc
{
    [stack release];
    [super dealloc];
}

- (int)currentDivisions
{
    int count;
    id div;
    if (!stack) return 0;
    count = [stack count];
    while (count--) {
        if ((div = [[stack objectAtIndex:count] objectForKey:@"divisions"])) {
            return [div intValue];
        }
    }
    return 0;
}

- (void)addAttributes:(NSDictionary *)attributes
{
    if (!attributes) {
        return;
    }
    if (!stack) {
        stack = [NSMutableArray new];
    }
    [stack addObject:attributes];
}

- (NSString *) description
{
    if (stack) return [stack description];
    return @"";
}

@end
