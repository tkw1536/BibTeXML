# /=====================================================================\ #
# |  BiBTeXML::Compiler::Target::Perl                                   | #
# | perl compile target implementation                                  | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Compiler::Target::Perl;

use base qw(BiBTeXML::Compiler::Target);

# makeIndent($level) - make indent of a given level
# - $indent:   integer, indicating level of indent to make
sub makeIndent { '  ' x $_[1]; }

# character escapes for all the names
our %ESCAPES = (
  # numbers
'0' => '0', '1' => '1', '2' => '2', '3' => '3', '4' => '4', '5' => '5', '6' => '6', '7' => '7', '8' => '8', '9' => '9',

  # small letters
'a' => 'a', 'b' => 'b', 'c' => 'c', 'd' => 'd', 'e' => 'e', 'f' => 'f', 'g' => 'g', 'h' => 'h', 'i' => 'i', 'j' => 'j',
'k' => 'k', 'l' => 'l', 'm' => 'm', 'n' => 'n', 'o' => 'o', 'p' => 'p', 'q' => 'q', 'r' => 'r', 's' => 's', 't' => 't',
  'u' => 'u', 'v' => 'v', 'w' => 'w', 'x' => 'x', 'y' => 'y', 'z' => 'z',

  # capital letters
'A' => 'A', 'B' => 'B', 'C' => 'C', 'D' => 'D', 'E' => 'E', 'F' => 'F', 'G' => 'G', 'H' => 'H', 'I' => 'I', 'J' => 'J',
'K' => 'K', 'L' => 'L', 'M' => 'M', 'N' => 'N', 'O' => 'O', 'P' => 'P', 'Q' => 'Q', 'R' => 'R', 'S' => 'S', 'T' => 'T',
  'U' => 'U', 'V' => 'V', 'W' => 'W', 'X' => 'X', 'Y' => 'Y', 'Z' => 'Z',

  # special characters
  '_' => '__',
  '.' => '_o_',
  '$' => '_S_',
  '>' => '_gt_',
  '<' => '_lt_',
  '=' => '_eq_',
  '+' => '_pl_',
  '-' => '_mi_',
  '*' => '_as_',
  ':' => '_co_',
);

# escape the name of a function or variable for use as the name
# of a subrutine in generated perl code
sub escapeName {
  my ($class, $name) = @_;
  my $result = '';
  my @chars = split(//, $name);
  foreach my $char (@chars) {
    if (defined($ESCAPES{$char})) {
      $result .= $ESCAPES{$char};
    } else {
      $result .= '_' . ord($char) . '_';
    }
  }
  return $result;
}

# escapeBuiltinName($name) - escapes the name of a built-in function
# - $name:  the name of the function to be escaped
sub escapeBuiltinName { 'builtin__' . escapeName(@_); }

# escapeFunctionName($name) - escapes the name of a user-defined function
# - $name:  the name of the function to be escaped
sub escapeFunctionName { 'bst__' . escapeName(@_); }

# escapeString($string) - escapes a string constant
# - $string:    the string to be escaped
sub escapeString {
  my ($class, $string) = @_;
  $string =~ s/\\/\\\\/g;          # escape \ as \\
  $string =~ s/'/\\'/g;            # escape ' as \'
  return '\'' . $string . '\'';    #  surround in single quotes
}

# escapeInteger($name) - escapes an integer
# - $integer:    the integer to be escaped
sub escapeInteger {
  my ($class, $integer) = @_;
  return '' . $integer;    # just turn it into a string
}

# escapeFunctionReference($name) - escapes the reference to a bst-level function
# - $name:    the (escaped) name of the bst function to call
sub escapeBstFunctionReference {
  my ($class, $name) = @_;
  return '\\&' . $name;    # we need a perl function reference
}

# escapeBstInlineBlock($block, $sourceString, $outerIndent, $innerIndent) - escapes the definition of a bst-inline block
# - $block:         the (compiled) body of the block to define
# - $sourceString:  the StyString this inline function was defined from
# - $outerIndent:   the (generated) outer indent, for use in multi-line outputs
# - $innerIndent:   the (generated) inner indent, for use in multi-line outputs
sub escapeBstInlineBlock {
  my ($class, $block, $sourceString, $outerIndent, $innerIndent) = @_;
  my $code = "sub { \n";
  $code .= $innerIndent . 'my ($context) = @_; ' . "\n";    # TODO: Fix indent
  $code .= $block . $outerIndent . '}';
  return $code;
}

# bstFunctionDefinition($name, $sourceString, $body, $outerIndent, $innerIndent) - escapes the definition to a bst function
# - $name:          the (escaped) name of the bst function to define
# - $sourceString:  the StyString this function was defined from
# - $body:          the (compiled) body of the function to define
# - $outerIndent:   the (generated) outer indent, for use in multi-line outputs
# - $innerIndent:   the (generated) inner indent, for use in multi-line outputs
sub bstFunctionDefinition {
  my ($class, $name, $sourceString, $body, $outerIndent, $innerIndent) = @_;
  my $code = "sub $name { \n";
  $code .= $innerIndent . 'my ($context) = @_; ' . "\n";    # TODO: Fix indent
  $code .= $body . $outerIndent . '}';
  return $code;
}

# bstFunctionCall($name, $sourceString, @argument) - compiles a call to a bst-level function
# - $name:          the name of the runtime function to call
# - $sourceString:  the StyString this call was made from
# - @arguments:     a set of appropriatly escaped arguments to give to the call
sub bstFunctionCall {
  return runtimeFunctionCall(@_); # in perl, this is the same as a runtime function call because of the defintion
}

# runtimeFunctionCall($name, $sourceString, @arguments) - compiles a call to function in the runtime
# - $name:          the name of the runtime function to call
# - $sourceString:  the StyString this call was made from
# - @arguments:     a set of appropriatly escaped arguments to give to the call
sub runtimeFunctionCall {
  my ($class, $name, $sourceString, @arguments) = @_;
  my $call = join(", ", @arguments, $sourceString->stringify);
  return "$name(\$context, " . $call . '); ';
}

# wrapProgram($program) - function used to wrap a compiled program
# - $program:      the compiled program
sub wrapProgram {
  my ($class, $program) = @_;

  my $code = "sub { \n";
  $code .= $class->makeIndent(1) . "# code automatically generated by BiBTeXML \n";
  $code .= $class->makeIndent(1) . 'use BiBTeXML::Runtime; ' . "\n";
  $code .= $class->makeIndent(1) . 'my ($context) = @_; ' . "\n";
  $code .= $program;
  $code .= "\n\n";
  $code .= $class->makeIndent(1) . 'return $context; ' . "\n";
  $code .= $class->makeIndent(1) . "# end of automatically generated code \n";
  $code .= "}";

  return $code;
}

1;