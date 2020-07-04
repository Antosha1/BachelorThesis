package MutationFinder::Mention;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
#
# Author: David Randolph (rndlph@users.sourceforge.net).
# File created on 5 July 2007.
################

use strict;
use Data::Dumper;
use base 'MutationFinder::Object';
use MutationFinder::Mutation;
use MutationFinder::Constant;

    
################
# The Mention object
# 
# Mention is a class for different types of mutation mentions. 
################

sub new 
{
    my ($class, $opt) = @_;
    my $self = $class->SUPER::new($opt);

    die "Mutation must be specified"
        if not defined $opt->{mutation};
    die "Mutation is not a mutation" 
        if not $opt->{mutation}->isa("MutationFinder::Mutation");

    my $self =
    {
        _mutation => $opt->{mutation},
    };

    bless $self, $class;

    if (defined $opt->{span})
    {
        $self->span_begin($opt->{span}->[0]);
        $self->span_end($opt->{span}->[1]);
    }

    if (defined $opt->{span_begin})
    {
        $self->span_begin($opt->{span_begin});
    }

    if (defined $opt->{span_end})
    {
        $self->span_end($opt->{span_end});
    }

    return $self;
}

sub mutation
{
    my ($self, $setting) = @_;

    if (not defined $setting)
    {
        return $self->{_mutation};
    }

    $self->{_mutation} = $setting;
}

sub span
{
    my ($self, $setting) = @_;

    if (not defined $setting)
    {
        my @result;
        $result[0] = $self->span_begin();
        $result[1] = $self->span_end();
        return \@result;
    }

    die "Bad span specified" 
       if not defined $setting->[0] or not defined $setting->[1];
}

sub span_begin
{
    my ($self, $setting) = @_;

    if (not defined $setting)
    {
        return undef if not defined $self->{_span_begin};
        return $self->{_span_begin};
    }

    die "Nonumeric span begin specified: $setting"
       if not $setting =~ /^\d+$/;

    if (defined $self->{_span_end} and $self->{_span_end} <= $setting)
    {
        die "Starting position of span must be less than ending position";
    }
    
    $self->{_span_begin} = $setting;
}

sub span_end
{
    my ($self, $setting) = @_;

    if (not defined $setting)
    {
        return undef if not defined $self->{_span_end};
        return $self->{_span_end};
    }

    die "Nonumeric span end specified: $setting"
       if not $setting =~ /^\d+$/;

    if (defined $self->{_span_begin} and $self->{_span_begin} >= $setting)
    {
        die "Ending position of span must be greater than starting position";
    }
    
    $self->{_span_end} = $setting;
}

sub eq_spans
{
    my ($self, $other) = @_;
# my $dump = Dumper($self) . Dumper($other);
# die $dump;

    if ( (not defined $self->span and not defined $other->span) or
         ($self->span_begin == $other->span_begin and 
          $self->span_end == $other->span_end) )
    {
        return TRUE;
    }

    return FALSE;
}

sub eq_mutations
{
    my ($self, $other) = @_;

    my $my_mut = $self->mutation;
    my $other_mut = $other->mutation;

    return $my_mut->eq($other_mut);
}

sub eq
{
    my ($self, $other) = @_;

    if ($self->eq_mutations($other) and $self->eq_spans($other))
    {
        return TRUE;
    }

    return FALSE;
}

1;

__END__
=pod

=head1 NAME

MutationFinder::Mention - Class to represent a mutation mention in text.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

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

    print "will not see" if $Ment1_1->eq($Ment1_3);
    print "will not see" if $Ment1_1->eq($Ment2_1);
    print "will see" if $Ment1_1->eq($Ment1_2);
    print "will see" if $Ment1_1->eq_spans($Ment2_1);
    print "will see" if $Ment1_1->span_begin() == 12;
    print "will see" if $Ment1_1->span_end() == 20;

=head1 DESCRIPTION

This class provides methods to store mutation mention data 
and retrieve properties of same.

=head1 METHODS

=head2 PACKAGE->new(HASHREF)

Construct the Mention object. The hash must include a "mutation" key 
that maps to a valid Mutation object reference. The following hash elements
are optional:

=over

=item *

span => [$BEGIN, $END]

=item *

span_begin => SCALAR

=item *

span_end => SCALAR

=back

=head2 $OBJ->eq($Mention)

Method to determine if this Mention is equivalent to another.
Returns TRUE if they are equal and FALSE otherwise.
Equivalent mentions have the same Mutation and span settings.

=head2 $OBJ->eq_mutations($Mention)

Method to determine if this Mention's associated Mutation is the
same as that of another. Returns TRUE if they are equal and FALSE 
otherwise.

=head2 $OBJ->eq_spans($Mention)

Method to determine if this Mention's spans are the same as 
those of another.  Returns TRUE if they are equal and FALSE otherwise.

=head2 $OBJ->mutation($Mutation)

If no argument is provided, return the Mutation associated 
with the Mention. If a Mutation argument is provided,
associate the Mention with this Mutation.

=head2 $OBJ->span([ARRAYREF])

If no argument is provided, return a reference to an array with two
integer elements. Element 0 is the span_begin location, and element
1 is the span_end location. If a reference to an array like this is
provided, set the span for the Mention accordingly.

=head2 $OBJ->span_begin()

The offset from the beginning of the document where the Mention occurs.

=head2 $OBJ->span_end()

The offset from the end of the document where the Mention occurs.

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=back

=cut
