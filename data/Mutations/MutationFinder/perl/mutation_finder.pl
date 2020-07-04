#!/usr/bin/env perl
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph.
# mutation_finder.pl
# File created on 25 Jan 2007.
################################################################################
# PRAGMAS
################################################################################
use strict;
use Getopt::Long qw(:config auto_version auto_help);
use FindBin;
use lib "$FindBin::Bin";
use File::Basename;
use Data::Dumper;
use MutationFinder::Constant;
use MutationFinder::Mutation;
use MutationFinder::PointMutation;
use MutationFinder::MutationFinder;
use MutationFinder::BaselineMutationExtractor;

use vars qw($VERSION);

################################################################################
# CONSTANTS
################################################################################
$VERSION = MutationFinder::Constant::VERSION;
use constant MUTATION_FINDER_OUTPUT_FILE_EXTENSION => 'mf';


################################################################################
# GLOBAL VARIABLES
################################################################################
my $Opt = {}; # Reference to hash of command-line options.
my $Args = []; # Reference to array of command-line arguments.
my $Mutation_Extractor; # Reference to MutationExtractor obj to process input.


################################################################################
# FUNCTIONS
################################################################################
#-------------------------------------------------------------------------------
# Construct the filepath for the output file
# 
# output_dir: the path to where output should be written
# input_filepath: the path to the input file -- this is used to
#     construct the output file name; the value of this parameter
#     is checked explicitly to ensure that an empty string is not
#     passed in, since that could end up creating a hidden file
#     which could be confusing and annoying
#-------------------------------------------------------------------------------
sub build_output_filepath($$)
{
    my ($output_dir, $input_filepath) = @_;
    my $output_filename;
    if ($input_filepath)
    {
        my $input_basename = basename $input_filepath;
        $output_filename = $input_basename . '.' .  
            MUTATION_FINDER_OUTPUT_FILE_EXTENSION;
    }
    else
    {
        die 'Must pass non-empty input filepath to construct output filename';
    }

    my $output_filepath;
    if ($output_dir =~ m=/$=)
    {
        $output_filepath = $output_dir . $output_filename;
    }
    else
    {
        $output_filepath = $output_dir . '/' . $output_filename;
    }

    return $output_filepath;
}


################################################################################
# MAIN BLOCK 
################################################################################
GetOptions($Opt,
    'output_dir=s',
    'output_normalized_mutations',
    'regular_expression_filepath=s',
    'store_spans',
    'use_baseline_system',
    '<>' => sub { push @{$Args}, @_; });
$Opt->{output_dir} = './' if not defined $Opt->{output_dir};
$Opt->{regular_expression_filepath} = "$FindBin::Bin/../regex.txt" 
    if not defined $Opt->{regular_expression_filepath};
$Opt->{store_spans} = FALSE if not defined $Opt->{store_spans};
$Opt->{output_normalized_mutations} = FALSE 
    if not defined $Opt->{output_normalized_mutations};

# Construct the mutation extractor object -- note that users can specify
# to use either the BaselineMutationExtractor or MutationFinder with the
# -b option.
if (defined $Opt->{use_baseline_system})
{
    $Mutation_Extractor = new MutationFinder::BaselineMutationExtractor();
}
else
{
    my %opt;
    $opt{regex_file} = $Opt->{regular_expression_filepath};
    $opt{report_spans} = TRUE if $Opt->{store_spans};
    $opt{report_normalized} = TRUE if $Opt->{output_normalized_mutations};

    $Mutation_Extractor = new MutationFinder::MutationFinder(\%opt);
}

if (not @{$Args})
{
    die "error: No input files specified -- there's nothing to do.\n";
}

foreach my $input_filepath (@{$Args})
{
    my $output_filepath = 
        build_output_filepath($Opt->{output_dir}, $input_filepath);

    $Mutation_Extractor->extract_mutations_from_lines_to_file(
        $input_filepath, $output_filepath);
}


__END__
=pod

=head1 NAME

mutation_finder.pl - Extract protein mutation mentions from text.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

     perl mutation_finder.pl --help
     perl mutation_finder.pl [--output_dir dir_path]
         [--store_spans | --output_normalized_mutations]
         [--regular_expression_filepath regular_expression_filepath]
         [--use_baseline_system] input_file1.tsv ...

=head1 DESCRIPTION

This is the Perl implementation of MutationFinder. It can be used 
in one of two ways:

=over

1) as a script for extraction mutation mentions from text sources

2) as library code imported to other Perl applications

=back

=head1 OPTIONS

=item B<--help>

Print a brief help message and exit.

=item B<--output_dir directory_path>

Specify the directory where output files should be stored. If not set,
the current working directory is used.

=item B<--output_normalized_mutations>

Return normalized mutations rather than extracted mentions.

=item B<--regular_expression_filepath regular_expression_filepath>

The regular expression file to be used when constructing MutationFinder
[default: ../regex.txt].

=item B<--store_spans>

Record the span, in byte offsets, where the mutation was identified.

=item B<--use_baseline_system>

Use the baseline "MuteXt" system based on Horn et al. (2004) to extract
mutation mentions.  Their rules for matching point mutations
are implemented, but their sequence-based validation step is
not. This is the 'baseline system' discussed in
Caporaso et al., (2007), and can be used to reproduce those
results. Exact instructions for reproducing those results are
provided in the example code included in this distribution.

=item B<--version>

Describe the version of the program and exit.

=head1 ASSUMPTIONS

None.

=head1 EXAMPLES

Extract the mutation mentions in the t1.txt and t2.txt files and display
the byte offset where each mention appears in the text record (paragraph).

     mutation_finder.pl --store_spans

=head1 SEE ALSO

To use the library code, see the perldoc for the following modules:

=over

=item * 

MutationFinder::BaselineMutationExtractor

=item *

MutationFinder::MutationExtractor

=item *

MutationFinder::Extraction

=item *

MutationFinder::Mention

=item *

MutationFinder::Mutation

=item *

MutationFinder::MutationFinder

=item *

MutationFinder::Object

=item *

MutationFinder::PointMutation

=back

=head1 AUTHOR

=item Greg Caporaso 

=item David Randolph (Perl port)

=cut
