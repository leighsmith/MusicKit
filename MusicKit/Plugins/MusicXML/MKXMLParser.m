/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLParser.h"
#import "MKXMLSingleValueParser.h"
#import <MusicKit/MKNote.h>

@implementation MKXMLParser

- (void) dealloc
{
    [dict release];
    [attributesDict release];
    // we don't release stack or parent since we do not own them
    [super dealloc];
}

/* some utilities */
+ (MKNote *)noteWithParametersFromStringArray:(NSArray*)a withBaseName:(NSString *)base
{
    MKNote *n = [[MKNote alloc] init];
    int count = [a count];
    int i;
    for (i = 0 ; i < count ; i++) {
        NSString *param = [base stringByAppendingFormat:@"%d",i];
        [n setPar:[MKNote parTagForName:param] toString:[a objectAtIndex:i]];
    }
    return [n autorelease];
}

/******************/

- (void) passElementName:(NSString *)elementName
       elementAttributes:(NSMutableDictionary *)elementAttributes
          toChildOfClass:(NSString*)c
{
    id obj = [[NSClassFromString(c) alloc] initWithStack:stack
                                                  parent:self
                                                    info:(void *)info];
    [stack addObject:obj];
    [obj startElement:elementName attributes:elementAttributes];
    [obj release];
}

- (BOOL) checkForSingleValues: (NSArray *) a
                  elementName: (NSString*) en
            elementAttributes: (NSMutableDictionary *) ea
{
    int i;
    int c = [a count];
    if (!c) return FALSE;
    if (!en) return FALSE;
    for (i = 0 ; i < c ; i++) {
        if ([[a objectAtIndex:i] isEqualToString:en]) {
            id obj = [[MKXMLSingleValueParser alloc] initWithStack:stack
                                                            parent:self
                                                              name:en
                                                              info:info];
            [stack addObject:obj];
            [obj startElement:en attributes:ea];
            [obj release];
            return TRUE;
        }
    }
    return FALSE;
}


- (id)initWithStack:(NSMutableArray *)oStack parent:(id)newParent info:(void *)inf
{
    id obj = [super init];
    if (!obj) return nil;
    stack = oStack;
    parent = newParent;
    info = inf;
    return obj;
}

- (void) setChildData:(id)data forKey:(id)key
{
    id oldObj;
    if (data) {
        if (!dict) dict = [[NSMutableDictionary alloc] init];
        if (!(oldObj = [dict objectForKey:key])) {
            [dict setObject:data forKey:key];
        }
        else {
            if ([oldObj isKindOfClass:[NSArray class]]) {
                [oldObj addObject:data];
#if DEBUG
                NSLog(@"added value for dict: %p for self %p and key %@",dict,self,key);
#endif
            }
            else {
                [dict setObject:[NSMutableArray arrayWithObjects:oldObj,data,nil]
                         forKey:key];
#if DEBUG
                NSLog(@"new value for dict: %@ for self %@ and key %@",dict,self,key);
#endif
            }
        }
    }
}

- (void) setAttributes:(id)elementAttributes forKey:(id)elementName
{
    if (!attributesDict) {
        attributesDict = [[NSMutableDictionary alloc] init];
    }
    if (elementAttributes && elementName) {
        [attributesDict setObject:elementAttributes forKey:elementName];
    }
}

- (NSMutableDictionary*) childData
{
    return [[dict retain] autorelease];
}

- (void)remove
{
    [stack removeObjectAtIndex:[stack count]-1]; // remove ourselves
}

//utility functions which can help to create a hierarchy of dicts and arrays
- (NSMutableDictionary *) dictForKey:(NSString*)k
{
    id d;
    if (!dict) {
        dict = [NSMutableDictionary new];
    }
    if (!(d = [dict objectForKey:k])) {
        d = [NSMutableDictionary new];
        [dict setObject:d forKey:k];
        [d autorelease];
    }
    return d;
}

- (NSMutableArray *) arrayFromDict:(id)md forKey:(NSString*)k
{
    id ma;
    if (!(ma = [md objectForKey:k])) {
        ma = [NSMutableArray new];
        [md setObject:ma forKey:k];
        [ma autorelease];
    }
    return ma;
}


/**************************************
 * SUBCLASS RESPONSIBILITIES
 */

- (void) endElement: (NSString*)elementName
{
}

- (void) startElement: (NSString*)elementName
           attributes:(NSMutableDictionary*)elementAttributes
{
}

- (void) characters: (NSString*)name
{
}

- (void) setChildData:(id)c attributes:(id)a forKey:(id)k
{
}

@end
