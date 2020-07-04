package MutationFinder::BaselineMutationExtractor;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
#
# File created on 25 Jan 2007.
################

use strict;
use Data::Dumper;
use MutationFinder::Constant;
use base 'MutationFinder::MutationExtractor';

# class BaselineMutationExtractor(MutationExtractor):
# A class for extracting point mutations mentions from text
#
# This class is based on the MuteXt system, described in
# Horn et al., (2004). Their rules for matching point mutations
# are implemented, but their sequence-based validation step is
# not. This class is the 'baseline system' discussed in
# Caporaso et al., (2007), and can be used to reproduce those
# results. Exact instructions for reproducing those results are
# provided in the example code <??WHERE WILL EXAMPLE CODE BE??>
#
# MuteXt matches amino acid single letter abbreviations in uppercase

my $single_letter_match = join '', values %amino_acid_three_to_one_letter_map;

# MuteXt only matches amino acid three letter abbreviations in titlecase
# (i.e. first letter in uppercase, all others in lowercase)
my @title_aa = map { ucfirst lc $_ } keys %amino_acid_three_to_one_letter_map;
my $triple_letter_match = join '|', @title_aa;

# The MuteXt paper doesn't speicfy what cases are used for matching full
# residue mentions. We allow lowercase or titlecase for maximum recall --
# precision seems unlikely to be affected by this.
my @lc_aa = map { lc $_ } keys %amino_acid_name_to_one_letter_map;
my @ucfirst_aa = map { ucfirst lc $_ } keys %amino_acid_name_to_one_letter_map;
my $full_name_match = join '|', @lc_aa, @ucfirst_aa;

my $single_wt_res_match = "([${single_letter_match}])";
   # r''.join([r'(?P<wt_res>[',single_letter_match,r'])'])
my $single_mut_res_match = "([${single_letter_match}])";
   # r''.join([r'(?P<mut_res>[',single_letter_match,r'])'])

my $triple_wt_res_match = "(${triple_letter_match})";
   # r''.join([r'(?P<wt_res>(',triple_letter_match,r'))'])
  
my $triple_mut_res_match = "(${triple_letter_match})";
   # r''.join([r'(?P<mut_res>(',triple_letter_match,r'))'])

my $full_mut_res_match = "(${full_name_match})";
   # r''.join([r'(?P<mut_res>(',full_name_match,r'))'])

my $position_match =  '([1-9][0-9]*)';
   # """"(?P<pos>[1-9][0-9]*)"""

sub new
{
    my ($class, $opt) = @_;

    my $ignorecase = FALSE;
    $ignorecase = $opt->{ignorecase} if defined $opt->{ignorecase};

    my $self = $class->SUPER::new($opt);

    # Initialize the object
    $self->{_word_regexs} = [];
    $self->{_string_regexs} = [];
    $self->{_replace_regex} = qr/[^a-zA-Z0-9\s]/;

    my ($word_regex_patterns, $word_match_index)
        = $self->_build_word_regex_patterns();
    my ($string_regex_patterns, $string_match_index)
        = $self->_build_string_regex_patterns();

    $self->{_string_regex_match_index} = $string_match_index;
    $self->{_word_regex_match_index} = $word_match_index;

    # Compile the regular expressions, and set appropriate flags
    foreach my $regex_pattern (@{$word_regex_patterns})
    {
        if ($ignorecase)
        {
            push @{$self->{_word_regexs}}, qr/${regex_pattern}/i;
        }
        else
        {
            push @{$self->{_word_regexs}}, qr/${regex_pattern}/;
        }
    }
    foreach my $regex_pattern (@{$string_regex_patterns})
    {
        if ($ignorecase)
        {
            push @{$self->{_string_regexs}}, qr/${regex_pattern}/i;
        }
        else
        {
            push @{$self->{_string_regexs}}, qr/${regex_pattern}/;
        }
    }

    bless $self, $class;
    return $self;
}

