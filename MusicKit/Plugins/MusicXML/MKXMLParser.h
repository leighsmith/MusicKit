/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "MKXMLSAXHandler.h"

//#import <Foundation/GSXML.h>
@class NSMutableArray;
@class NSString;
@class MKNote;

extern id MK_XML_NullString;

@interface MKXMLParser : NSObject /*GSSAXHandler*/
{
    //reference to stack held at top level.
    NSMutableArray             *stack;
    NSMutableDictionary        *dict;
    NSMutableDictionary        *attributesDict; // not often used except by sound and singlevalue
    MKXMLParser                *parent; // the object to send our data dict to when the tag is closed
    MKXMLInfoStruct            *info; /* simply passed around */
}

+ (MKNote *)noteWithParametersFromStringArray:(NSArray*)a
                                 withBaseName:(NSString *)base;

- (void) passElementName:      (NSString *) elementName
       elementAttributes:      (NSMutableDictionary *) elementAttributes
          toChildOfClass:      (NSString*) c;

- (BOOL) checkForSingleValues: (NSArray *) a
                  elementName: (NSString*) en
            elementAttributes: (NSMutableDictionary *) ea;

- (id)   initWithStack:        (NSMutableArray *) stack
                parent:        (id) parent
                  info:        (void *) inf;

- (void) setChildData:         (id) data
               forKey:         (id) key;

- (void) setAttributes:        (id) data
                forKey:        (id) elementName;

- (NSMutableDictionary*) childData;

- (void)remove;

//utility functions which can help to create a hierarchy of dicts and arrays
- (NSMutableDictionary *) dictForKey:    (NSString*)k;

- (NSMutableArray *)   arrayFromDict:    (id) md
                              forKey:    (NSString*) k;

// general methods corresponding to GSXML (GSSAXHandler)
// methods
- (void) endElement:           (NSString*) elementName;

- (void) startElement:         (NSString*) elementName
           attributes:         (NSMutableDictionary*) elementAttributes;

- (void) characters:           (NSString*) name;

      //other stubs:
- (void) setChildData:         (id) c
           attributes:         (id) a
               forKey:         (id) k;

@end
