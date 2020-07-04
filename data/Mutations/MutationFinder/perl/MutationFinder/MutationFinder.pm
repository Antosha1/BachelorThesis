package MutationFinder::MutationFinder;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
# File created on 25 Jan 2007.
################

use strict;
use English;
use Data::Dumper;
use base 'MutationFinder::MutationExtractor';
use MutationFinder::Constant;
use MutationFinder::Mention;


my $single_letter_match = join '', values %amino_acid_three_to_one_letter_map;
my $triple_letter_match = join '|', keys %amino_acid_three_to_one_letter_map;
my $full_name_match = join '|', keys %amino_acid_name_to_one_letter_map;

my $single_wt_res_match = 
    # r''.join([r'(?P<wt_res>[',single_letter_match,r'])'])
    "([$single_letter_match])";
my $single_mut_res_match = 
    # r''.join([r'(?P<mut_res>[',single_letter_match,r'])'])
    "([$single_letter_match])";

my $triple_wt_res_match = 
    # r''.join([r'(?P<wt_res>(',triple_letter_match,r'))'])
    "($triple_letter_match)";
    
my $triple_mut_res_match = 
    # r''.join([r'(?P<mut_res>(',triple_letter_match,r'))'])
    "($triple_letter_match)";

my $wt_res_match = 
    # r''.join([r'(?P<wt_res>(',
    # triple_letter_match,r')|(',full_name_match,r'))'])
    "($triple_letter_match|$full_name_match)";

my $mut_res_match = 
    # r''.join([r'(?P<mut_res>(',
    # triple_letter_match,r')|(',full_name_match,r'))'])
    "($triple_letter_match|$full_name_match)";

my $position_match = 
    #r"""(?P<loc>[1-9][0-9]*)"""
    "([1-9][0-9]*)";

my $replace_word_match =
    # r'\s*(was\s*|were\s*|is\s*)?(((mutated\s*|changed\s*)?to)|((replaced|substituted)\s+(by|with)))\s*'
    "\s*(was\s*|were\s*|is\s*)?(((mutated\s*|changed\s*)?to)|((replaced|substituted)\s+(by|with)))\s*";

my $position_word_match = 
    # r'\s*(at)?\s*(amino acid)?\s*(residue|position)?\s*'
    "\s*(at)?\s*(amino acid)?\s*(residue|position)?\s*";

my $allowed_prefixes = 
    # r'(^|[\s\(\[\'"])'
    '(^|[\s\(\[\'"])';
my $allowed_suffixes = 
    # r'([.,\s)\]\'":;?!]|$)'
    '([.,\s)\]\'":;?!]|$)';


sub new
{
    my ($class, $opt) = @_;

    $opt->{support_spans} = TRUE; 
    my $self = $class->SUPER::new($opt);
    $self->{regex_file} = '';
    $self->{ignorecase} = TRUE;

    foreach my $key ('regex_file', 'ignorecase')
    {
        $self->{$key} = $opt->{$key} if defined $opt->{$key};
    }

    bless $self, $class;

    $self->{_regexs} = [];

    if ($self->{regex_file})
    {
        my ($regex_list) = _build_regex_patterns_from_file($self->{regex_file});
        foreach my $regex_item (@$regex_list)
        {
            my $pattern = $regex_item->{pattern};
            if ($regex_item->{case_sensitive})
            {
                push @{$self->{_regexs}}, qr/${pattern}/;
            }
            else
            {
                push @{$self->{_regexs}}, qr/${pattern}/i;
            }
            push @{$self->{_regex_match_index}}, $regex_item->{match_index};
        }
    }
    else
    {
        my ($regex_patterns, $match_index) = 
            _build_regex_patterns();
        $self->{_regex_match_index} = $match_index;

        # No option to ignore case for the xNy match.
        push @{$self->{_regexs}}, qr/$regex_patterns->[0]/;
        shift @$regex_patterns; 

        # Compile the regular expressions, and set appropriate flags
        foreach my $regex_pattern (@{$regex_patterns})
        {
            if ($self->{ignorecase})
            {
                push @{$self->{_regexs}}, qr/${regex_pattern}/i;
            }
            else
            {
                push @{$self->{_regexs}}, qr/$regex_pattern/;
            }
        }
    }

    return $self;
}

