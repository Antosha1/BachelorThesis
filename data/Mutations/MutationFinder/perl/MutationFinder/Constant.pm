package MutationFinder::Constant;
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Author: Greg Caporaso (gregcaporaso@gmail.com)
# Perl port by David Randolph (rndlph@users.sourceforge.net).
# 
# File created on 25 Jan 2007.

use strict;
require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw
(
    SUCCESS
    FAILURE
    TRUE
    FALSE
    VERSION
    ME 
    %amino_acid_three_to_one_letter_map
    %amino_acid_name_to_one_letter_map
);

use constant SUCCESS => 0;
use constant FAILURE => 1;
use constant TRUE => 1;
use constant FALSE => 0;
use constant VERSION => '1.1';
use constant ME => 'mutation_finder.pl';

    
# A hash table mapping three-letter amino acids codes onto one-letter
# amino acid codes
our %amino_acid_three_to_one_letter_map = (
    'ALA' => 'A',
    'GLY' => 'G',
    'LEU' => 'L',
    'MET' => 'M',
    'PHE' => 'F',
    'TRP' => 'W',
    'LYS' => 'K',
    'GLN' => 'Q',
    'GLU' => 'E',
    'SER' => 'S',
    'PRO' => 'P',
    'VAL' => 'V',
    'ILE' => 'I',
    'CYS' => 'C',
    'TYR' => 'Y',
    'HIS' => 'H',
    'ARG' => 'R',
    'ASN' => 'N',
    'ASP' => 'D',
    'THR' => 'T');

# A hash table mapping amino acid names to their one-letter abbreviations
our %amino_acid_name_to_one_letter_map = (
    'ALANINE' => 'A',
    'GLYCINE' => 'G',
    'LEUCINE' => 'L',
    'METHIONINE' => 'M',
    'PHENYLALANINE' => 'F',
    'TRYPTOPHAN' => 'W',
    'LYSINE' => 'K',
    'GLUTAMINE' => 'Q',
    'GLUTAMIC ACID' => 'E',
    'GLUTAMATE' => 'E',
    'ASPARTATE' => 'D',
    'SERINE' => 'S',
    'PROLINE' => 'P',
    'VALINE' => 'V',
    'ISOLEUCINE' => 'I',
    'CYSTEINE' => 'C',
    'TYROSINE' => 'Y',
    'HISTIDINE' => 'H',
    'ARGININE' => 'R',
    'ASPARAGINE' => 'N',
    'ASPARTIC ACID' => 'D',
    'THREONINE' => 'T');

1;
__END__
=pod

=head1 NAME

MutationFinder::Constant - Constants for MutationFinder objects.

=head1 COPYRIGHT

(c) Copyright 2007 Regents of the University of Colorado.

=head1 SYNOPSIS

use MutationFinder::Constant;

print $amino_acid_three_to_one_letter_map{'ARG'};

=head1 DESCRIPTION

This module defines constants to support mutation mention extraction.

=head1 CONSTANTS 

=head2 %amino_acid_name_to_one_letter_map

A hash table mapping full amino-acid names (e.g., "ARGININE") to one-letter
codes (e.g., "A").

=head2 %amino_acid_three_to_one_letter_map

A hash table mapping three-character amino-acid codes (e.g., "ARG") to one-letter
codes (e.g., "A").

=head2 FAILURE

A failure return code (1).

=head2 FALSE

The Perl false Boolean value (0).

=head2 SUCCESS

A successful return code (0).

=head2 ME 

The official name of this software.

=head2 TRUE

The truth value in Perl (1).

=head2 VERSION

The version of this MutationFinder release.

=head1 AUTHOR

=over

=item *

David Randolph

=item *

Creg Caporaso

=back

=cut
