/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *	FILE: GenericDocument.m
 *
 *	AUTHOR: Michael McNabb
 *
 *	DESCRIPTION:
 *		The GenericDocument superclass is Michael McNabb's collection of functions and 
 *		methods which perform standard NeXTSTEP application document behavior.
 *		It handles the user interface for document file opening, closing, and saving.
 *		Actual application-specific loading and saving is relegated to the subclass.
 *
 *		Note that GenericDocument is a subclass of responder, and inserts itself in
 *		the responder chain just after the document's window.  This allows it to
 *		respond to First Responder messages when the window is the key window.
 *
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "GenericDocument.h"

void parsePath(char *path, char *dir, char *name)
     /* Parse out the name and directory given a path */
{
    char *c;
    int dirlen, namelen;
    c = strrchr(path, '/');
    dirlen = (c) ? c-path+1 : 0;
    namelen = strlen(path) - dirlen;
    strncpy(dir,path,dirlen);
    dir[dirlen] = '\0';
    strncpy(name, path+dirlen, namelen);
    name[namelen] = '\0';
}

void getPath(char *path, char *dir, char *name, char *ext)
 /* Construct a path given a file name, directory, and type */
{
	strcpy(path, (strlen(dir)) ? dir : NXHomeDirectory());
	if (path[strlen(path) - 1] != '/')
		strcat(path, "/");
	if (strlen(name)) {
		strcat(path, name);
		if (ext) {
			if (ext[0] != '.')
				strcat(path, ".");
			strcat(path, ext);
		}
	}
}

BOOL fileExists(const char *name)
	/* Return YES if a file exists by the specified name */
{
	FILE *fp;

	if (fp = fopen(name, "r")) {
		fclose(fp);
		return YES;
	} else
		return NO;
}

#if 0
int freeSpace(char *path)
	/* Return the number of bytes free on the disk where the given path is located.
	 * We do this by doing a df into a file in /tmp, then parsing the file.
	 */
{
	FILE *fp;
	int i, space;
	char *buf, *name, *dir;
	NX_MALLOC(buf,char,MAXPATHLEN+64);
	NX_MALLOC(dir,char,MAXPATHLEN+64);
	NX_MALLOC(name,char,MAXPATHLEN+64);
	parsePath(path,dir,name);
	sprintf(buf,"df %s | grep / > /tmp/df.tmp",dir);
	system(buf);
	fp = fopen("/tmp/df.tmp", "r");
	if (fp==NULL) return -1;
	fscanf(fp, "%s %d %d %d", buf, &i, &i, &space);
	fclose(fp);
	NX_FREE(buf);
	NX_FREE(dir);
	NX_FREE(name);
	return space*1024;
}

static BOOL checkSize(int size, char *path)
	/* See if there are at least <size> bytes free on the disk where <path> is located.
	 * Return YES if there are, otherwise warn the user and return NO.
	 */
{
	int space, response;

	/* First see if enough free space exists */
	space = freeSpace(path);
	if (space < 0) return YES;		/* Don't know the free space */
	if (size <= space) return YES;  /* No problem */
	
	/* Better alert the user. */
	response = NXRunAlertPanel ([NXApp appName], 
		"Warning: free space on disk = %d kbytes.\nEstimated file size = %d kbytes.",
		"Proceed", "Cancel Save", NULL, space/1000, size/1000);
	if (response==NX_ALERTALTERNATE) return NO;

	return YES;
}
#endif

/* Global string representing the name of the IB file for the type of document */
const char *docNibFileName = "Document.nib";

/* Global string representing the default document file extension. */
const char *docFileExtension = NULL;

/* Global integer used to determine the names of UNTITLED documents. */
int numDocs = 0;

int offset = 0;
id keyDocument = nil;
id documents = nil;

@implementation GenericDocument

/* ----------------------  Class Methods  ---------------------- */

+ setNibFileName:(const char *)nibFileName
	/* Reset the name of the IB file used for this document class */
{
	docNibFileName = nibFileName;
	return self;
}

+ setDocFileExtension:(const char *)extension
	/* Set the default extension used for these documents. */
{
	docFileExtension = extension;
	return self;
}


/* ----------------------  Initialization Methods  ---------------------- */

- setDefaults
	/* The subclass puts any new-document initialization here */
{
	char title[32];
	sprintf(title,"UNTITLED-%d",++numDocs);
	[self setFilePath:title];
	delegate = NXApp;
	return self;
}