# Function: _build_regex_patterns
# Return values:
#    1. \@patterns is a reference to an array of patterns to evaluate
#       in order.
#    2. \@match_index is a reference to an array of mappings from
#       the points of interest in an an identified mutation to the
#       match variables (e.g., $2, $7) that will hold them.
#
sub _build_regex_patterns
{
    # What follows here is a bit of a hack. Perl does support named match 
    # variables in a way, but the perlre page issues the following "WARNING":
    #
    #    This extended regular expression feature is considered 
    #    highly experimental, and may be changed or deleted without notice.
    # 
    # Thus, this kludge.

    # single-letter abbreviation xNy (note: N must be greater than 9)
    my $one_letter_pattern =
        $allowed_prefixes .
        $single_wt_res_match .
        $position_match .
        $single_mut_res_match .
        $allowed_suffixes;
    my %one_letter_match_index =
    (
        wt_res  => 2,
        pos     => 3,
        mut_res => 4
    );

    # match arrow notations (w N --> m variations)
    my $arrow_pattern =
        $allowed_prefixes .
        $wt_res_match. 
        '\s*'.
        $position_match .
        '\s*-{,2}>\s*' .
        $mut_res_match .
        $allowed_suffixes;
    my %arrow_match_index = %one_letter_match_index;

    # match three-letter notations xxxNyyy (note: N > 9)
    my $three_letter_pattern =
        $allowed_prefixes .
        $triple_wt_res_match .
        $position_match .
        $triple_mut_res_match .
        $allowed_suffixes;
    my %three_letter_match_index = %one_letter_match_index;
    
    # match textual descriptions (w N to m variations)
    my $text_wNm_pattern =
        $allowed_prefixes .
        $wt_res_match .
        '\s*\-?\(?' .
        $position_match .
        '\)?' .
        $replace_word_match .
        $mut_res_match .
        $allowed_suffixes;
    # The $replace_word_match introduces 7 left parentheses, shifting the
    # match variable to $11 for the mut_res.
    my %text_wNm_match_index =
    (
        wt_res  => 2,
        pos     => 3,
        mut_res => 11
    );

    # match textual descriptions (w to m at N variations)
    my $text_wmN_pattern =
        $allowed_prefixes .
        $wt_res_match .
        $replace_word_match .
        $mut_res_match .
        $position_word_match .
        $position_match .
        $allowed_suffixes;
    # The $replace_word_match introduces 7 left parentheses, shifting the
    # match variable to $9 for the mut_res. The $position_word_match has
    # three left parentheses, making pos appear at $12.
    my %text_wmN_match_index =
    (
        wt_res  => 2,
        pos     => 13,
        mut_res => 10 
    );

    # xNy formats (one-letter and three-letter abbreviations)
    my @pattern = 
    (
        $one_letter_pattern,
        $arrow_pattern,
        $three_letter_pattern,
        $text_wNm_pattern,
        $text_wmN_pattern
    );
    my @match_index = 
    (
        \%one_letter_match_index,
        \%arrow_match_index,
        \%three_letter_match_index,
        \%text_wNm_match_index,
        \%text_wmN_match_index
    );

    return (\@pattern, \@match_index);
}

