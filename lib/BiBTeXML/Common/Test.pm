# /=====================================================================\ #
# |  BiBTeXML::Common::Test                                             | #
# | Utility Functions for test cases                                    | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Common::Test;
use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);
use BiBTeXML::Runner;
use BiBTeXML::Common::Utils qw(slurp);

use Encode;
use Time::HiRes qw(time);

use File::Basename qw(dirname);
use File::Spec;

use BiBTeXML::Common::Utils qw(slurp puts);

use base qw(Exporter);
our @EXPORT = qw(
  &fixture &slurp &puts &isResult
  &makeStringReader &makeFixtureReader
  &measureBegin &measureEnd
  &integrationTest &integrationTestPaths
);

# gets the path to a mock fixture
sub fixture {
    File::Spec->join( dirname( shift(@_) ), 'fixtures', @_ );
}

# makes a BiBTeXML::Common::StreamReader to a fixed string
sub makeStringReader {
    my ( $content, $eat, $delimiter ) = @_;
    my $reader = BiBTeXML::Common::StreamReader->new();
    $reader->openString( ( $eat ? ' ' : '' )
        . $content
          . ( defined($delimiter) ? $delimiter : ' ' ) );
    $reader->eatChar if $eat;

    return $reader;
}

# makes a BiBTeXML::Common::StreamReader to a fixture
sub makeFixtureReader {
    my $reader = BiBTeXML::Common::StreamReader->new();
    my $path   = fixture(@_);
    $reader->openFile( $path, "utf-8" );
    return ( $reader, $path );
}

# joins a list of objects by stringifying them
sub joinStrs {
    my @strs = map { $_->stringify; } @_;
    return join( "\n\n", @strs );
}

# starts a measurement
sub measureBegin {
    return time;
}

# ends a measurement
sub measureEnd {
    my ( $begin, $name ) = @_;
    my $duration = time - $begin;
    Test::More::diag("evaluated $name in $duration seconds");
}

sub isResult {
    my ( $results, $path, $message ) = @_;
    Test::More::is( joinStrs( @{$results} ), slurp("$path.txt"), $message );
}

sub integrationTestPaths {
    my ($path) = @_;

    # resolve the path to the test case
    $path = File::Spec->catfile( 't', 'fixtures', 'integration', $path );

    # read the citation specification file
    my $citesIn = [
        grep { /\S/ } split(
            /\n/, slurp( File::Spec->catfile( $path, 'input_citations.spec' ) )
        )
    ];

    # read the macro specification file
    my $macroIn = slurp( File::Spec->catfile( $path, 'input_macro.spec' ) );
    $macroIn =~ s/^\s+|\s+$//g;
    $macroIn = undef if $macroIn eq '';

    # hard-code input and output files
    my $bstIn = File::Spec->catfile( $path, 'input.bst' );
    my $bibIn = File::Spec->catfile( $path, 'input.bib' );
    my $resultOut = File::Spec->catfile( $path, 'output.bbl' );

    return $bstIn, $bibIn, $citesIn, $macroIn, $resultOut;
}

# represents a full test of the BiBTeXML steps
sub integrationTest {
    my ( $name, $path ) = @_;

    # resolve paths to input and output
    my ( $bstIn, $bibIn, $citesIn, $macroIn, $resultOut ) =
      integrationTestPaths($path);

    return subtest "$name" => sub {
        plan tests => 4;

        # create a reader for the bst file
        my $bst = BiBTeXML::Common::StreamReader->newFromFile($bstIn);
        my $bib = BiBTeXML::Common::StreamReader->newFromFile($bibIn);

        # compile it
        my ( $code, $compiled ) = createCompile( $bst, \&note, $bstIn );

        # check that the code compiled without problems
        is( $code, 0, 'compilation went without problems' );
        return if $code ne 0;

        # execute the compiled code
        $compiled = eval $compiled;
        is( ref $compiled, 'CODE', 'compilation produced CODE' );

        # create a temporary file for the output
        my ($output) = File::Temp->new( UNLINK => 1, SUFFIX => '.tex' );
        open( my $handle, ">", $output );
        
        # and create the run
        my $runcode =  createRun( $compiled, [$bib], $citesIn, $macroIn, \&note, $handle, 1 );

        # run the run
        my $status = &{$runcode}();
        is( $status, 0, 'running went ok' );

        # check that we compiled the expected output
        is( slurp($output), slurp($resultOut),
            'compilation returned expected result' );
    };
}

1;
