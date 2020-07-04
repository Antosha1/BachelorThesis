package MutationFinder::Mutation;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
# File created on 25 Jan 2007.
################

use strict;
use base 'MutationFinder::Object';

    
################
# The Mutation object
# 
# Mutation is a base class for different types of mutations. Currently the
# only Mutation type defined is a PointMutation, but in the future Insertion
# and Deletion objects may also be defined. 
# 
################

# class Mutation(object):
# A base class for storing information about mutations.

sub new 
{
    my ($class, $opt) = @_;
    $opt = {} if not defined $opt;
    my $self = $class->SUPER::new($opt);

    # Position: the sequence position or start position of the mutation
    # (must be castable to an int).
    die "Position must be defined" if not defined $opt->{position};
    die "Position must be an integer" if not ($opt->{position} =~ /^\d+$/);
    die "Position must be greater than 0" if not $opt->{position};

    my $self =
    {
        _position => int $opt->{position}
    };
  
    bless $self, $class;
    return $self;
}
    
sub position($)
{
    my ($self) = @_;
    return $self->{_position};
}

sub str($)
{
    my ($self) = @_;
    die 'Mutation subclasses must override str()';
}

sub eq($$)
{
    my ($self, $other) = @_;
    die 'Mutation subclasses must override ==';
}

sub ne($$)
{
    my ($self, $other) = @_;
    die 'Mutation subclasses must override !=';
}

1;

__END__
=pod

=head1 NAME

MutationFinder::Mutation - Virtual base class to capture individual mutations.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

    use MutationFinder::Mutation;
    my $mut = new MutationFinder::Mutation({position => 42});

=head1 DESCRIPTION

This base class provides core methods to describe mutations.

=head1 METHODS

=head2 PACKAGE->new(HASHREF)

Construct the Mutation object. The hash must include an integer "position" element.

=head2 $OBJ->eq($Mutation)

Virtual method to determine if this Mutation is equivalent to another.
This method must be implemented by derived classes.

=head2 $OBJ->ne($Mutation)

Virtual method to determine if this Mutation is not equivalent to another.
This method must be implemented by derived classes.

=head2 $OBJ->position()

Returns the position of the Mutation object.

=head2 $OBJ->str()

Virtual method to return a string representation of the Mutation object. 
This method must be implemented by derived classes.

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=back

=cut
