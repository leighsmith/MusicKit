/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import "MKXMLSAXHandler.h"
#import "MKXMLScoreTimewiseParser.h"
#import "MKXMLScorePartwiseParser.h"
#ifdef GNUSTEP
#import <Foundation/GSXML.h>
#else
#import <CoreFoundation/CFXMLNode.h> 
#import <CoreFoundation/CFXMLParser.h> 
#endif

@implementation MKXMLSAXHandler

#ifndef GNUSTEP
void *createStructure(CFXMLParserRef parser, 
            CFXMLNodeRef node, void *info) {
    CFStringRef myTypeStr = nil;
    CFStringRef myDataStr = nil;
//    CFStringRef myDataStr2 = nil;
    const CFXMLDocumentInfo *docInfoPtr;
    CFXMLParserContext ct;
    id h;
    BOOL didEntity = FALSE;
    
    CFXMLParserGetContext(parser,&ct);
    h = ct.info;
    
    // Use the dataTypeID to determine what to print.
    switch (CFXMLNodeGetTypeCode(node)) {
        case kCFXMLNodeTypeDocument:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeDocument\n");
//            docInfoPtr = CFXMLNodeGetInfoPtr(node);
//            myDataStr = CFStringCreateWithFormat(NULL,
//                            NULL,
//                            CFSTR("Document URL: %@\n"),
//                            CFSTR("")/*CFURLGetString(docInfoPtr->sourceURL)*/);
                break;
        case kCFXMLNodeTypeElement:
        {
            NSMutableDictionary *dict;
            didEntity = TRUE;
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeElement\n");
            docInfoPtr = CFXMLNodeGetInfoPtr(node);
//            myDataStr = CFStringCreateWithFormat(NULL, NULL,
//                    CFSTR("Element: %@\n"), CFXMLNodeGetString(node));
//            myDataStr2 = CFStringCreateWithFormat(NULL, NULL,
//                    CFSTR("extra: %@\n"), ((CFXMLElementInfo*)docInfoPtr)->attributes);
            dict = [(NSMutableDictionary*)(((CFXMLElementInfo*)docInfoPtr)->attributes) copy];
            [h startElement:(NSString *)CFXMLNodeGetString(node)
                 attributes:dict];
            [dict release];
            break;
        }
        case kCFXMLNodeTypeProcessingInstruction:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeProcessingInstruction\n");
//            myDataStr = CFStringCreateWithFormat(NULL, NULL, 
//                CFSTR("PI: %@\n"), CFXMLNodeGetString(node));
            break;
        case kCFXMLNodeTypeComment:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeComment\n");
//            myDataStr = CFStringCreateWithFormat(NULL, NULL,
//                CFSTR("Comment: %@\n"), CFXMLNodeGetString(node));
            break;
        case kCFXMLNodeTypeText:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeText\n");
//            myDataStr = CFStringCreateWithFormat(NULL, NULL, 
//                CFSTR("Text:%@\n"), CFXMLNodeGetString(node));
            [h characters:(NSString *)CFXMLNodeGetString(node)];
            break;
        case kCFXMLNodeTypeCDATASection:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLDataTypeCDATASection\n");
//            myDataStr = CFStringCreateWithFormat(NULL, NULL, 
//                CFSTR("CDATA: %@\n"), CFXMLNodeGetString(node));
            break;
        case kCFXMLNodeTypeEntityReference:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeEntityReference\n");
//            myDataStr = CFStringCreateWithFormat(NULL, NULL, 
//                CFSTR("Entity reference: %@\n"), CFXMLNodeGetString(node));
            break;
        case kCFXMLNodeTypeDocumentType:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeDocumentType\n");
//            myDataStr = CFStringCreateWithFormat(NULL, NULL, 
//                CFSTR("DTD: %@\n"), CFXMLNodeGetString(node));
            break;
        case kCFXMLNodeTypeWhitespace:
//            myTypeStr = CFSTR("Data Type ID: kCFXMLNodeTypeWhitespace\n");
//            myDataStr = CFStringCreateWithFormat(NULL, NULL, 
//                CFSTR("Whitespace: %@\n"), CFXMLNodeGetString(node));
            break;
        default:
            break;
//            myTypeStr = CFSTR("Data Type ID: UNKNOWN\n");
//            myDataStr = CFSTR("Unknown type.\n");
        }
    
    // Release the strings.
    if (myTypeStr) CFRelease(myTypeStr);
    if (myDataStr) CFRelease(myDataStr);

    // Return the data string for use by the addChild and 
    // endStructure callbacks.
    return [(NSString *)CFXMLNodeGetString(node) copy];
}

void addChild(CFXMLParserRef parser, void *parent, 
              void *child, void *info) {
}

void endStructure(CFXMLParserRef parser, void *xmlType, void *info) {
    CFXMLParserContext ct;
    id h;
    
    CFXMLParserGetContext(parser,&ct);
    h = ct.info;
    
    [h endElement:xmlType];
    
    // Now that the structure and all of its children have been parsed, 
    // we can release the string.
    CFRelease(xmlType);
}

CFDataRef resolveEntity(CFXMLParserRef parser, CFStringRef publicID,
 CFURLRef systemID, void *info) {
    
    printf("---resolveEntity Called---\n");
    return NULL;
}

