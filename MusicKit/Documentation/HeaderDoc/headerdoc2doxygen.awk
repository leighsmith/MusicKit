# Converts Headerdoc to Doxygen using the Javadoc style in Doxygen
# for minimal change in coding.

# for variables, typedefs or enums
# \var to document a variable or typedef or enum value.
# s//@var
# \struct to document a C-struct.
# \union to document a union.
# \enum to document an enumeration type.
# \fn to document a function.
# \def to document a #define.
# \file to document a file.

# Remove @methods
/@method/ {
    next;
}

/@abstract/ {
    sub("@abstract", "@brief");
    hasAbstract = 1;
}

/@discussion/ {
    sub("@discussion", hasAbstract ? "\n  " : "@brief");
    inDiscussion = 1;
}

/^$|\*\// {
    inDiscussion = 0;
    hasAbstract = 0;
}

!hasAbstract && inDiscussion && /.*\.( +|$)/ {
    # printf("periodline: %s\n", $0);
    sub("\\.( +|$)",".\n\n  ");
    # printf("aftersub: %s\n", $0);
    inDiscussion = 0; # early exit so only first sentence is separated.
}

{ 
    sub("@result", "@return");
    sub(" *See also:", "  @see");
    print;
}

