NAME = example1
MFILES = example1.m
HFILES =

LIBS = -lmusic_s -ldsp_s -lNeXT_s -lsys_s 

CFLAGS = -O -g
LDFLAGS =

SRCFILES = $(MFILES) $(HFILES) 
OBJFILES = $(MFILES:.m=.o)
GARBAGE = $(DERIVED) core errs 

$(NAME): $(OBJFILES) 
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJFILES) $(LIBS) 

all: $(NAME)

clean: 
	-rm -f *.o $(NAME) $(DERIVED) $(GARBAGE) 

help: 
	@echo '  make $(NAME) - to make the application'
	@echo '  make clean -    to remove all files but the source'


