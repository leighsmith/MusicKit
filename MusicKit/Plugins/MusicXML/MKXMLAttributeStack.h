//
//  MKXMLAttributeStack.h
//  XML
//
//  Created by Stephen Brandon on Mon Apr 22 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MKXMLAttributeStack : NSObject
{
  NSMutableArray *stack;
}

- (int)currentDivisions;

- (void)addAttributes:(NSDictionary *)attributes;

@end
