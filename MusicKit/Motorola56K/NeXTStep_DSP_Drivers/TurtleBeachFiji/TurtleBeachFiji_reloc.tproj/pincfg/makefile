#     MAKEFILE for pincfg.exe
##### Module Macro #####
NAME    = pincfg
SRCS    = $(NAME).c eewrite.c
OBJS    =
LIBS    = c:\plugplay\lib\dos\DOSCMS.LIB

##### Library Macro #####
MOD     = -AS

##### Include Macro #####
INCLS   = $(NAME).h

##### Build Option Macros #####
!if "$(DEBUG)" == "YES"
DDEF	= -DDEBUG
##CLOPT   = -Zid -Od /Zp /Fa  - for asm listin
CLOPT   = -Zid -Od /Zp
MOPT	= -Zi
LOPT	= /CO /LI /MAP
!else
DDEF	=
CLOPT   = -Os /Zp
LOPT	=
!endif

##### Tool Macros #####
CC      = cl -nologo -c $(MOD) $(CLOPT) $(DDEF)
LINK    = link $(LOPT)

##### Inference Rules #####
.c.obj:
    $(CC) $*.c


##### Main (default) Target #####
goal: $(NAME).exe

##### Dependents For Goal and Command Line #####

$(NAME).exe: $(SRCS:.c=.obj)
    $(LINK) @<<
    $(SRCS:.c=.obj) $(OBJS),
    $(NAME).exe,
    $(NAME).map,
    $(LIBS) ;
<<
!if "$(DEBUG)" == "YES"
    mapsym $(NAME).map
!endif

##### Dependents #####
$(SRCS:.c=.obj): $(INCLS)

##### Clean Directory #####
clean:
    -del *.obj
    -del *.exe
    -del *.map
    -del *.sym

