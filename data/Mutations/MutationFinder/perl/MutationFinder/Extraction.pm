package MutationFinder::Extraction;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
#
# Author: David Randolph (rndlph@users.sourceforge.net).
# File created on 12 July 2007.

use strict;
use Data::Dumper;
use base 'MutationFinder::Object';
use MutationFinder::Constant;
use MutationFinder::Mention;
use MutationFinder::Mutation;

    
################
# The Extraction object
# 
# Extraction is an object to store document records.
################

sub new 
{
    my ($class, $opt) = @_;
    my $self = $class->SUPER::new($opt);

    die "ID must be specified"
        if not defined $opt->{id};

    bless $self, $class;

    $self->id($opt->{id});

    $self->{_mention_index} = 0;
    $self->{_mutation_index} = 0;
    $self->{_debug} = FALSE;

    $self->{_mentions} = [];
    $self->{_mutations} = [];

    # Order by span_begin, span_end, or by order found if no spans available.
    $self->{_ordered_mentions} = []; 

    if (defined $opt->{mentions})
    {
        $self->mentions($opt->{mentions});
    }
 
    return $self;
}

sub add_mention
{
    my ($self, $ment) = @_;

    die "No mention" if not defined $ment;
    die "Bad mention" if not $ment->isa("MutationFinder::Mention");

    push @{$self->{_mentions}}, $ment;

    if (not @{$self->{_ordered_mentions}} or not $ment->span())
    {
        push @{$self->{_ordered_mentions}}, $ment;
    }
    else
    {
        # We insert the mention into the sorted array in the correct place.
        my $preceding_index;
        for (my $i = 0; $i < scalar @{$self->{_ordered_mentions}}; $i++)
        {
            if ($ment->span_begin < $self->{_ordered_mentions}->[$i]->span_begin)
            {
                $preceding_index = $i;
                last;
            }  
            elsif ($ment->span_begin == $self->{_ordered_mentions}->[$i]->span_begin)
            {
                if ($ment->span_end < $self->{_ordered_mentions}->[$i]->span_end)
                {
                    $preceding_index = $i;
                    last;
                }
            }  
        }

        if (not defined $preceding_index)
        {
            push @{$self->{_ordered_mentions}}, $ment;
        }
        else
        {
            splice(@{$self->{_ordered_mentions}}, $preceding_index, 0, $ment);
        }
    }

    my $mut = $ment->mutation;
    $self->_add_mutation($mut);
}

sub _add_mutation
{
    my ($self, $mut) = @_;
    foreach my $old_mut (@{$self->{_mutations}})
    {
        if ($old_mut->eq($mut))
        {
            return; # Already know about this one.
        }
    }
    push @{$self->{_mutations}}, $mut;
}

sub id
{
    my ($self, $setting) = @_;

    if (not defined $setting)
    {
        return $self->{_id};
    }

    die "ID must be a scalar" if ref $setting;

    $self->{_id} = $setting;
}

sub mentions
{
    my ($self, $setting) = @_;

    if (not defined $setting)
    {
        return @{$self->{_mentions}};
    }
    die "The mention reference must be an ARRAY reference"
        if (ref $setting ne 'ARRAY');
    foreach my $ment (@$setting)
    { 
        $self->add_mention($ment);
    }
}

sub ordered_mentions
{
    my ($self) = @_;

    return @{$self->{_ordered_mentions}};
}

sub spans
{
    my ($self, $mutation) = @_;

    my @span;
    
    foreach my $ment (@{$self->{_ordered_mentions}})
    {
        if ($mutation->eq($ment->mutation) and defined $ment->span)
        {
            push @span, $ment->span;
        }
    }

    return @span;
}

sub next
{
    my ($self) = @_;
    my $index = $self->{_mention_index};
    if (not defined $self->{_mentions}[$index])
    {
        $self->{_mention_index} = 0;
        return undef;
    }

    $self->{_mention_index}++;
    return $self->{_ordered_mentions}[$index];
}

sub next_mention
{
    my ($self) = @_;
    return $self->next();
}

sub next_found_mention
{
    my ($self) = @_;
    my $index = $self->{_mention_index};
    if (not defined $self->{_mentions}[$index])
    {
        $self->{_mention_index} = 0;
        return undef;
    }

    $self->{_mention_index}++;
    return $self->{_mentions}[$index];
}

sub next_mutation
{
    my ($self) = @_;
    my $index = $self->{_mutation_index};
    if (not defined $self->{_mutations}[$index])
    {
        $self->{_mutation_index} = 0;
        return undef;
    }

    $self->{_mutation_index}++;
    return $self->{_mutations}[$index];
}

