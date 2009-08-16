
#import "ScoreInspector.h"

@implementation ScoreInspector

static id scoreInspector = nil;

+ new
{
    if (scoreInspector == nil) {
        char path[MAXPATHLEN+1];
        NSBundle *bundle;
	bundle = [NSBundle bundleForClass:self];
        self = scoreInspector = [super new];

        if ([bundle getPath:path 
                forResource:"ScoreInspector"
                ofType:"nib"]) {
            [NXApp loadNibFile:path owner:scoreInspector];
        } else {
            scoreInspector = nil;
        }
    }
    return scoreInspector;
}

- doit:(const char *)cmd1
{
    char cmd[MAXPATHLEN+strlen(cmd1)+10];
    unsigned  cnt = [self selectionCount];
    char *cpc = cmd + strlen(cmd1);
    strcpy(cmd,cmd1);
    if (cnt>0) {
	int i;
	char paths[cnt*(MAXPATHLEN+1)];
	char *cpp = paths;
	[self selectionPathsInto:(char *)paths separator:'\0'];
	for (i=0; i<cnt; i++) {
	    strcpy(cpc,cpp);
	    cpp += strlen(cpp) + 1;
	    strcat(cpc," &");
	    fprintf(stderr,"%s\n",cmd);
	    system(cmd);
	}
    }
    return self;
}

- openInEdit:sender
{
    return [self doit:"openfile "];
}

- play:sender
{
    return [self doit:"playscore -p "];
}


@end
