package MutationFinder::MutationExtractor;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
#
# File created on 25 Jan 2007.
################

use strict;
use English;
use Data::Dumper;
use MutationFinder::PointMutation;
use MutationFinder::Constant;
use MutationFinder::Extraction;
use MutationFinder::Mention;

# A base class for extracting Mutations from text.
sub new
{
    my ($class, $opt) = @_;
    my $self = {};

    $self->{support_spans} = FALSE;
    $self->{report_spans} = FALSE;
    $self->{report_verbose} = TRUE;
    $self->{report_normalized} = FALSE;

    foreach my $key ('support_spans', 'report_spans',
        'report_verbose', 'report_normalized')
    {
        $self->{$key} = $opt->{$key} if defined $opt->{$key};
    }

    # FIXME: Is this really necessary? Shouldn't the normalized option simply
    # take precedence over the spans?
    die "The report_spans and report_normalized options are incompatible"
        if $self->{report_spans} and $self->{report_normalized};

    die "The MutationExtractor does not support spans"
        if not $opt->{support_spans} and $opt->{report_spans};
 
    bless $self, $class;

    return $self;
}

sub support_spans
{
    my ($self) = @_;
    return $self->{report_spans};
}

sub report_spans
{
    my ($self, $setting) = @_;
    return $self->{report_spans} if not defined $setting;
    die "The " . ref($self) . " class does not support spans"
        if $setting and not $self->{support_spans};
    die "The report_spans and report_normalized options are incompatible"
        if $setting and $self->{report_normalized};
    $self->{report_spans} = $setting;
}

sub report_verbose
{
    my ($self, $setting) = @_;
    return $self->{report_verbose} if not defined $setting;
    $self->{report_verbose} = $setting;
}

sub report_normalized
{
    my ($self, $setting) = @_;
    return $self->{report_normalized} if not defined $setting;
    $self->{report_normalized} = $setting;
    die "The report_spans and report_normalized options are incompatible"
        if $self->{report_spans} and $self->{report_normalized};
}

sub get_point_mention_data
{
    my ($self, $match) = @_;

    my $wt_res = eval "\$$match->{wt_res}";
    my $pos = eval "\$$match->{pos}";
    my $mut_res = eval "\$$match->{mut_res}";
    my $current_mutation = new MutationFinder::PointMutation(
        {position => $pos, wild => $wt_res, mut => $mut_res});
    my $start = _get_min($LAST_MATCH_START[$match->{wt_res}],
         $LAST_MATCH_START[$match->{mut_res}],
         $LAST_MATCH_START[$match->{pos}]);
    my $fin = _get_max($LAST_MATCH_END[$match->{wt_res}],
         $LAST_MATCH_END[$match->{mut_res}],
         $LAST_MATCH_END[$match->{pos}]);

    my @span = ($start, $fin);

    my $mention = new MutationFinder::Mention(
        {mutation => $current_mutation, span => \@span});

    return $mention;
}

sub _get_min
{
    my (@val) = @_;
    my @sorted_val = sort {$a <=> $b} @val;
    return $sorted_val[0];
}

sub _get_max
{
    my (@val) = @_;
    my @sorted_val = reverse sort {$a <=> $b} @val;
    return $sorted_val[0];
}

sub extract_mutations_from_lines
{
    my ($self, $lines) = @_;
    my @result;
    foreach my $line (@$lines)
    {
        my $id;
        push @result, $self->get_extraction_for_line($line);
    }

# my $data = Dumper \@result;
# die $data;
    return @result;
}

sub get_extraction_for_line
{
    my ($self, $line) = @_;
    
    my ($id, $str);
    if ($line =~ /^([^\t]+)/)
    {
        $id = $1;
    }
    else
    {
        return undef;
    }

    if ($line =~ /^[^\t]+\t(.*)/)
    {
        $str = $1;
    }
    else
    {
        my $record = new MutationFinder::Extraction({id => $id});
        return $record;
    }

    my @result = $self->call($str);
    my $extraction = new MutationFinder::Extraction(
        {id => $id, mentions => \@result});

    return $extraction;
}

