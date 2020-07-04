package MutationFinder::Object;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: David Randolph (rndlph@users.sourceforge.net).
# File created on 12 July 2007.
################ 

use strict;
use Data::Dumper;
use MutationFinder::Constant;
use MutationFinder::Mention;

    
################
# The Object object
# 
# Base class for all MutationFinder objects.
################

sub new 
{
    my ($class, $opt) = @_;

    my $debug_setting = FALSE;
    $debug_setting = $opt->{debug} if defined $opt->{debug};
    my $self =
    {
        _debug => $debug_setting
    };

    bless $self, $class;

    return $self;
}

sub debug
{
    my ($self, $setting) = @_;
    return $self->{_debug} if not defined $setting;
    $self->{_debug} = ($setting) ? TRUE : FALSE;
}

sub print
{
    my ($self, $msg) = @_;

    print STDERR $msg if $self->debug;
}

sub dump
{
    my ($self) = @_;

    print STDERR Dumper($self) if $self->debug;
}

sub eq
{
    die "eq() must be defined by derived class";
}

sub ne 
{
    my ($self, $other) = @_;  
    return (not $self->eq($other));
}

1;

__END__
=pod

=head1 NAME

MutationFinder::Object - Virtual base class for objects that represent text and biological artifacts.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

Basic stuff.

=head1 DESCRIPTION

This base class provides core methods for Mutation, Mention, and Extraction objects.

=head1 METHODS

=head2 PACKAGE->new([HASHREF])

Optional "debug" field may be set to output additional debug information.

=head2 $OBJ->debug([SCALAR])

If no input SCALAR is specified, return the debug mode (TRUE or FALSE) of the Object.
If SCALAR is set to a value, the debug mode is set accordingly. 

=head2 $OBJ->dump()

Prints Data::Dumper representation of the Object to STDERR if in debug mode.

=head2 $OBJ->eq($Object)

Virtual method to be implemented by derived classes. Returns TRUE if Objects are
equal and FALSE otherwise.

=head2 $OBJ->ne($Object)

Returns FALSE if Objects are equal and TRUE otherwise. It is up to the derived
class to define equality.

=head2 $OBJ->print(SCALAR)

Prints SCALAR string argument to STDERR if debug mode is TRUE.

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=back

=cut