- initFromPath:(char *)path
    /* Initialize a newly allocated document from a saved document on disk. */
{
	id newSelf = self;
 	[super init];

	if (!documents) documents = [[List allocFromZone:[NXApp zone]] initCount:2];
	
	if (path && *path) {
		char *ext = strrchr(path,'.');
		if (ext && *ext && !strcmp(ext+1, docFileExtension))
			newSelf = [self loadDocumentFromPath:path];
		if (!newSelf) {
			NXRunAlertPanel([NXApp appName], "Cannot open %s", NULL, NULL, NULL, path);
			[NXApp delayedFree:self];
			return nil;
		}
		[newSelf setFilePath:path];
	}
	else
		[self setDefaults];

	[NXApp loadNibSection:docNibFileName owner:newSelf withNames:NO
		fromZone:[NXApp zone]];
	
	[documents addObjectIfAbsent:newSelf];
	if ([delegate respondsTo:@selector(documentDidInit:)])
		[delegate documentDidInit:newSelf];
	if (newSelf != self) {
		[NXApp delayedFree:self];
		self = newSelf;
	}
    return newSelf;
}

- awakeFromNib
{
	NXRect r;
	[window setDelegate:self];
	[window setFreeWhenClosed:NO];
	[window getFrame:&r];
	[window moveTo:r.origin.x+(offset*20.0) :r.origin.y-(offset*20.0)];
	if (++offset == 6) offset = 0;
    if (filePath) [window setTitleAsFilename:filePath];
	[window setDocEdited:!filePath || (*filePath == '\0')];
	return self;
}
	
- init
	/* Initialize a newly allocated empty document, and set the title to "UNTITLED-n" */
{
	return [self initFromPath:NULL];
}

/* ----------------------  Close and Free Methods  ---------------------- */

- free
	/* Free the memory storing the file name, dir, and path, then free self. */
{
	NXZoneFree([self zone],filePath);
	NXZoneFree([self zone],fileName);
	NXZoneFree([self zone],fileDir);
	[NXApp delayedFree:window];		/* Window's freeWhenClosed must == NO!! */
	return [super free];
}


/* ------------------  The document's file path ------------------ */

- setFilePath:(char *)aPath
	/* Sets the file path of the document to be a copy of aPath. Returns self. */
{
	if (!filePath) {
	    filePath = NXZoneMalloc([self zone],sizeof(char)*(MAXPATHLEN+1));
    	fileName = NXZoneMalloc([self zone],sizeof(char)*(MAXPATHLEN+1));
    	fileDir =  NXZoneMalloc([self zone],sizeof(char)*(MAXPATHLEN+1));
		*filePath = '\0';
 		*fileName = '\0';
   	 	*fileDir = '\0';
	}
	strncpy(filePath,aPath,MAXPATHLEN+1);
	parsePath(filePath, fileDir, fileName);
    [window setTitleAsFilename:filePath];
	return self;
}

- (char *)fileName
{
    return fileName;
}

- (char *)fileDir
{
    return fileDir;
}

- (char *)filePath
{
    return filePath;
}

/* ------------------  Methods for opening files from the disk  ------------------ */

+ openFromZone:(NXZone *)aZone
	/* Class method which prompts for a document file and open it. */
{
	char *path = malloc(sizeof(char)*(MAXPATHLEN+1));
	const char *const * files;
	const char *types[2];
	char *currentPath = [keyDocument fileDir];
	id openPanel = [OpenPanel new];

	[openPanel allowMultipleFiles:YES];
	types[0] = docFileExtension;
	types[1] = NULL;

	if (currentPath && *currentPath && strncmp(currentPath,"UNTITLED",8))
		strcpy(path,currentPath);
	else {
		const char *s = NXReadDefault([NXApp appName], "DocDirectory");
		if (s) strcpy(path, s);
	}
	if (path && *path && path[strlen(path) - 1] != '/')
		sprintf(&path[strlen(path)], "/");
	if ([openPanel runModalForDirectory:(const char *)path
		 file:"" types:types]) {
		int n;
		id newDoc = nil, oldDoc = nil;
		NXRect r;
		const NXScreen *s = NULL;
		strcpy(path,[openPanel directory]);
		sprintf(&path[strlen(path)], "/");
		n = strlen(path);
		files = [openPanel filenames];
		while (*files) {
			sprintf(&path[n], *files);
			newDoc = [[self allocFromZone:aZone] initFromPath:(char *)path];
			if (oldDoc) {
				/* Offset this document from the previous one. */
				[[oldDoc window] getFrame:&r];
				if (!s) s = [[oldDoc window] screen];
				if ((s->screenBounds.size.width-(r.origin.x+r.size.width) >= 20.0) &&
					(r.origin.y >= 20.0)) {
					r.origin.x += 20.0;
					r.origin.y -= 20.0;
					[[newDoc window] moveTo:r.origin.x :r.origin.y];
				}
			}
			[[newDoc window] orderFront:nil];
			oldDoc = newDoc;
			files++;
		}
		[[newDoc window] makeKeyWindow];
	}
	return self;
}

+ open
{
	[self openFromZone:[NXApp zone]];
	return self;
}

/* ------------------  Methods for saving files to disk  ------------------ */