sub get_output_for_line
{
    my ($self, $line) = @_;
    my $extraction = $self->get_extraction_for_line($line);
    my $output = $extraction->id();

    if ($self->report_normalized)
    {
        while (my $mutation = $extraction->next_mutation())
        {
            $output .= "\t" . $mutation->str();
        }
    }
    else
    {
        while (my $mention = $extraction->next())
        {
            next if not $mention->mutation();
            my $identifier = $mention->mutation()->str();
            if ($self->{report_spans})
            {
                if (not $self->support_spans())
                {
                    die 'Attempting to access spans from a MutationExtractor ' .
                        'which cannot store them';
                }
                
                $identifier .= ":" . $mention->span_begin .
                    ',' . $mention->span_end;
            }
            $output .= "\t$identifier";
        }
    }

    $output .= "\n";
    return $output;
}

#-------------------------------------------------------------------------------
#   This function extracts mutations from an iterable object
#   containing the lines of a file (i.e. either an array or file object)
#   and writes the mutations to an output file. The text span (in
#   character offset) can also be recorded for each mutation mention,
#   if the MutationExtractor supports storing spans. Currently
#   BaselineMutationExtractor does not support spans, while
#   MutationFinder does.
#
#   input_file: a file in which each item is a tab-delimited
#       string where the first field is a unique identifier and the
#       remaining fields comprise a single text source;
#       this will be a file or list.
#   output_file: the file path where the output should be written
#-------------------------------------------------------------------------------
sub extract_mutations_from_lines_to_file
{
    my ($self, $input_file, $output_file) = @_;

    if ($output_file and -f $output_file)
    {
        die "Output file already exists: ${output_file}.\n" .
            "Please either rename or move the existing file.";
    }

    open OUTFILE, ">> $output_file"
        or die "Could not open the output file for writing: $output_file";

    if (not ref $input_file)
    {
        open INFILE, "< $input_file"
            or die "Cannot open specified input file: $input_file";

        foreach my $line (<INFILE>)
        {
            print OUTFILE $self->get_output_for_line($line);
        }

        close INFILE or die "Could not close output file: $input_file";
    } 
    else
    {    
        foreach my $line (@$input_file)
        {
            print OUTFILE $self->get_output_for_line($line);
        }
    }

    close OUTFILE or die "Could not close output file: $output_file";
}


#-------------------------------------------------------------------------------
# Produces a hash table mapping record identifiers to a reference to an array
# of mutation mention records.
#-------------------------------------------------------------------------------
sub extract_mutations_from_lines_to_hash
{
    my ($self, $input_file) = @_;

    return $self->extract_mutations_from_lines_to_dict($input_file);
}

sub extract_mutations_from_lines_to_dict
{
    my ($self, $input_file) = @_;

    my @record;
    my %dict;
    if (not ref $input_file)
    {
        open INFILE, "< $input_file"
            or die "Cannot open specified input file: $input_file";

        foreach my $line (<INFILE>)
        {
            push @record, $self->get_extraction_for_line($line);
        }

        close INFILE or die "Could not close input file: $input_file";
    } 
    else
    {    
        foreach my $line (@$input_file)
        {
            push @record, $self->get_extraction_for_line($line);
        }
    }
   
    foreach my $extraction (@record)
    {
        my $id = $extraction->id;
        my @ment = ();
        while (my $ment = $extraction->next())
        {
            push @ment, $ment;
        }
        $dict{$id} = \@ment;
    } 

    return %dict;
}

sub call
{
    die "call() must be implemented by the derived class";
}


# Applies mutation_extractor to text and return the mutations in a dict
# 
# text: a single string containing the text which mutations should be
#    extracted from
sub extract_mutations_from_string
{
    my ($self, $text) = @_;
    return $self->call($text);
}

1;

__END__
=pod

=head1 NAME

MutationFinder::MutationExtractor - Virtual base class to extract mutation mentions from text.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

    use base 'MutationFinder::MutationExtractor';

    sub new
    {
        my ($class, $opt) = @_;
        $opt->{support_spans} = TRUE;
        my $self = $class->SUPER::new($opt);
        ....
    }


=head1 DESCRIPTION

This base class provides core methods to support mutation extraction.

=head1 METHODS

=head2 PACKAGE->new([HASHREF])

Construct a new MutationExtractor. The following options may be passed in
with the HASHREF argument:

=over

=item *

support_spans => TRUE|FALSE

Indicate if the derived class supports spans. Defaults to FALSE.

=item *
 
report_spans => TRUE|FALSE

