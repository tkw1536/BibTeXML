# /=====================================================================\ #
# |  BiBTeXML::Cmd::bibtexml                                            | #
# | bibtexml entry point                                                | #
# |=====================================================================| #
# | Part of BibTeXML                                                    | #
# |---------------------------------------------------------------------| #
# | Tom Wiesing <tom.wiesing@gmail.com>                                 | #
# \=====================================================================/ #

package BiBTeXML::Cmd::bibtexml;
use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray);

use BiBTeXML::Runner;
use BiBTeXML::Common::Utils qw(slurp);

sub main {
    shift(@_);    # remove the first argument

    my ( $output, $macro, $cites, $wrap, $help ) = ( undef, undef, '*', 0, 0 );
    GetOptionsFromArray(
        \@_,
        "destination=s" => \$output,
        "macro=s"       => \$macro,
        "cites=s"       => \$cites,
        "wrap"          => \$wrap,
        "help"          => \$help,
    ) or return usageAndExit(1);

    # if we requested help, or we had a wrong number of arguments, exit
    return usageAndExit(0) if ($help);
    return usageAndExit(1) if scalar(@_) le 1;

    my ( $bstfile, @bibfiles ) = @_;

    # create a reader for the bib files
    my $reader;
    my (@bibreaders);

    foreach my $bibfile (@bibfiles) {
        $reader = BiBTeXML::Common::StreamReader->newFromFile($bibfile);
        unless(defined($reader)) {
            print STDERR "Unable to find bibfile $bibfile\n";
            return 4;
        }
        push( @bibreaders, $reader );
    }

    # create a reader for the bst file
    $reader = BiBTeXML::Common::StreamReader->newFromFile($bstfile);
    unless (defined($reader)) {
        print STDERR "Unable to find bstfile $bstfile\n";
        return 3;
    }

    # prepare the output file
    my $ofh;
    if ( defined($output) ) {
        open( $ofh, ">", $output );
    } else {
        $ofh = *STDOUT;
    }
    unless ( defined($ofh) ) {
        print STDERR "Unable to find $output";
        return 5, undef;
    }

    # compile the bst file
    my ( $status, $compiled ) = createCompile(
        $reader,
        sub {
            print STDERR @_;
        },
        $bstfile
    );
    return $status, undef if $status ne 0;

    # eval the code
    $compiled = eval $compiled;
    unless(ref $compiled eq 'CODE') {
        print STDERR "Compilation error: Expected 'CODE' but got '" . ref($compiled) . "'. ";
        return 3;
    } 

    # create a run
    my @citations = split( /,/, $cites );
    my $runcode = createRun(
        $compiled,
        [@bibreaders],
        [@citations],
        $macro,
        sub {
            print STDERR @_;
        },
        $ofh,
        $wrap,
    );

    # and run the code
    return &{$runcode}();
}

# helper function to print usage information and exit
sub usageAndExit {
    my ($code) = @_;
    print STDERR
'bibtexml [--help] [--wrap] [--destination $DEST] [--cites $CITES] [--macro $MACRO] $BSTFILE $BIBFILE [$BIBFILE ...]'
      . "\n";
    return $code;
}

1;
