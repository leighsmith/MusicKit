#ifndef __MK_DSPSymbols_H___
#define __MK_DSPSymbols_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */

#import "dsp_structs.h"

int DSPSetCurrentSymbolTable(int theIndex);
/* 
 * Set symbol table to specifed index, creating
 * a new table, if necessary.  Index is zero-based.
 */

void DSPClearSymbolTable(void);
/*
 * Clear current symbol table.
 */

void DSPFreeSymbolTable(void);
/*
 * Free current symbol table.
 * DSPSymbol pointers entered into the table are not freed since they
 * belong to a DSPLoadSpec struct elsewhere.
 */

int DSPEnterSymbol(char *sym, DSPSymbol *val);
/* 
 * Makes a current symbol table entry for a given string and stores the value.
 * Returns 0 for inserted, nonzero for updated previous value.
 * On the first call, the symbol table is created if necessary.
 * Case is preserved.
 */

int DSPLookupSymbol(char *sym, DSPSymbol **val);
/*
 * Gets symbol associated with string sym (normally its name).
 * Returns FALSE for found (no error), TRUE for not found.
 * Case matters. Uses current symbol table.
 */

#endif