Indicate if any generated reports should include span information. Defaults to FALSE.
Note that both report_spans and report_normalized cannot both be TRUE.

=item *

report_verbose => TRUE|FALSE

Indicate if each Mention should be reported separately. Defaults to TRUE.

=item *

report_normalized => TRUE|FALSE

Indicate if each normalized Mutations should be reported (instead of
Mentions). Defaults to FALSE. Note that both report_spans and
report_normalized cannot both be TRUE.

=back

=head2 $OBJ->call(SCALAR)

A virtual method. It must be implemented by the derived class.

=head2 $OBJ->extract_mutations_from_lines(ARRAYREF)

Returns an array of Extraction objects for the input array of
lines (or documents). Each input line must be properly formatted, beginning
with an identifying string and a tab, followed by the text to be processed.

=head2 $OBJ->extract_mutations_from_lines_to_dict(SCALAR|ARRAYREF)

The argument may be a string that contains the path to an input
file or a reference to an array of lines. 

Returns a hash table mapping each document identifier to a reference
to an array of Mention objects (or to an empty array if no Mentions are
found).

Each input line must be properly formatted, beginning with an identifying
string and a tab, followed by the text to be processed.

=head2 $OBJ->extract_mutations_from_lines_to_file(SCALAR|ARRAYREF, SCALAR)

The first argument may be a string that contains the path to an input
file or a reference to an array of lines. The second argument must be a string
containing the path to use for the output. 

Writes report output according to the configuraion of the MutationExtractor
object to a specified file, processing the specified input file or array.
Each input line must be properly formatted, beginning with an identifying
string and a tab, followed by the text to be processed.

=head2 $OBJ->extract_mutations_from_lines_to_hash(SCALAR|ARRAYREF)

A synonym for $OBJ->extract_mutations_from_lines_to_dict(SCALAR|ARRAYREF).
(A "dict" is a Python term. It is essentially the same thing as a Perl
hash table.)

=head2 $OBJ->extract_mutations_from_string(SCALAR)

A wrapper to the $OBJ->call(SCALAR) method, which must be implemented
by the derived class. Method must return an array of Mention objects
found in the SCALAR text input.

=head2 $OBJ->get_extraction_for_line(SCALAR)

Returns an Extraction object for the input line (or document).
The input line must be properly formatted, beginning
with an identifying string and a tab, followed by the text to be processed.
This is the standard format for input file lines for MutationFinder.

=head2 $OBJ->get_output_for_line(SCALAR)

Returns a string summarizing the Extraction made for the input
line (or document). The input line must be properly formatted, beginning
with an identifying string and a tab, followed by the text to be processed.

=head2 $OBJ->get_point_mention_data(HASHREF)

Return a Mention object given a HASHREF that indicates which standard
pattern-matching variables (e.g., $1, $2) store the various parts of the 
mutation mention. This function must be called immediately after a regular
expression is evaluated to ensure that the standard variable are populated
with the correct data. This is handled this way because Perl does not
currently support named match variables, and we are naming the variables
in our defined regular expressions. The location (spans) of each mention
are also determined here.

The hash table takes the following form:

    %match_index =
    (
        'wt_res' => 1,
        'pos' => 2,
        'mut_res' => 3
    );

For examples of how to use this method, see the 
MutationFinder::MutationFinder class.

=head2 $OBJ->report_normalized([SCALAR])

If no Boolean argument specified, return Boolean to indicate if normalized
mutations should be included in any reports. If Boolean argument is specified, set 
the report_normalized behavior accordingly.

=head2 $OBJ->report_spans([SCALAR])

If no Boolean argument specified, return Boolean to indicate if spans should
be included in any reports.  If Boolean argument is specified, set 
the report_spans behavior accordingly.

=head2 $OBJ->report_verbose([SCALAR])

If no Boolean argument specified, return Boolean to indicate if verbose
output is to be produced by this MutationExtractor. (Verbose output includes
separate output for each individual Mentions. Terse output includes an array
of spans associated with each Mutation.) If Boolean argument is specified, set 
the report_verbose behavior accordingly.

=head2 $OBJ->support_spans()

Return Boolean to indicate if derived class supports span locations of mentions. 

=head1 SEE ALSO

MutationFinder::Extraction, MutationFinder::Mention, MutationFinder::Mutation.

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=back

=cut
