#!/usr/bin/perl
# $Id$
# Script to create HeaderDoc comments from NeXT documentation
# converted from RTF to HTML.
# Leigh Smith <leigh@tomandandy.com>
#
# NeXT RTF doco file consists of:
#  CLASS DESCRIPTION
#  description
#  INSTANCE VARIABLES
#  CLASS METHODS
#  name which must match first word of prototype.
#  + prototype
#  \n\n
#  description
#  INSTANCE METHODS
#  name which must match first word of prototype.
#  - prototype
#  \n\n
#  description
#  PARAMETER INTERPRETATION
#  part of class description
#  EOF
#
# A method consists of a prototype followed by its description (discussion).
#
# headerDoc expects the copyright to be placed in a configuration
# file: headerDoc2HTML.config in the cwd. We use that for the
# copyright statement.
#
# We write the output either as a header file with only comments, or
# as a sed script to run over the existing .h file to merge the new
# comments in.
# Sed scripts look like:
# /- *methodName:/i\
# \
# /*\
# New header\
# */
$nameMethods="method";		# or "function".

eval 'exec /usr/bin/perl -S $0 ${1+"$@"}' if $running_under_some_shell;

while ($ARGV[0] =~ /^-/) {
    $_ = shift;
    last if /^--/;
    if (/^-n/) {
	$printMissing++;
	next;
    }
    elsif (/^-s/) {
	$sedOutput++;
	next;
    }
    die "I don't recognize this switch: $_\\n";
}

if($sedOutput) {
    $eolChar = "\\";		# add a backslash and newline on print
}

$\ = "\n";			# automatically add newline on print

# get Class name from filename
$ARGV[0] =~ /\/([^\/]*?)\.html/;
$classname = $1;

# Since HTML doesn't interpret \n as formatting, we read the entire
# file into memory, replacing \n's with spaces.
while (chop($_ = <>)) {
    #
    # Here we remove wierd HTML cruft.
    #
    # remove <div></div> tags
    s/<div[^>]*>//g;
    s/<\/div>//g;
    # and wierd space characters
    s/&#8364;/ /g;
    # and wierd not signs indicating RTF images.
    s/&#172;//g;
    # move any leading space before an end tag i.e 
    # <b>Text with trailing space </b>
    s/(  *)<\/(.*)>/<\/$2>$1/g;

    # This checks if any page breaks divide a section title.
    $wholeFile = $wholeFile . " " . $_;
}

# Synthpatches have parameter descriptions at the end of the file.
if($wholeFile =~ s/Parameter Interpretation(.*?)$//i) {
    $parameterInterpretation = $1;
}

# Check for class header, if so, generate a @header tag
if ($wholeFile =~ s/^.*?Class Description(.*?)Instance Variables/Instance Variables/i) {
    $description = $1;
    if($sedOutput) {
	printf("1i\\\n");
    }
    printf("/*!%s\n  \@header $classname%s\n", $eolChar, $eolChar);

    # Substitute any .eps files to be a figure
    $description =~ s/([^>\s]+)\.eps/\<img src=\"Images\/$1.gif\">/;
    
    if(length($parameterInterpretation) != 0) {
	$description .= "<h2>Parameter Interpretation</h2>". $parameterInterpretation;
    }
    # output the text of the description
    # compact more than two consecutive \n's to a single one.
    $description =~ s/<br>\s*<br>\s*(<br>)+?/<br><br>/g;
    # convert HTML page breaks to standard EOLs (HeaderDoc generates its own).
    $description =~ s/<br>/$eolChar\n/g;
    printf("%s%s\n*/\n", $description, $eolChar);
}
    
# Remove the methods listed in the Method Types section
# Retain the instance variables listed in that section as occasionally
# it will have some human created description.
if($wholeFile =~ s/Instance Variables(.*?)Method Types(.*?)(Instance|Class) Methods//i) {
    $ivarDescription = $1;
}

# We can remove the Instance Method title
$wholeFile =~ s/Instance Methods//i;

# Prefix each method definition with HeaderDoc opening.
# find the +/-, the method prototype and the discussion. 
# Look for a non-blank string of characters, possibly
# terminated with a colon that indicates this is the preluding
# method title to the next prototype, effectively the end of the
# description.
# We rewrite this as a <br> to ensure we don't break other prototype
# boundaries.
while ($wholeFile =~ s/<br>\s*([\+\-])\s*(.*?)(<br>)+(.*?)(<br>)+(<br>\S+<br>|<br>$)/<br>/) {
    $classOrInstanceMethod = $1;
    $prototype = $2;
    $discussion = $4;
    $formattedPrototype = $classOrInstanceMethod . $prototype;
    # give ourselves a clean description
    # $formattedPrototype =~ s/<\/*[bi]>//g;

    # Format the prototype for HeaderDoc.
    # Match the return type and the method name prior to parameters.
    if ($prototype =~ s/\s*(\(.*?\)|[^\s<]*?)\s*<b>\s*(.*?)\s*<\/b>//) {
	$returnType = $1;
	$methodName = $2;  # The start of the method name.

	$paramCount = 0;
	while($prototype !~ /^\s*$/) {
	    # print "methodName = $methodName prototype remaining: $prototype";
	    # Match on parameter type (some won't be static)...
	    # Ensure an italicized parameter doesn't precede the type
	    # (indicating we have missed an untyped (i.e id) parameter).
	    if ($prototype =~ s/^\s*\((.*?)\)//) {
		$paramType[$paramCount] = $1;
	    }
	    else {
		$paramType[$paramCount] = "id";
	    }

	    # ...and parameter name
	    if ($prototype =~ s/\s*<i>\s*([^\s]*?)\s*<\/i>//) {
		$paramName[$paramCount] = $1;
	    }
	    
	    # ...and subsequent 'keyName:' keywords
	    if ($prototype =~ s/\s*<b>\s*(.*?:)\s*<\/b>//) {
		$methodName .= $1;
	    }
	    $paramCount++;
	}
    }
    
    # print out what we found, possibly as a sed script
    if($sedOutput) {
	printf("/%s *%s *%s/i\\\n\\\n", $classOrInstanceMethod, $returnType, $methodName);
	$commentPadding = "\\ \\ ";
    }
    else {
	$commentPadding = "  ";
    }
    printf("/*!%s\n", $eolChar); 

    printf("%s\@%s %s%s\n", $commentPadding, $nameMethods, $methodName, $eolChar);
    for($i = 0; $i < $paramCount; $i++) {
	# no return type defaults to id.
	if (length($paramType[$i]) == 0) {
	    $paramType[$i] = "id";
	}
	printf("%s\@param %s is %s %s.%s\n", $commentPadding,
	       $paramName[$i], indefiniteArticle($paramType[$i]), $paramType[$i],
	       $eolChar); 
	$paramType[$i] = $paramName[$i] = "";
    }
    
    # no return type defaults to id.
    if (length($returnType) == 0) {
	$returnType = "id";
    }
    if ($returnType ne "(void)") {
	printf("%s\@result Returns %s %s.%s\n", $commentPadding,
	       indefiniteArticle($returnType), $returnType, $eolChar);
    }

    # convert <br>'s to standard line breaks for headerDoc to do it's stuff.
    $discussion =~ s/<br>/\n/g;
    printf("%s\@discussion %s%s\n*/\n", $commentPadding, $discussion, $eolChar);
}

# print what was not accounted for for debugging.
if ($printMissing) { 
    print STDERR "remaining data not accounted for: $wholeFile";
}

sub indefiniteArticle
{
    return (index("aeiouh", substr($_[0],0,1)) == -1) ? "a" : "an";
}
