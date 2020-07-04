package MutationFinder::PointMutation;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
# File created on 25 Jan 2007.
################


    
################
# The PointMutation object 
# 
# Mutation is a base class for different types of mutations. Currently the
# only Mutation type defined is a PointMutation, but in the future Insertion
# and Deletion objects may also be defined. 
# 
# Each mutation mention returned by the extraction systems is packaged into a 
# PointMutation object. 
#
################

use strict;
use MutationFinder::Constant;
use base 'MutationFinder::Mutation';
use Data::Dumper;

# class PointMutation(Mutation):
# A class for storing information about protein point mutations.

# Define a mapping for residue identity inputs to one-letter
# abbreviations. For simplicty of the normalization procedure, a 
# one-letter to one-letter 'mapping' is also included. This 
# eliminates the need for an independent validation step, since
# any valid identity which is passed in will be a key in this dict, 
# and it avoids having to analyze which format the input residue 
# was passed in as.  
my @aa_codes = split(//, 'ACDEFGHIKLMNPQRSTVWY');
my %aa_lookup = map { $_ => $_ } @aa_codes;
my %_abbreviation_lookup = (%aa_lookup, %amino_acid_three_to_one_letter_map,
    %amino_acid_name_to_one_letter_map);

sub new
{
    my ($class, $opt) = @_;

    # my $data = Dumper($opt);
    die "Bad opt: $opt" if not ref($opt) eq 'HASH';

    if (defined $opt->{wNm})
    {
        if (not ($opt->{wNm} =~ /([A-Z])(\d+)([A-Z])/))
        {
            die "Improperly formatted mutation mention: $opt->{wNm}";
        }

        $opt->{wild} = $1;
        $opt->{position} = $2;
        $opt->{mut} = $3;
    }

    die "Wild type not defined" if not defined $opt->{wild};
    die "Mutant type not defined" if not defined $opt->{mut};
    die "Position not defined" if not defined $opt->{position};

    my $self = $class->SUPER::new($opt);

    # Initalize the object and call the base class init 
    #
    # Location: the sequence position or start position of the mutation
    #           (castable to an int)
    # wild: the wild-type (pre-mutation) residue identity (a string)
    # mut: the mutant (post-mutation) residue identity (a string)
    # 
    # Residues identities are validated to ensure that they are within 
    # the canonical set of amino acid residues are normalized to their
    # one-letter abbreviations.
    # 
    bless $self, $class;
    $self->{_wt_residue} = $self->_normalize_residue_identity($opt->{wild});
    $self->{_mut_residue} = $self->_normalize_residue_identity($opt->{mut});

    return $self;
}

sub _normalize_residue_identity($$)
# Normalize three-letter and full residue names to their 
# one-letter abbreviations. If a residue identity is passed in
# which does not fall into the set of canonical amino acids
# a MutationError is raised.
{
    my ($self, $residue) = @_;
    my $normalized;

    # convert residue to its single letter abbreviation after
    # converting it to uppercase (so lookup is case-insensitive)

    die "No residue" if not defined $residue;
    die "Bad residue $residue" if not defined $_abbreviation_lookup{uc $residue};
    $normalized = $_abbreviation_lookup{uc $residue};
    return $normalized;
}

sub wt_residue($)
{
    my ($self) = @_;
    return $self->{_wt_residue};
}

sub mut_residue($)
{
    my ($self) = @_;
    return $self->{_mut_residue};
}

sub str($)
# Override str(), returns mutation as a string in wNm format"""
{
    my ($self) = @_;
    my $str = $self->{_wt_residue} . $self->{_position} .
        $self->{_mut_residue};
    return $str;
}

sub eq($$)
# Override ==
# Two PointMutation objects are equal if their Location, WtResidue,
# and MutResidue values are all equal.
{
    my ($self, $other) = @_;
    return($self->{_position} eq $other->{_position} and 
           $self->{_wt_residue} eq $other->{_wt_residue} and 
           $self->{_mut_residue} eq $other->{_mut_residue});
}

sub ne($$)
# Override !=
# 
# Two PointMutation obects are not equal if either their Location,
# WtResidue, or MutResidue values differ.
{
    my ($self, $other) = @_;
    return not $self->eq($other);
}

1;

__END__
=pod

=head1 NAME

MutationFinder::PointMutation - Class to capture single amino-acid mutations.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

    use MutationFinder::PointMutation;

    my $pm1 = new MutationFinder::PointMutation(
        {position => 42, wild => 'W', mut => 'G'});

    my $pm2 = new MutationFinder::PointMutation({wNm => 'W42G'});

    if (($pm1->position == 42) and $pm1->eq($pm2))
    {
        print $pm1->str(), "\n";
    }


=head1 DESCRIPTION

This class captures essential information about point mutations.

=head1 METHODS

=head2 PACKAGE->new(HASHREF)

Construct the Mutation object. The hash must include either an integer "position" element
and one-character "wild" and "mut" codes or a single "wNm" string element.

=head2 $OBJ->eq($Mutation)

Returns TRUE if this Mutation is equivalent to another.
Returns FALSE otherwise.

=head2 $OBJ->position()

Returns the position of the Mutation. Inherited from base class
MutationFinder::Mutation.

=head2 $OBJ->mut_residue()

Returns the one-character amino-acid code for the mutant residue. 

=head2 $OBJ->ne($Mutation)

Returns FALSE if this Mutation is equivalent to another.
Returns TRUE otherwise.

=head2 $OBJ->str()

Returns a string representation of the PointMutation object.

=head2 $OBJ->wt_residue()

Returns the one-character amino-acid code for the wild-type residue. 

=head1 SEE ALSO

MutationFinder::Mutation perldoc.

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=cut