sub reset
{
    my ($self) = @_;
    $self->{_cursor_index} = 0;
}

sub eq_normalized 
{
    my ($self, $other) = @_;  

    my $my_count = $self->normalized_count();
    my $other_count = $other->normalized_count();
    if ($my_count != $other_count)
    {
        print STDERR "Extraction records are not normal-equal: Mutation counts do not match"
            if $self->{_debug};
        return FALSE;
    }

    my @own_mut  = $self->normalized_mutations();
    my @other_mut = $other->normalized_mutations();

    # If any mutation in this extraction is not present in the other,
    # the two are not normal-equal.
    foreach my $own (@own_mut)
    {
        my $found_it = FALSE;
        OTHER:
        foreach my $other (@other_mut)
        {
            if ($own->eq($other))
            {
                $found_it = TRUE;
                last OTHER;
            }
        }
        if (not $found_it)
        {
            print STDERR "Extraction records are not normal-equal: Mutations do not match"
                if $self->{_debug};
            return FALSE;
        }
    }

    return TRUE;
}

sub ne_normalized
{
    my ($self, $other) = @_;  
    return not $self->eq_normalized($other);
}

sub mention_count
{
    my ($self) = @_;  
    my $count = scalar @{$self->{_mentions}};
    return $count;
}

sub normalized_count
{
    my ($self) = @_;  
    my $count = scalar @{$self->{_mutations}};
    return $count;
}

sub normalized_mutations
{
    my ($self) = @_;  
    return @{$self->{_mutations}};
}

sub eq
{
    my ($self, $other) = @_;  
    return ($self->eq_id($other) and $self->eq_mentions($other));
}

sub eq_id
{
    my ($self, $other) = @_;  

    if ($self->id() ne $other->id())
    {
        print STDERR "Extraction records are not equal: IDs do not match"
            if $self->{_debug};
        return FALSE;
    }

    return TRUE;
}

sub ne_id
{
    my ($self, $other) = @_;  
    return not $self->eq_id($other);
}

sub eq_mentions
{
    my ($self, $other) = @_;  

    return TRUE if not $self->mention_count() and 
        not $other->mention_count();

    if ( (not $self->mention_count and $other->mention_count) or
         (not $other->mention_count and $self->mention_count) )
    {
# my $data = $self->mention_count . "/" . $other->mention_count . "\n" .
# Dumper($self) . Dumper($other);
# die $data;
        die "Extraction records are not equal: mention counts do not match";
        print STDERR "Extraction records are not equal: mention counts do not match"
            if $self->{_debug};
        return FALSE;
    }

    my $index = 0;
    my @other_mention = $other->ordered_mentions;

    foreach my $mine (@{$self->{_ordered_mentions}})
    {
        if (not $mine->eq($other_mention[$index]))
        {
            print STDERR "Extraction records are not equal: mentions do not match"
                if $self->{_debug};
            return FALSE;
        }

        $index++;
    }

    return TRUE;
}

sub ne_mentions
{
    my ($self, $other) = @_;  
    return not $self->eq_mentions($other);
}

1;

__END__
=pod

=head1 NAME

MutationFinder::Extraction - Class to store mutation extractions for a given document.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

    use MutationFinder::Extraction;
    use MutationFinder::Mutation;
    use MutationFinder::Mention;

    $Pm1 = new MutationFinder::PointMutation(
        {position => 64, wild => 'A', mut => 'G'});
    $Pm2 = new MutationFinder::PointMutation({wNm => 'W42A'});

    $Ment1_1 = new MutationFinder::Mention(
        {mutation => $Pm1, span => [12, 20]});
    $Ment1_2 = new MutationFinder::Mention(
        {mutation => $Pm1, span_begin => 12, span_end => 20});
    $Ment1_3 = new MutationFinder::Mention(
        {mutation => $Pm1, span_begin => 97, span_end => 115});
    $Ment2_1 = new MutationFinder::Mention(
        {mutation => $Pm2, span => [12, 20]});
    $Ment2_2 = new MutationFinder::Mention(
        {mutation => $Pm2, span => [512, 520]});

    $Ext1_1 = new MutationFinder::Extraction(
        {id => 'one', mentions => [$Ment1_1, $Ment1_3]});
    $Ext1_2 = new MutationFinder::Extraction(
        {id => 'one', mentions => [$Ment1_1, $Ment1_3]});
    $Ext2_1 = new MutationFinder::Extraction(
        {id => 'two', mentions => [$Ment1_1, $Ment1_3]});
    $Ext2_2 = new MutationFinder::Extraction(
        {id => 'two', mentions => [$Ment2_1, $Ment1_3]});

    print "will not see" if $Ext1_1->eq($Ext1_3);
    print "will not see" if $Ext1_1->eq_id($Ext2_1);
    print "will see" if $Ext1_1->eq($Ext1_2);
    print "will see" if $Ext1_1->eq_mentions($Ext2_1);

    $Ext2_1->add_mention($Ment1_2);
    print "will see" if $Ext1_1->eq_normalized($Ext2_1);

    while (my $ment = $Ext2_1->next())
    {
        print $ment->mutation->str(), "\n";
    }

    while (my $mut = $Ext2_1->next_mutation())
    {
        print $mut->str(), "\n";
    }

