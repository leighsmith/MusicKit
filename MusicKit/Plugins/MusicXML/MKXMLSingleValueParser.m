/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLSingleValueParser.h"

@implementation MKXMLSingleValueParser

id MK_XML_NullString = @"_MKXMLNULL_";

- (void) dealloc
{
    [content release];
    [name release];
    [super dealloc];
}

- (id) initWithStack:(NSMutableArray *)newStack parent:(id)newParent name:(NSString *)newName info:(void *)inf
{
    id ret = [super initWithStack:newStack parent:newParent info:(void *)inf];
    if (ret) name = [newName retain]; // in general these are static strings
    return ret;
}

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
//    if (elementAttributes && elementName) {
//        [self setAttributes:elementAttributes forKey:elementName];
//    }
    [attributesDict release];
    attributesDict = [elementAttributes retain];
}

- (void) characters: (NSString*)data
{
    if (!content) {
        content = [[NSMutableString stringWithString:data] retain];
    }
    else {
        [content appendString:data];
    }
}

- (NSString*) stringByTrimmingSpaces
{
    unsigned            length = [content length];
    /* static */        SEL  caiSel = @selector(characterAtIndex:);
    if (length > 0)
    {
        unsigned  start = 0;
        unsigned  end = length;
        unichar   (*caiImp)(NSString*, SEL, unsigned int);

        caiImp = (unichar (*)())[content methodForSelector: caiSel];
        while (start < length && isspace((*caiImp)(content, caiSel, start)))
        {
            start++;
        }
        while (end > start)
        {
            if (!isspace((*caiImp)(content, caiSel, end - 1)))
            {
                break;
            }
            end--;
        }
        if (start > 0 || end < length)
        {
            if (start < end)
            {
#ifdef GNUSTEP
                return [content substringFromRange:
                    NSMakeRange(start, end - start)];
#else
                return [content substringWithRange:
                    NSMakeRange(start, end - start)];
#endif
            }
            else
            {
                return MK_XML_NullString;
            }
        }
    }
    else return MK_XML_NullString;
    return content;
}


- (NSString *)content
{
    // trim white space and newlines before returning
    return [self stringByTrimmingSpaces];
}

- (void) endElement: (NSString*)elementName
{
    // Should really check to see if it's US that is being closed...
    NSString *c = [self content];
#if DEBUG
    fprintf(stderr,"end Single Value element name: %s. content was %s\n",[elementName cString],[c cString]);
#endif
    // these 2 methods are used to send the parsed data back up to the parent.
    // Every MKXMLParser subclass inherits the ability to save data passed in
    // by setChildData:forKey:, but this necessarily discards any attributes that
    // were part of the tag. In the more complicated case of attributes, parent
    // entities will want to implement the second form which passes in the attributes
    // dict, or nil if there were none.
    [parent setChildData:c forKey:name];
    [parent setChildData:c attributes:attributesDict forKey:name];
    [self remove];
}

@end