# build the sentence-level regex patterns
#
# These patterns match an xN followed by a mutant residue
# mention within ten words
# (e.g. 'we mutated Ser42 to glycine')
# The wt residue can be a one- or three-letter abbreviation, and the
# mt residue can be a three-letter abbreviation or full name.
#
sub _build_string_regex_patterns($)
{
    my ($self) = @_;

    my $single_triple_pattern =
        '(^|\s)' .
        $single_wt_res_match .
        $position_match .
        '\s(\w+\s){0,9}' .
        $triple_mut_res_match .
        '(\s|$)';
    my %single_triple_match_index =
    (
        wt_res  => 2,
        pos     => 3,
        mut_res => 5
    );

    my $single_full_pattern =
        '(^|\s)' .
        $single_wt_res_match .
        $position_match .
        '\s(\w+\s){0,9}' .
        $full_mut_res_match .
        '(\s|$)';
    my %single_full_match_index = %single_triple_match_index;

    my $triple_triple_pattern =
        '(^|\s)' .
        $triple_wt_res_match .
        $position_match .
        '\s(\w+\s){0,9}' .
        $triple_mut_res_match .
        '(\s|$)';
    my %triple_triple_match_index = %single_triple_match_index;

    my $triple_full_pattern =
        '(^|\s)' .
        $triple_wt_res_match .
        $position_match .
        '\s(\w+\s){0,9}' .
        $full_mut_res_match .
        '(\s|$)';
    my %triple_full_match_index = %single_triple_match_index;

    my @pattern =
    (
        $single_triple_pattern,
        $single_full_pattern,
        $triple_triple_pattern,
        $triple_full_pattern
    );
    my @match_index =
    (
        \%single_triple_match_index,
        \%single_full_match_index,
        \%triple_triple_match_index,
        \%triple_full_match_index
    );

    return (\@pattern, \@match_index);
}

# Build the word-level reqex patterns
#
# These patterns match wNm format mutations using either
# one-letter abbreviations OR three-letter abbreviations, but
# not a mixture.
# (e.g. A42G and Ala42Gly will match, but not A42Gly)
#
sub _build_word_regex_patterns($)
{
    my ($self) = @_;
    my @pattern;
    my @match_index;

    my $single_single_pattern =
        '^' .
        $single_wt_res_match .
        $position_match .
        $single_mut_res_match .
        '$';
    my %single_single_match_index =
    (
        wt_res  => 1,
        pos     => 2,
        mut_res => 3
    );

    my $triple_triple_pattern =
        '^' . 
        $triple_wt_res_match . 
        $position_match .
        $triple_mut_res_match .
        '$';
    my %triple_triple_match_index = %single_single_match_index;

    my @pattern =
    (
        $single_single_pattern,
        $triple_triple_pattern
    );
    my @match_index =
    (
        \%single_single_match_index,
        \%triple_triple_match_index
    );

    return (\@pattern, \@match_index);
}

# Extract point mutations mentions from raw_text and return them in an array
# 
# raw_text: the text from which mutations should be extracted
# IT IS NOT POSSIBLE TO STORE SPANS WHEN EXTRACTING MUTATIONS WITH
# BaselineMutationExtractor. Because MuteXt splits on sentences and
# words, and removes alphanumeric characters from within words, the
# mappings to original character-offsets get complicated.
# MutationFinder does, however, return spans.
#
sub call
{
    my ($self, $raw_text) = @_;
    my @result = ();

    my @word = $self->_preprocess_words($raw_text);

    # Apply patterns which work on the word level
    foreach my $word (@word)
    {
        my $regex_index = 0;
        foreach my $regex (@{$self->{_word_regexs}})
        {
            while ($word =~ m/$regex/g)
            {
                my $match =
                    $self->{_word_regex_match_index}->[$regex_index];
                my $finding = $self->get_point_mention_data($match);
                push @result, $finding;
            }
            $regex_index++;
        }
    }

    my @sentence = $self->_preprocess_sentences($raw_text);

    # Apply patterns which work on the sentence level and attempt to
    # to find a mutant residue up to ten words ahead of a xN match
    foreach my $sentence (@sentence)
    { 
        my $regex_index = 0;
        foreach my $regex (@{$self->{_string_regexs}})
        {
            while ($sentence =~ m/$regex/g)
            {
                my $match =
                    $self->{_string_regex_match_index}->[$regex_index];
                my $finding = $self->get_point_mention_data($match);
                push @result, $finding;
            }
            $regex_index++;
        }
    }

    return @result;
}