Boolean handleError(CFXMLParserRef parser, SInt32 error, void *info) {
    char buf[512], *s;

    // Get the error description string from the Parser.
    CFStringRef description = CFXMLParserCopyErrorDescription(parser);
    s = (char *)CFStringGetCStringPtr(description,
                        CFStringGetSystemEncoding());
    
    // If the string pointer is unavailable, do some extra work.
    if (!s) {
        CFStringGetCString(description, buf, 512,
                        CFStringGetSystemEncoding());
    }
    
    CFRelease(description);
    
    // Report the exact location of the error.
    fprintf(stderr, "Parse error (%d) %s on line %d, character %d\n",
                        (int)error, 
                        s, 
                        (int)CFXMLParserGetLineNumber(parser),
                        (int)CFXMLParserGetLocation(parser));
    
    return FALSE;
}

#endif

- (void) dealloc
{
    if (info) {
        [info->infoDict release];
//        [info->score release];
        [info->currentPart release];
        [info->parts release];
        free(info);
    }
    [oStack release];
    [super dealloc];
}

+ (MKScore *) parseData:(NSData*)data intoScore:(MKScore *)s
{
#ifdef GNUSTEP
    GSSAXHandler *h = [MKXMLSAXHandler handler];
    GSXMLParser       *p = [GSXMLParser parserWithSAXHandler: h
                                                    withData: data];
    [h setupWithScore:s];
    if ([p parse])
    {
        return [p score];
    }
    return nil;
    
#else
    MKXMLSAXHandler *h = [MKXMLSAXHandler new];
    // First, set up the parser callbacks.
    CFXMLParserCallBacks callbacks = {
        (CFIndex)                                  0,
        (CFXMLParserCreateXMLStructureCallBack)    createStructure,
        (CFXMLParserAddChildCallBack)              addChild,
        (CFXMLParserEndXMLStructureCallBack)       endStructure,
        (CFXMLParserResolveExternalEntityCallBack) resolveEntity,
        (CFXMLParserHandleErrorCallBack)           handleError
    };
    CFXMLParserContext aContext = {0, h ,NULL,NULL,NULL};
    
    // Create the parser with the option to skip whitespace.
    CFXMLParserRef parser = CFXMLParserCreate(kCFAllocatorDefault, (CFMutableDataRef)data, NULL, 
    kCFXMLParserSkipWhitespace, kCFXMLNodeCurrentVersion, &callbacks, &aContext);
    
    [h setupWithScore:s];
    // Invoke the parser.
    if (!CFXMLParserParse(parser)) {
        printf("parse failed\n");
        [h release];
        return nil;
    }
    [h autorelease];
    return [h score];

#endif
}

+ (MKScore *) parseFile:(NSString *)path intoScore:(MKScore *)s
{
    return [MKXMLSAXHandler parseData:[NSData dataWithContentsOfFile:path] intoScore:s];
}

- (void) startElement: (NSString*)elementName attributes:(NSMutableDictionary*)elementAttributes
{
#if DEBUG
    fprintf(stderr,"Top level received start element name: %s attributes: %s\n",
            [elementName cString],[[elementAttributes description] cString] );
#endif
    if ([elementName isEqualToString:@"score-timewise"]) { //current top-of-stack item
        id obj;
        if (!oStack) oStack = [[NSMutableArray alloc] init];

        obj = [[MKXMLScoreTimewiseParser alloc] initWithStack:oStack parent:self info:info];
        [oStack addObject:obj];
        [obj release];
    }
    else if ([elementName isEqualToString:@"score-partwise"]) {
        id obj;
        if (!oStack) oStack = [[NSMutableArray alloc] init];

        obj = [[MKXMLScorePartwiseParser alloc] initWithStack:oStack parent:self info:info];
        [oStack addObject:obj];
        [obj release];
    }
    else {
#if DEBUG
        printf("top level received start element it does not recognise (%s)\n",[elementName cString]);
#endif
        [[oStack lastObject] startElement:elementName attributes:elementAttributes];
    }
}

- setupWithScore:(MKScore *)s
{
    MKNote *aNote;
    info = calloc(sizeof(MKXMLInfoStruct),1);
    info->infoDict = [NSMutableDictionary new];
    if (s) {
        info->score = [s retain];
    }
    else {
        info->score = [MKScore new];
    }
    info->parts = [NSMutableDictionary new];
    if (![info->score infoNote]) {
        aNote = [MKGetNoteClass() new];
        [info->score setInfoNote:aNote];
        [aNote release];
    }
    return self;
}

- (void) endElement: (NSString*)elementName
{
#if DEBUG
     fprintf(stderr,"end element name: %s\n",[elementName cString]);
#endif
    [[oStack lastObject] endElement:elementName]; // give a chance to clean up
}
- (void) characters: (NSString*)name
{
#if DEBUG
    fprintf(stderr,"     (top level received characters): %s\n",[name cString]);
#endif
    [[oStack lastObject] characters:name];
}

- (void) ignoreWhitespace: (NSString*)ch
{
#if DEBUG
    fprintf(stderr,"ignore whitespace, length %d\n",[ch length]);
#endif
}

- (MKScore *) score
{
    return [[info->score retain] autorelease];
}

@end
