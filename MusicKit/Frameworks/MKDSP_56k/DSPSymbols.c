/* Made from Andy Moorer's vsymtab.c file by J.O. Smith, May 13, 1990 */
/* History:
   2/26/93/DAJ - Added support for multiple symbol tables.
   */

/* -------------------------------------------------------------------------
|| VSYMSTO, VSYMGET - Simple-minded symbol table routines
------------------------------------------------------------------------- */
#ifdef SHLIB
#include "shlib.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>		/* strcmp, strlen, strcpy */
#include <DSPSymbols.h>

#define	TRUE	1
#define	FALSE	0

/* -------------------------------------------------------------------------
|| VENTRY, SYMTAB - Structure definitions for symbol tables
------------------------------------------------------------------------- */

#define vnbuckets 2003	/* Convenient prime */

/* --------- Symbol table Entry --------------- */

struct ventry {
    struct ventry *next_ventry;
    struct symtab *entry_symtab;	/* We belong to this one */
    char *symbol;			/* name */
    DSPSymbol *value;			/* symbol */
    long type;				/* arbitrary integer type code */
};

/* ------------ A symbol table itself -------------------- */

struct symtab {
    struct ventry *buckets[vnbuckets];
#if 0 
    struct symtab *parent_symtab, *offspring_symtab, *sibling_symtab;
    struct ventry *name;	/* Name of symbol table, if any */
    int StaticLevel;		/* Scope level, root = 0 */
#endif
    int NSyms;			/* Number of symbols */
};


/* -------------------------------------------------------------------------
|| mycalloc - override broken libsys version
------------------------------------------------------------------------- */

static void *mycalloc(int count, int size)
{
    int i,n;
    char *c;
    void *p;
    n = count*size;
    p = malloc(n);
    for (i=0, c=(char *)p; i<n; i++)
      *c++ = 0;
    return p;
}

/* -------------------------------------------------------------------------
|| DSPSetCurrentSymbolTable - Selects a symbol table.
------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------
|| MAKE SYM TAB  - Creates symbol table.
------------------------------------------------------------------------- */

/* The following added by DAJ--2/26/93 */
static int s_cur_symtab = 0; 
static struct symtab **s_st = 0;
static int n_symtabs = 0;

static int s_makeSymTab(void)
{
    if (!s_st[s_cur_symtab])
      s_st[s_cur_symtab] = (struct symtab *) mycalloc(sizeof(struct symtab),1);
    return 0;
}

int DSPSetCurrentSymbolTable(int index)
{
    if (index >= n_symtabs)  { /* Index is zero-based */
	int i;
	if (n_symtabs == 0) 
	  s_st = malloc(sizeof(struct symtab *) * (index+1));
	else {
	    s_st = realloc(s_st,sizeof(struct symtab *) * (index+1));
	}
	for (i=n_symtabs; i<index+1; i++)
	  s_st[i] = 0;
	n_symtabs = index + 1;
    }
    s_cur_symtab = index;
    if (!s_st[s_cur_symtab])
      s_makeSymTab();
    return 0;
}

/* -------------------------------------------------------------------------
   DSPClearSymbolTable - Clear symbol table by releasing all symbol entries
------------------------------------------------------------------------- */

void DSPClearSymbolTable(void)
{
    struct ventry *tp, *np;
    int i;

    if (s_st[s_cur_symtab] == NULL) return;
    for (i = 0; i < vnbuckets; ++i) 
    { tp = s_st[s_cur_symtab]->buckets[i];
      s_st[s_cur_symtab]->buckets[i] = NULL;
      while (tp != NULL)
      {	np = tp->next_ventry;
	free(tp);
	tp = np;
    }
  }
}


void DSPFreeSymbolTable(void)
{   if (s_st[s_cur_symtab] == NULL) return;
    DSPClearSymbolTable();
    free(s_st[s_cur_symtab]);
    s_st[s_cur_symtab] = NULL;
}


/* -------------------------------------------------------------------------
|| HASH - Produces hash key from string and table length
------------------------------------------------------------------------- */