- save:sender
    /* Save the document, querying for a name if necessary. */
{
    if (![window isDocEdited]) return self;
    if (strncmp(fileName,"UNTITLED",8)) {
		getPath(filePath,fileDir,fileName, NULL);
      	[self saveDocumentToPath:filePath];
    	[window setDocEdited:NO];
	}
    else
      if ([self saveAs:sender]) [window setDocEdited:NO];

    return self;
}

- saveAs:sender
    /* Save the document, querying for a name. */
{
	id savePanel = [SavePanel new];
	char *ext = strrchr(fileName,'.');
	char *name;
	BOOL success;
	
    if (!strncmp(fileName,"UNTITLED",8)) {
		const char *s = NXReadDefault([NXApp appName], "DocDirectory");
		if (s) {
			if (!fileExists(s)) mkdir(s, 0755);
			sprintf(fileDir, fileExists(s) ? s : NXHomeDirectory());
		}
	}

	if (ext!=NULL) {
		/* If the current file name has an extension, strip it off */
		name = NXZoneMalloc([self zone],sizeof(char)*(ext-fileName+1));
		strncpy(name,fileName,ext-fileName);
		name[ext-fileName] = '\0';
		ext = ext+1;
	}
	else name = fileName;

	ext = (docFileExtension) ? docFileExtension : (ext ? ext : NULL);

	if (ext) [savePanel setRequiredFileType:ext];
    if (![savePanel runModalForDirectory:fileDir file:name]) return nil;
	
    success = [self saveDocumentToPath:(char *)[savePanel filename]];
	
	if (success) {
		strcpy(filePath,[savePanel filename]);
    	parsePath(filePath, fileDir, fileName);
    	[window setTitleAsFilename:filePath];
		[window setDocEdited:NO];
	}
	if (name != fileName) NXZoneFree([self zone],name);
    return (success) ? self : nil;
}

- saveTo:sender
    /* Save the document, querying for a name. Keep previous file name. */
{
    char *oldFilePath = NXZoneMalloc([self zone],sizeof(char)*(strlen(filePath)+1));
	strcpy(oldFilePath,filePath);
	[self saveAs:sender];
	[self setFilePath:oldFilePath];
	NXZoneFree([self zone],oldFilePath);
    return self;
}

- revertToSaved:sender
    /* Replace the current document with a freshly unarchived version. */
{ 
    if (![window isDocEdited] ||
		(NXRunAlertPanel ([NXApp name], "Do you want to revert changes to %s?", 
			"Revert", "Cancel", NULL, fileName) != 
	 		NX_ALERTDEFAULT))
		return self;

	if ([self loadDocumentFromPath:filePath])
    	[window setDocEdited:NO];
	else
		NXRunAlertPanel([NXApp appName], "Cannot open %s", NULL, NULL, NULL, filePath);
    return self;
}


/* ------------------  Subclass Responsibility methods  ------------------ */

- loadDocumentFromPath:(char *)path
	/* Subclass implements this method to load a document from a disk file.
	 * Returns YES if successful, otherwise NO.
	 */
{
	[self subclassResponsibility:_cmd];
	return self;
}

- (BOOL)saveDocumentToPath:(char *)path
	/* Subclass implements this method to save a document to a disk file.
	 * Returns YES if successful, otherwise NO.
	 */
{
	[self subclassResponsibility:_cmd];
	return NO;
}


/* ----------------------  Window Delegate Methods  ---------------------- */

- windowDidBecomeKey:sender
{
	keyDocument = self;
	if ([delegate respondsTo:@selector(documentDidBecomeKey:)])
		[delegate documentDidBecomeKey:self];
	return self;
}

- windowDidResignKey:sender
{
	if ([delegate respondsTo:@selector(documentDidResignKey:)])
		[delegate documentDidResignKey:self];
	return self;
}

- windowWillClose:sender
    /* Query the user before closing window if document was modified. */
{
    if ([self okToClose]) {
		if ([delegate respondsTo:@selector(documentWillClose:)])
			[delegate documentWillClose:self];
		[documents removeObject:self];
		if (self == keyDocument) keyDocument = nil;
		[NXApp delayedFree:self];
		return self;
	}
    return nil;
}


/* ----------------------  Other Methods  ---------------------- */

- window
{
	return window;
}

- show
{
	[window makeKeyAndOrderFront:nil];
	NXPing();
	return self;
}

- (BOOL)isReadOnly
{
	return readOnly;
}

- setEdited
	/* A convenience method which opens the little X in the window's close button */
{
    [window setDocEdited:YES];
    return self;
}

- (BOOL)okToClose
    /* Query the user before closing the window if the document has been modified. */
{
    int response = 0;

    if ([window isDocEdited]) {
		response = NXRunAlertPanel([NXApp appName], "Save changes to %s?", "Save", 
				   "Don't Save", "Cancel", fileName);
		if (response == NX_ALERTDEFAULT) [self save:self];
		return (response != NX_ALERTOTHER);
    }

    return YES;
}
	
- awake
{
	[super awake];
	delegate = NXApp;
	return self;
}

@end
