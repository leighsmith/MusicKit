#ifndef __MK_GenericDocument_H___
#define __MK_GenericDocument_H___
#import <appkit/appkit.h>
#import "GenericDocument.h"

@interface GenericDocument:Responder
{
    id	window;					/* The document's window */
	char *filePath;		     	/* The document's complete file path */
    char *fileName;		     	/* The document's file name */
    char *fileDir;		     	/* The document's file directory */
	id delegate;				/* Object which receives delegate messages */
	BOOL readOnly;				/* Whether the object's parameters can be reset */
}

/* ----------------------  Class Initialization Methods  ---------------------- */

+ setNibFileName:(const char *)nibFileName;
+ setDocFileExtension:(const char *)extension;

/* ----------------------  Initialization Methods  ---------------------- */

- setDefaults;
- initFromPath:(char *)path;

/* ------------------  The document's file path ------------------ */

- setFilePath:(char *)aPath;
- (char *)fileName;
- (char *)fileDir;
- (char *)filePath;

/* ------------------  Methods for opening files from the disk  ------------------ */

+ openFromZone:(NXZone *)aZone;

/* ------------------  Methods for saving files to disk  ------------------ */

- save:sender;
- saveAs:sender;
- saveTo:sender;
- revertToSaved:sender;

/* ------------------  Subclass Responsibility Methods  ------------------ */

- loadDocumentFromPath:(char *)path;
- (BOOL)saveDocumentToPath:(char *)path;

/* ----------------------  Other Methods  ---------------------- */

- window;
- show;
- (BOOL)okToClose;
- setEdited;
- (BOOL)isReadOnly;

@end

@interface GenericDocumentDelegate:Object

- documentDidInit:sender;
- documentDidBecomeKey:sender;
- documentDidResignKey:sender;
- documentWillClose:sender;

@end

extern id keyDocument;		/* The document whose window was last made key */
extern id documents;		/* List of all currently existing documents */
extern BOOL fileExists(const char *name);

#endif