sub _build_regex_patterns_from_file
{
    my ($regex_file) = @_;

    my @regex_from_file;
    if (ref $regex_file)
    {
        # We have an array reference and not an actual file.
        @regex_from_file = @$regex_file;
    }
    else
    { 
        open REGEX_FILE, "< $regex_file" or die "Bad open: $regex_file";

        foreach my $line (<REGEX_FILE>)
        {
            # chomp $line;
            $line =~ s/\s+$//;
            next if $line =~ /^#/;
            next if $line =~ /^\s*$/;
            push @regex_from_file, $line;
        }
    }

    my @regex = (); # An array of hashes, with one hash describing each regex.

    foreach my $regex (@regex_from_file)
    {
        my %regex = ();
        my $case_sensitive = FALSE;
        my $filtered_regex = '';
        my $open_paren_index = 0;
        my @field = split /\(/, $regex;
        my %match_index = 
        (
            wt_res => 0,
            mut_res => 0,
            pos => 0
        );

        my $field_index = 0;
        FIELD:
        foreach my $field (@field)
        {
            if ($field =~ s/\?P<(wt_res|mut_res|pos)>//)
            {
                $match_index{$1} = $open_paren_index;
            }
            if ($field =~ s/\[CASE_SENSITIVE\]//)
            {
                $case_sensitive = TRUE;
            }

            $filtered_regex .= $field . '(';

            if (($field_index > 0) and ($field[$field_index - 1] =~ m=\\$=))
            {
                $field_index++;
                # The open parenthesis was escaped, so we don't count it.
                next FIELD;
            }

            $field_index++;
            $open_paren_index++;
        }

        $filtered_regex =~ s/\($//;

        foreach my $key (keys %match_index)
        {
            die "Missing $key value in regex:\n\n\t$regex"
                if not $match_index{$key};
        }

# print "FILTY: $filtered_regex\n";
        $regex{pattern} = $filtered_regex;
        $regex{match_index} = \%match_index;
        $regex{case_sensitive} = $case_sensitive;
# print Dumper \%regex;
        push @regex, \%regex;
    }

    return \@regex;
}

#  Perform precision increasing post-processing steps
#
#  Remove false positives indicated by:
#      -> mutant and wild-type results are of the same type
#
sub _post_process($@)
{
    my ($self, @mention) = @_;
    return if not @mention;

    my @valid_mention;
    foreach my $mut_mention (@mention)
    {
        my $mutation = $mut_mention->mutation();
        if ($mutation->wt_residue() ne $mutation->mut_residue())
        {
            push @valid_mention, $mut_mention;
        }
    }

    return @valid_mention; 
}

#  Extract point mutations mentions from raw_text and return them in an array
#
#    raw_text: a string of text
#
#   The result of this method is a hash mapping PointMutation objects to
#    a list of spans where they were identified. Spans are presented in the
#    form of character-offsets in text. If counts for each mention are
#    required instead of spans, apply len() to each value to convert the
#    list of spans to a count.
#
#   Example result:
#    raw_text: 'We constructed A42G and L22G, and crystalized A42G.'
#    result = {PointMutation(42,'A','G'):[(15,19),(46,50)],
#              PointMutation(22,'L','G'):[(24,28)]}
#
#    Note that the spans won't necessarily be in increasing order, due
#     to the order of processing regular expressions.
#
sub call
{
    my ($self, $raw_text) = @_;

    my @result = ();
    my $regex_index = 0;
    foreach my $regex (@{$self->{_regexs}})
    {
        while ($raw_text =~ m/$regex/g)
        {
            my $match = 
                $self->{_regex_match_index}->[$regex_index];
            my $finding = $self->get_point_mention_data($match);
            push @result, $finding;  
        }
        $regex_index++;
    }
                     
    @result = $self->_post_process(@result);
    return @result;
}


1;

__END__
=pod

=head1 NAME

MutationFinder::MutationFinder - MutationExtractor based on Caporaso et al. method.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

    use MutationFinder::MutationFinder;
    use MutationFinder::Mention;

    my $Mf = new MutationFinder::MutationFinder(
        {regex_file => '/tmp/regex.txt'});
    my %doc = $Mf->extract_mutations_from_lines_to_hash('/tmp/file.txt');
    $Mf->extract_mutations_from_lines_to_file('/tmp/file.txt', '/tmp/file.txt.mf');

    my @line =
    (
        "id1\tMutate Arg at position 12 to Glycine. This is noteworthy.",
        "id2\tThe G47S mutation caused the hydrophilic region to be exposed."
    );
    my @extraction = $Mf->extract_mutations_from_lines(\@line);
    foreach my $extract (@extraction)
    {
        print $extract->id(), "\n";
        while my $ment ($extract->next())
        {
            print $ment->mutation->str(), ":" , $ment->mutation->span_begin(),
                "," $ment->mutation->span_end() , "\n";
        }
    }

=head1 DESCRIPTION

This class provides methods to implement the mutation-extraction method 
described by Caporaso et al. Most of its functionality is derived from
the MutationFinder::MutationExtractor base class. See the perldoc from
this class for more details.

=head1 METHODS

=head2 PACKAGE->new([HASHREF])

Construct a new MutationFinder object. All settings for the base class 
MutationFinder::MutationExtractor are valid. The following options are
also available through the HASHREF argument:

=over

=item *

regex_file => SCALAR|ARRAYREF

This may be a string containing the path to the regular-expresssion file to use
or it may be a reference to an array that contains the regular expressions.

=item *

ignorecase => TRUE|FALSE

Indicate if the distinction between upper and lowercase letters should be
ignored when searching for mutation mentions. Note that ignoring case will
improve recall at the expense of precision. The default is TRUE.

=back

=head2 $OBJ->call(SCALAR)

Given a string of raw text, returns an array of Mention objects representing
the point mutation mentions present in the text.

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=back

=cut