/* Winning hash function out of 10 entries from NeXT Software Dept. */
/* Submitted by Mike McNabb - see ~/m/hashing_strings for more info. */
static unsigned s_hashKey(char *string, int length)
{
    register unsigned short i=0;
    register const char *end=string+strlen(string);
    while (string<end) {
        i += *(unsigned short *)string;
        string+=2;
    }
    if (string==end) i+=(unsigned short)*string;  
    /* If string is odd number of chars long */
    return (unsigned)(i % length);
}

#if 0
static unsigned hash_original(const char *string, unsigned length)
{
    register unsigned short i=0;
    register const char *end=string+length-1;
    while (string<end) {
        i += *(unsigned short *)string;
        string+=2;
    }
    if (string==end) i+=(unsigned short)*string;  
    /* If string is odd number of chars long */
    return (unsigned)i;
}

static long s_hashKey(char *sym, int tlen)
{
    long hval;

    hval = 05252525;	/* Big number to disperse 1-char symbols */
    while (*sym != '\0')
    {	hval = (hval << 1) ^ (*sym++ & 0377);
	if (hval < 0)
	{   hval++;	/* Fold sign bit */
	    hval &= 017777777777;	/* Make it always positive */
	}
    }
    return(hval % tlen);
}
#endif

/* -------------------------------------------------------------------------
|| ENTER SYMBOL - Make a symbol table entry for a given string and store value
------------------------------------------------------------------------- */

int DSPEnterSymbol(char *sym, DSPSymbol *val)
{
    struct ventry *newentry;	/* formerly RETURNED via arg list */
    struct ventry *nlastentry;
    int hashval;

    if (!s_st[s_cur_symtab])
      s_makeSymTab();

    newentry = NULL;
    if (sym == NULL || *sym == '\0') return(FALSE);

    hashval = s_hashKey(sym,vnbuckets);
    for (nlastentry = s_st[s_cur_symtab]->buckets[hashval];
	 nlastentry != NULL; nlastentry = nlastentry->next_ventry)
      if (strcmp(sym, nlastentry->symbol) == 0)
      {	nlastentry->value = val;
	/* nlastentry->type = typ; */
	nlastentry->type = 0;
	newentry = nlastentry;
	return(TRUE);		/* Found and updated */
    }

    newentry = (struct ventry *) mycalloc(sizeof(struct ventry),1);
    (newentry)->symbol = (char *) malloc(strlen(sym)+1);
    strcpy((newentry)->symbol,sym);
    (newentry)->entry_symtab = s_st[s_cur_symtab];	/* Say who we belong to */
    (newentry)->value = val;
    /* (newentry)->type = typ; */
    (newentry)->type = 0;
    (newentry)->next_ventry = s_st[s_cur_symtab]->buckets[hashval];
    s_st[s_cur_symtab]->buckets[hashval] = newentry;
#if 0
    (newentry)->offset = s_st[s_cur_symtab]->NSyms;	/* Set offset of symbol */
#endif
    ++(s_st[s_cur_symtab]->NSyms);			/* And bump number thereof */
    return(FALSE);
}


/* -------------------------------------------------------------------------
|| SYMBOL LOOKUP - Get value associated with string symbol
------------------------------------------------------------------------- */

int DSPLookupSymbol(char *sym, DSPSymbol **val)
{
    struct ventry *nlastentry;	/* formerly an arg returning whole entry */

    if (!s_st[s_cur_symtab])
      return TRUE;

    nlastentry = NULL;
    if (sym == NULL || *sym == '\0') return(TRUE);

    for (nlastentry = s_st[s_cur_symtab]->buckets[s_hashKey(sym,vnbuckets)];
	 nlastentry != NULL; nlastentry = (nlastentry)->next_ventry)
      if (strcmp(sym,(nlastentry)->symbol) == 0)
      {	*val = (nlastentry)->value;
	/* *typ = (nlastentry)->type; */
	return FALSE;		/* Found ok */
    }
    return TRUE;
}