=head1 DESCRIPTION

This class stores mutation extraction data and provides methods 
for retrieving these data.

=head1 METHODS

=head2 PACKAGE->new(HASHREF)

Construct the Extraction object. The hash must include an 
"id" string element to identify the document associated with the Extraction.

=head2 $OBJ->add_mention($Mention)

Adds the specified Mention object to the Extraction.

=head2 $OBJ->eq($Extraction)

Determines if this Extraction is equivalent to another. Returns 
TRUE if Extractions are equal and FALSE otherwise. Equal Extractions 
have the same document IDs and Mentions.

=head2 $OBJ->eq_id($Extraction)

Determines if this Extraction is from the same document as another.
Returns TRUE if document IDs are equal and FALSE otherwise. 

=head2 $OBJ->eq_mentions($Extraction)

Determines if this Extraction contains the same Mentions as another.
Returns TRUE if the Mentions are identical and FALSE otherwise. 

=head2 $OBJ->eq_normalized($Extraction)

Determines if this Extraction contains the same normalized Mutations as another.
Returns TRUE if the Mutations are identical and FALSE otherwise. 

=head2 $OBJ->id([SCALAR])

If string argument is specified, set the document ID for the Extraction.
If no argument is provided, return the string ID of the document associated
with the Extraction.

=head2 $OBJ->mention_count()

Returns the number of mentions stored in the Extraction.

=head2 $OBJ->mentions([ARRAYREF])

If no argument specified, return the array of Mentions associated with this Extraction.
If an array of Mentions is specified, associate this Extraction object with the
Mention array.

=head2 $OBJ->ne($Extraction)

Determines if this Extraction is not equivalent to another. Returns 
TRUE if Extractions are not equal and FALSE otherwise. Equal Extractions 
have the same document IDs and Mentions.

=head2 $OBJ->ne_id($Extraction)

Determines if this Extraction is not from the same document as another.
Returns FALSE if document IDs are equal and TRUE otherwise. 

=head2 $OBJ->ne_mentions($Extraction)

Determines if this Extraction contains different Mentions than another.
Returns FALSE if the Mentions are identical and TRUE otherwise. 

=head2 $OBJ->ne_normalized($Extraction)

Determines if this Extraction contains different normalized Mutations as another.
Returns FALSE if the Mutations are identical and TRUE otherwise. 

=head2 $OBJ->next()

Returns the next mention (ordered by its position in the document) stored in
the Extraction. Returns undef and resets the cursor position to the beginning
after the last Mention is returned.

=head2 $OBJ->next_mention()

Returns the next mention (ordered by its position in the document 
if possible) stored in the Extraction. If the MutationExtractor does
not support spans, the Mutations are returned in the order in which 
they were reported to the Extraction object.

=head2 $OBJ->next_found_mention()

Returns the next Mention stored in the Extraction in the order in which 
they were reported to the Extraction object (i.e., "found" by the MutationExtractor).

=head2 $OBJ->next_mutation()

Returns the next mutation (ordered by its first appearance in the document) stored in
the Extraction. If the MutationExtractor does not support spans, the mutations are
returned in the order in which they were reported to the Extraction object.

=head2 $OBJ->normalized_count()

Returns the number of normalized mutations stored in this Extraction.

=head2 $OBJ->ordered_mentions()

Returns an array of Mention objects in the order in which they were
reported to the Extraction object (not the order in which they appear in 
the document).

=head2 $OBJ->reset()

Resets the cursor for the B<next*()> methods to the beginning.

=head2 $OBJ->spans($Mutation)

Returns an array of [span_begin, span_end] array references representing the 
different span location ideintified in the Extraction for the given $Mutation.

=head1 AUTHOR

=over

=item David Randolph

=item Creg Caporaso

=back

=cut