sub get_point_mention_data
{
    my ($self, $match) = @_;

    my $wt_res = eval "\$$match->{wt_res}";
    my $pos = eval "\$$match->{pos}";
    my $mut_res = eval "\$$match->{mut_res}";
    my $current_mutation = new MutationFinder::PointMutation(
        {position => $pos, wild => $wt_res, mut => $mut_res});

    my $finding = new MutationFinder::Mention({mutation => $current_mutation});
    return $finding;
}


# Preprocess input text as MuteXt does
# 
# When working on sentences, MuteXt splits on sentence
# breaks and removes all non-alphanumeric characters.
#
sub _preprocess_sentences($$)
{
    my ($self, $raw_text) = @_;

    my @sentence = ();
    foreach my $sentence (split /\./, $raw_text)
    {
        my $replace_regex = $self->{_replace_regex};
        $sentence =~ s/${replace_regex}//g;
        $sentence =~ s/^\s+//;
        $sentence =~ s/\s+$//;
        push @sentence, $sentence;
    } 

    return @sentence;
}

# Preprocess input text as MuteXt does
#
# When working on words, MuteXt splits an input string
# on spaces and removes all non-alphanumeric characters.
#
sub _preprocess_words($$)
{
    my ($self, $raw_text) = @_;
    my @word = ();
    foreach my $word (split(/\s/, $raw_text))
    {
        my $replace_regex = $self->{_replace_regex};
        $word =~ s/${replace_regex}//g;
        push @word, $word;
    } 

    return @word;
}


1;
__END__
=pod

=head1 NAME

MutationFinder::BaselineMutationExtractor -  Baseline system to extract mutation mentions from text.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

    use MutationFinder::BaselineMutationExtractor;
    use MutationFinder::Mention;

    my $Bme = new MutationFinder::BaselineMutationExtractor();
    my %doc = $Bme->extract_mutations_from_lines_to_hash('/tmp/file.txt');
    $Bme->extract_mutations_from_lines_to_file('/tmp/file.txt', '/tmp/file.txt.mf');

    my @line = 
    (
        "id1\tMutate Arg at position 12 to Glycine. It is noteworthy",
        "id2\tThe G47S mutation caused the hydrophilic region to be exposed."
    );
    my @extraction = $Bme->extract_mutations_from_lines(\@line);
    foreach my $extract (@extraction)
    {
        print $extract->id(), "\n";
        while my $ment ($extract->next())
        {
            print $ment->mutation->str(), "\n";
        }
    }

=head1 DESCRIPTION

This class implements methods described by Horn et al. to extract mutation
mentions from text. Most of its functionality is derived from
the MutationFinder::MutationExtractor base class. See the perldoc from
this base class for more details.

=head1 METHODS

=head2 PACKAGE->new([HASHREF])

Construct a new MutationFinder object. All settings for the base class
MutationFinder::MutationExtractor are valid. The following options are
also available through the HASHREF argument:

=over

=item *

ignorecase => TRUE|FALSE

Indicate if the distinction between upper and lowercase letters should be
ignored when searching for mutation mentions. Note that ignoring case will
improve recall at the expense of precision. The default is FALSE.

=back

=head2 $OBJ->call(SCALAR)

Given a string of raw text, returns an array of Mention objects representing
the point mutation mentions found in the text.

=head2 $OBJ->get_point_mention_data(SCALAR)

Return a Mention object given a HASHREF that indicates which standard
pattern-matching variables (e.g., $1, $2) store the various parts of the
mutation mention. This function must be called immediately after a regular
expression is evaluated to ensure that the standard variable are populated
with the correct data. This is handled this way because Perl does not
currently support named match variables, and we are naming the variables
in our defined regular expressions.

Overrides the base class method because the baseline system does not
support spans. 

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=back

=cut
