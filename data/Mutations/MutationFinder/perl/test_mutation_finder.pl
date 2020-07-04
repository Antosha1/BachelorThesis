#!/usr/bin/env perl
# Copyright (c) 2007 Regents of the University of Colorado
# Please refer to licensing agreement at MUTATIONFINDER_HOME/doc/license.txt.
#
# Authors: Greg Caporaso (gregcaporaso@gmail.com)
#          David Randolph (rndlph@users.sourceforge.net).
# test_mutation_finder.pl
# Unit test for Perl version of mutation_finder.
###################

use strict;
use Test::SimpleUnit qw{:functions};
use Data::Dumper;

# If a setup or teardown function fails, skip the rest of the tests
Test::SimpleUnit::AutoskipFailedSetup( 1 );
Test::SimpleUnit::AutoskipFailedTeardown( 1 );
  
my $Mutation;
my $RequireWasOkay = 0;
my $Me;  # MutationExtractor
my $Pm;  # PointMutation
my $Pm2; # PointMutation
my @Regular_Expressions = 
(
    '(^|[\s\(\[\'"/,\-])(?P<wt_res>[CISQMNPKDTFAGHLRWVEY])(?P<pos>[1-9][0-9]+)(?P<mut_res>[CISQMNPKDTFAGHLRWVEY])(?=([.,\s)\]\'":;\-?!/]|$))[CASE_SENSITIVE]',
    '(^|[\s\(\[\'"/,\-])(?P<wt_res>(CYS|ILE|SER|GLN|MET|ASN|PRO|LYS|ASP|THR|PHE|ALA|GLY|HIS|LEU|ARG|TRP|VAL|GLU|TYR)|(GLUTAMINE|GLUTAMIC ACID|LEUCINE|VALINE|ISOLEUCINE|LYSINE|ALANINE|GLYCINE|ASPARTATE|METHIONINE|THREONINE|HISTIDINE|ASPARTIC ACID|ARGININE|ASPARAGINE|TRYPTOPHAN|PROLINE|PHENYLALANINE|CYSTEINE|SERINE|GLUTAMATE|TYROSINE))(?P<pos>[1-9][0-9]*)(?P<mut_res>(CYS|ILE|SER|GLN|MET|ASN|PRO|LYS|ASP|THR|PHE|ALA|GLY|HIS|LEU|ARG|TRP|VAL|GLU|TYR)|(GLUTAMINE|GLUTAMIC ACID|LEUCINE|VALINE|ISOLEUCINE|LYSINE|ALANINE|GLYCINE|ASPARTATE|METHIONINE|THREONINE|HISTIDINE|ASPARTIC ACID|ARGININE|ASPARAGINE|TRYPTOPHAN|PROLINE|PHENYLALANINE|CYSTEINE|SERINE|GLUTAMATE|TYROSINE))(?=([.,\s)\]\'":;\-?!/]|$))',
    '(^|[\s\(\[\'"/,\-])(?P<wt_res>(CYS|ILE|SER|GLN|MET|ASN|PRO|LYS|ASP|THR|PHE|ALA|GLY|HIS|LEU|ARG|TRP|VAL|GLU|TYR)|(GLUTAMINE|GLUTAMIC ACID|LEUCINE|VALINE|ISOLEUCINE|LYSINE|ALANINE|GLYCINE|ASPARTATE|METHIONINE|THREONINE|HISTIDINE|ASPARTIC ACID|ARGININE|ASPARAGINE|TRYPTOPHAN|PROLINE|PHENYLALANINE|CYSTEINE|SERINE|GLUTAMATE|TYROSINE))(?P<pos>[1-9][0-9]*)-->(?P<mut_res>(CYS|ILE|SER|GLN|MET|ASN|PRO|LYS|ASP|THR|PHE|ALA|GLY|HIS|LEU|ARG|TRP|VAL|GLU|TYR)|(GLUTAMINE|GLUTAMIC ACID|LEUCINE|VALINE|ISOLEUCINE|LYSINE|ALANINE|GLYCINE|ASPARTATE|METHIONINE|THREONINE|HISTIDINE|ASPARTIC ACID|ARGININE|ASPARAGINE|TRYPTOPHAN|PROLINE|PHENYLALANINE|CYSTEINE|SERINE|GLUTAMATE|TYROSINE))(?=([.,\s)\]\'":;\-?!/]|$))',
    '(^|[\s\(\[\'"/,\-])(?P<wt_res>(CYS|ILE|SER|GLN|MET|ASN|PRO|LYS|ASP|THR|PHE|ALA|GLY|HIS|LEU|ARG|TRP|VAL|GLU|TYR)|(GLUTAMINE|GLUTAMIC ACID|LEUCINE|VALINE|ISOLEUCINE|LYSINE|ALANINE|GLYCINE|ASPARTATE|METHIONINE|THREONINE|HISTIDINE|ASPARTIC ACID|ARGININE|ASPARAGINE|TRYPTOPHAN|PROLINE|PHENYLALANINE|CYSTEINE|SERINE|GLUTAMATE|TYROSINE))(?P<pos>[1-9][0-9]*) to (?P<mut_res>(CYS|ILE|SER|GLN|MET|ASN|PRO|LYS|ASP|THR|PHE|ALA|GLY|HIS|LEU|ARG|TRP|VAL|GLU|TYR)|(GLUTAMINE|GLUTAMIC ACID|LEUCINE|VALINE|ISOLEUCINE|LYSINE|ALANINE|GLYCINE|ASPARTATE|METHIONINE|THREONINE|HISTIDINE|ASPARTIC ACID|ARGININE|ASPARAGINE|TRYPTOPHAN|PROLINE|PHENYLALANINE|CYSTEINE|SERINE|GLUTAMATE|TYROSINE))(?=([.,\s)\]\'":;\-?!/]|$))'
);

  
my @Mutation_Tests = 
(
    # Require the module
    {
        name => 'require',
        test => sub
        {
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::Constant };
            assertNoException { require MutationFinder::Mutation };
            assertNoException { require MutationFinder::PointMutation };
            assertNoException { require MutationFinder::MutationFinder };
            assertNoException { require MutationFinder::BaselineMutationExtractor };
        
            # assertNoException { MyClass->import(':myfuncs') } "Failed to import :myfuncs";
        
            # Make sure calling 'import()' actually imported the functions
            # assertRef 'CODE', *::myfunc{CODE};
            # assertRef 'CODE', *::myotherfunc{CODE};
        
            # Set the flag to let the setup function know the module loaded okay
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'test_new',
        test => sub 
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;
            $Mutation = new MutationFinder::Mutation({position => 42});
            assert($Mutation);
            assertEquals(42, $Mutation->position(), "Bad position");
            $Mutation = new MutationFinder::Mutation({position => '42'});
            assertEquals(42, $Mutation->position(), "Bad position");
        }
    },
    {
        name => 'test_position',
        test => sub 
        {
            my $instance = new MutationFinder::Mutation({position => 42});
            assert($Mutation);
            assertEquals(42, $Mutation->position(), "Bad position");
            $instance = new MutationFinder::Mutation({position => '42'});
            assertEquals(42, $Mutation->position(), "Bad position");
        }
    },
    {
        name => 'test_abstract_methods',
        test => sub 
        {
            my $instance = new MutationFinder::Mutation({position => 42});
            assert($Mutation);
            assertException(sub{$instance->str()});
            assertException(sub{$instance->eq(42)});
            assertException(sub{$instance->ne(42)});
        }
    }
);
 
my %Amino_Acid_Codes =
(
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
    'THR' => 'T',
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
    'THREONINE' => 'T',
    'A' => 'A',
    'G' => 'G',
    'L' => 'L',
    'M' => 'M',
    'F' => 'F',
    'W' => 'W',
    'K' => 'K',
    'Q' => 'Q',
    'E' => 'E',
    'S' => 'S',
    'P' => 'P',
    'V' => 'V',
    'I' => 'I',
    'C' => 'C',
    'Y' => 'Y',
    'H' => 'H',
    'R' => 'R',
    'N' => 'N',
    'D' => 'D',
    'T' => 'T'
);

my @PointMutation_Tests = (
  
    # Require the module
    {
        name => 'require',
        test => sub
        {
            $RequireWasOkay = 0;
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::PointMutation };
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'setup',
        test => sub 
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;
            $Mutation = new MutationFinder::PointMutation(
                {position => 42, wild => 'W', mut => 'G'});
            assert($Mutation);
        }
    },
    {
        name => 'test_valid_init',
        test => sub 
        {
            my $m = new MutationFinder::PointMutation(
                {position => 42, wild => 'A', mut => 'C'});
            assertEquals(42, $m->position());
            assertEquals('A', $m->wt_residue());
            assertEquals('C', $m->mut_residue());
            $m = new MutationFinder::PointMutation(
                {position => 42, wild => 'Ala', mut => 'Cys'});
            assertEquals(42, $m->position());
            assertEquals('A', $m->wt_residue());
            assertEquals('C', $m->mut_residue());
            $m = new MutationFinder::PointMutation(
                {position => 42, wild => 'A', mut => 'Cys'});
            assertEquals(42, $m->position());
            assertEquals('A', $m->wt_residue());
            assertEquals('C', $m->mut_residue());
        }
    },
    {
        name => 'test_invalid_init',
        test => sub 
        {
            assertException(sub {my $m = new MutationFinder::PointMutation(
                {position => 'hello', wild => 'A', mut => 'C'});});
            assertException(sub {my $m = new MutationFinder::PointMutation(
                {position => 42, wild => 'X', mut => 'C'});});
            assertException(sub {my $m = new MutationFinder::PointMutation(
                {position => 0, wild => 'A', mut => 'C'});});
            assertException(sub {my $m = new MutationFinder::PointMutation(
                {position => -42, wild => 'A', mut => 'C'});});
            assertException(sub {my $m = new MutationFinder::PointMutation(
                {position => 42, wild => 'A', mut => 'X'});});
        }
    },
    {
        name => 'test_str',
        test => sub 
        {
            assertEquals($Mutation->str(), 'W42G');
        }
    },
    {
        name => 'test_eq',
        test => sub 
        {
            my $mut = new MutationFinder::PointMutation({wNm => 'W42G'});
            assert($Mutation->eq($mut));
            $mut = new MutationFinder::PointMutation({wNm => 'W42G'});
            assert($Mutation->eq($mut));
            $mut = new MutationFinder::PointMutation({wNm => 'W41G'});
            assertNot($Mutation->eq($mut));
            $mut = new MutationFinder::PointMutation(
                {position => 42, wild => 'Y', mut => 'G'});
            assertNot($Mutation->eq($mut));
            $mut = new MutationFinder::PointMutation(
                {position => 42, wild => 'W', mut => 'C'});
            assertNot($Mutation->eq($mut));
        }
    },
    {
        name => 'test_ne',
        test => sub 
        {
            my $mut = new MutationFinder::PointMutation({wNm => 'W42G'});
            assertNot($Mutation->ne($mut));
            $mut = new MutationFinder::PointMutation({wNm => 'W42G'});
            assertNot($Mutation->ne($mut));
            $mut = new MutationFinder::PointMutation({wNm => 'W41G'});
            assert($Mutation->ne($mut));
            $mut = new MutationFinder::PointMutation(
                {position => 42, wild => 'Y', mut => 'G'});
            assert($Mutation->ne($mut));
            $mut = new MutationFinder::PointMutation(
                {position => 42, wild => 'W', mut => 'C'});
            assert($Mutation->ne($mut));
        }
    },
    {
        name => 'test_normalize_residue_identity',
        test => sub 
        {
            foreach my $test_input (keys %Amino_Acid_Codes)
            {
                my $expected_output = $Amino_Acid_Codes{$test_input};
                my $actual_output = 
                    $Mutation->_normalize_residue_identity(lc $test_input);
                assertEquals($expected_output, $actual_output,
                    "$expected_output != $actual_output");
            }
        }
    },
    {
        name => 'test_normalize_residue_identity_error_handling',
        test => sub 
        {
            foreach my $test_input ('','X','xxala','alaxx','asdasd','42')
            {
                assertException(sub { my $actual_output = 
                    $Mutation->_normalize_residue_identity($test_input)});
            }
            foreach my $test_input ({},[],42,0.42)
            {
                assertException(sub { my $actual_output = 
                    $Mutation->_normalize_residue_identity($test_input)});
            }
        }
    },
);

my @Fake_Input_File = 
(
    "id1\tThe alanine64 to glycine mutation.",
    "id2\tWe constructed W42A (Trp42Ala) and\tG88Y (Gly88Tyr).",
    "id3\tNo mutation mentions here.",
    "id4\t",
    "id5"
);

my $Fake_Output_File = "id1\tA64G
id2\tW42A\tW42A\tG88Y\tG88Y
id3
id4
id5";
my @Fake_Output_File = split "\n", $Fake_Output_File;

my $Fake_Output_File_With_Spans = "id1\tA64G:4,24
id2\tW42A:15,19\tW42A:21,29\tG88Y:35,39\tG88Y:41,49
id3
id4
id5";
my @Fake_Output_File_With_Spans = split "\n", $Fake_Output_File_With_Spans;

my $Fake_Normalized_Output_File = "id1\tA64G
id2\tW42A\tG88Y
id3
id4
id5";
my @Fake_Normalized_Output_File = split "\n", $Fake_Normalized_Output_File;

my $Bme;
my $Mf;
my $Mutex;
my ($Pm1, $Pm2, $Pm3, @Ment1, @Ment2, @Ment3, @Ment4, @Ment5, @Expected);

my @MutationExtractor_Tests = 
(
    # Require the module
    {
        name => 'require',
        test => sub
        {
            $RequireWasOkay = 0;
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::MutationExtractor };
            assertNoException { require MutationFinder::BaselineMutationExtractor };
            assertNoException { require MutationFinder::MutationFinder };
            assertNoException { require MutationFinder::PointMutation };
            assertNoException { require MutationFinder::Mention };
            assertNoException { require MutationFinder::Extraction };
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'setup',
        test => sub 
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;

            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;
            $Mutex = new MutationFinder::MutationExtractor();
            $Bme = new MutationFinder::BaselineMutationExtractor();
            $Mf = new MutationFinder::MutationFinder(
                {regex_file => \@Regular_Expressions, report_spans => 1});
            $Pm1 = new MutationFinder::PointMutation(
                {position => 64, wild => 'A', mut => 'G'});
            @Ment1 = ();
            push @Ment1, new MutationFinder::Mention(
                {mutation => $Pm1, span_begin => 4, span_end => 24});

            $Pm2 = new MutationFinder::PointMutation({wNm => 'W42A'});
            @Ment2 = ();
            push @Ment2, new MutationFinder::Mention(
                {mutation => $Pm2, span_begin => 15, span_end => 19});
            push @Ment2, new MutationFinder::Mention(
                {mutation => $Pm2, span_begin => 21, span_end => 29});

            $Pm3 = new MutationFinder::PointMutation(
                {position => 88, wild => 'G', mut => 'Y'});
            push @Ment2, new MutationFinder::Mention(
                {mutation => $Pm3, span_begin => 35, span_end => 39});
            push @Ment2, new MutationFinder::Mention(
                {mutation => $Pm3, span_begin => 41, span_end => 49});

            @Ment3 = ();
            @Ment4 = ();
            @Ment5 = ();
            @Expected = 
            (
                new MutationFinder::Extraction({id => 'id1', mentions => \@Ment1}),
                new MutationFinder::Extraction({id => 'id2', mentions => \@Ment2}),
                new MutationFinder::Extraction({id => 'id3', mentions => \@Ment3}),
                new MutationFinder::Extraction({id => 'id4', mentions => \@Ment4}),
                new MutationFinder::Extraction({id => 'id5', mentions => \@Ment5})
            );
            assert($Bme);
            assert($Mf);
            assert($Mutex);
        }
    },
    {
        name => 'get_extraction_for_line',
        test => sub 
        {
            assertException(sub {my $result = $Mutex->call('foobar');});

            my $line = "id9\tThe W42G and Ser92Gly mutations are notable.";
            my $extry = $Mf->get_extraction_for_line($line);
            my $m1 = new MutationFinder::PointMutation({wNm => 'W42G'});
            my $m2 = new MutationFinder::PointMutation({wNm => 'S92G'});
            assertEquals($extry->id, "id9"); 
            my $ment = $extry->next();
            assert($m1->eq($ment->mutation));
            $ment = $extry->next();
            assert($m2->eq($ment->mutation));
        }
    },
    {
        name => 'get_output_for_line',
        test => sub 
        {
            my $line = "id9\tThe W42G and Ser92Gly mutations are notable, esp. S92G.";

            $Mf->report_spans(0);
            my $op = $Mf->get_output_for_line($line);
            chomp $op;
            assertEquals($op, "id9\tW42G\tS92G\tS92G");

            $Mf->report_spans(1);
            my $op = $Mf->get_output_for_line($line);
            chomp $op;
            assertEquals($op, "id9\tW42G:4,8\tS92G:13,21\tS92G:50,54");
        }
    },
    {
        name => 'test_extract_mutations_from_string',
        test => sub 
        {
            foreach my $line (@Fake_Input_File)
            {
                my @field = split "\t", $line;
                my ($expected) = $Bme->call($field[1]);
                my ($result) = $Bme->extract_mutations_from_string($field[1]);
                if (not defined $expected)
                {
                    assertEquals($result, undef);
                }
                else
                {
                    assert($expected->mutation()->eq($result->mutation()));
                }
                ($expected) = $Mf->call($field[1]);
                ($result) = $Mf->extract_mutations_from_string($field[1]);
                if (not defined $expected)
                {
                    assertEquals($result, undef);
                }
                else
                {
                    assert($expected->mutation->eq($result->mutation));
                }
            }
        }
    },
    {
        name => 'test_extract_mutations_from_lines',
        test => sub 
        {

            my @actual = $Mf->extract_mutations_from_lines(\@Fake_Input_File);
            assert(@actual);

            my $record_index = 0;
            assert(@Expected);
            foreach my $extract (@Expected)
            {
                my $mention_index = 0;
                assert($extract->eq($actual[$record_index]), "bad index $record_index");
                $record_index++;
            }
   
            # Test with empty list passed in
            @actual = $Mf->extract_mutations_from_lines([]);
            assertNot(@actual);
        }
    },
    {
        name => 'extract_mutations_from_lines_to_file',
        test => sub 
        {
            my $tmp_file = "/tmp/mf_test_output.mf";
            unlink $tmp_file if -f $tmp_file;
            $Mf->report_spans(0);
            $Mf->extract_mutations_from_lines_to_file(\@Fake_Input_File, $tmp_file);

            open OPFILE, $tmp_file or die "bad open";
            my @output = <OPFILE>; 
            close OPFILE or die "bad open";

            assert(@output);
            chomp @output;

            my $index = 0;
            foreach my $expected_line (@Fake_Output_File)
            {
                assertEquals($output[$index++], $expected_line);
            }

            unlink $tmp_file if -f $tmp_file;
        }
    },
    {
        name => 'extract_mutations_from_lines_to_file_w_spans',
        test => sub 
        {
            my $tmp_file = "/tmp/mf_test_output.mf";
            unlink $tmp_file if -f $tmp_file;
            $Mf->extract_mutations_from_lines_to_file(\@Fake_Input_File, $tmp_file);

            open OPFILE, $tmp_file or die "bad open";
            my @output = <OPFILE>; 
            close OPFILE or die "bad open";

            assert(@output);
            chomp @output;

            my $index = 0;
            foreach my $expected_line (@Fake_Output_File_With_Spans)
            {
                assertEquals($output[$index++], $expected_line);
            }

            unlink $tmp_file if -f $tmp_file;
        }
    },
    {
        name => 'extract_mutations_from_lines_to_file_normalized',
        test => sub 
        {
            my $tmp_file = "/tmp/mf_test_output.mf";
            unlink $tmp_file if -f $tmp_file;
            $Mf->report_spans(0);
            $Mf->report_normalized(1);
            $Mf->extract_mutations_from_lines_to_file(\@Fake_Input_File, $tmp_file);

            open OPFILE, $tmp_file or die "bad open";
            my @output = <OPFILE>; 
            close OPFILE or die "bad open";

            assert(@output);
            chomp @output;

            my $index = 0;
            foreach my $expected_line (@Fake_Normalized_Output_File)
            {
                assertEquals($output[$index++], $expected_line);
            }

            unlink $tmp_file if -f $tmp_file;
        }

    },
    {
        name => 'extract_mutations_from_lines_to_file_invalid_params',
        test => sub 
        {
            assertException(sub {$Mf->report_normalized(1)});
            assertException(sub
            {
                my $mf = new MutationFinder::MutationFinder(
                    {regex_file => \@Regular_Expressions, 
                     report_spans => 1,
                     report_normalized => 1})
            });
        }
    },
    {
        name => 'extract_mutations_from_lines_to_file_w_non_default_extractor',
        test => sub 
        {
            assertException(sub {$Bme->report_spans(1)});
            assertException(sub
            {
                my $mf = new MutationFinder::BaselineMutationExtractor(
                    {report_spans => 1});
            });
        }
    },
    {
        name => 'extract_mutations_from_lines_to_dict',
        test => sub 
        {
            my %dict = $Mf->extract_mutations_from_lines_to_dict(\@Fake_Input_File);
            assert(%dict);
     
            assert($dict{id1}); 
            assert($Ment1[0]->eq($dict{id1}->[0]));
            assert($dict{id2}); 
            assert($Ment2[0]->eq($dict{id2}->[0]));
            assert($Ment2[1]->eq($dict{id2}->[1]));
            assert($Ment2[2]->eq($dict{id2}->[2]));
            assert($Ment2[3]->eq($dict{id2}->[3]));
            assert($dict{id3}); 
            assertNot(@{$dict{id3}}); 
            assert($dict{id4}); 
            assertNot(@{$dict{id4}}); 
            assert($dict{id5}); 
            assertNot(@{$dict{id5}}); 
        }
    },
);

my $Obj;
my $Dbg_Obj;
my @Object_Tests = 
(
    # Require the module
    {
        name => 'require',
        test => sub
        {
            $RequireWasOkay = 0;
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::Object };
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'setup',
        test => sub 
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;

            $Obj = new MutationFinder::Object();
            $Dbg_Obj = new MutationFinder::Object(
                {debug => 1});
            assert($Obj);
            assert($Dbg_Obj);
        }
    },
    {
        name => 'eq',
        test => sub 
        {
            assertException( sub {my $answer = $Obj->eq($Obj);} );
        }
    },
    {
        name => 'ne',
        test => sub 
        {
            assertException( sub {my $answer = $Dbg_Obj->ne($Obj);} );
        }
    },
    {
        name => 'debug',
        test => sub 
        {
            assertNot($Obj->debug());
            $Obj->debug(1);
            assert($Obj->debug());
            $Obj->debug(0);

            assert($Dbg_Obj->debug());
            $Dbg_Obj->debug(0);
            assertNot($Obj->debug());
            $Dbg_Obj->debug(1);
        }
    },
);

my ($Ment1_1, $Ment1_2, $Ment1_3, $Ment2_1);
my @Mention_Tests = 
(
    # Require the module
    {
        name => 'require',
        test => sub
        {
            $RequireWasOkay = 0;
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::Mention };
            assertNoException { require MutationFinder::Mutation };
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'setup',
        test => sub 
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;

            $Pm = new MutationFinder::PointMutation({wNm => 'S42T'});
            $Pm2 = new MutationFinder::PointMutation({wNm => 'T42S'});
            assert($Pm);
            assert($Pm2);
            
            $Ment1_1 = new MutationFinder::Mention(
                {mutation => $Pm, span => [12, 20]});
            $Ment1_2 = new MutationFinder::Mention(
                {mutation => $Pm, span_begin => 12, span_end => 20});
            $Ment1_3 = new MutationFinder::Mention(
                {mutation => $Pm, span_begin => 97, span_end => 115});
            $Ment2_1 = new MutationFinder::Mention(
                {mutation => $Pm2, span => [12, 20]});
            assert($Ment1_1);
            assert($Ment1_2);
            assert($Ment1_3);
            assert($Ment2_1);
        }
    },
    {
        name => 'eq',
        test => sub 
        {
            # same mut, same span
            assert($Ment1_1->eq($Ment1_2)); 

            # same mut, different span
            assertNot($Ment1_1->eq($Ment1_3)); 

            # different mut, same span
            assertNot($Ment1_1->eq($Ment2_1)); 

            # different mut, different span
            assertNot($Ment1_3->eq($Ment2_1)); 
        }
    },
    {
        name => 'ne',
        test => sub 
        {
            # same mut, same span
            assertNot($Ment1_1->ne($Ment1_2)); 

            # same mut, different span
            assert($Ment1_1->ne($Ment1_3)); 

            # different mut, same span
            assert($Ment1_1->ne($Ment2_1)); 

            # different mut, different span
            assert($Ment1_3->ne($Ment2_1)); 
        }
    },
    {
        name => 'eq_mutations',
        test => sub 
        {
            # same mut, same span
            assert($Ment1_1->eq_mutations($Ment1_2)); 

            # same mut, different span
            assert($Ment1_1->eq_mutations($Ment1_3)); 

            # different mut, same span
            assertNot($Ment1_1->eq_mutations($Ment2_1)); 

            # different mut, different span
            assertNot($Ment1_3->eq_mutations($Ment2_1)); 
        }
    },
    {
        name => 'eq_spans',
        test => sub 
        {
            # same mut, same span
            assert($Ment1_1->eq_spans($Ment1_2)); 

            # same mut, different span
            assertNot($Ment1_1->eq_spans($Ment1_3)); 

            # different mut, same span
            assert($Ment1_1->eq_spans($Ment2_1)); 

            # different mut, different span
            assertNot($Ment1_3->eq_spans($Ment2_1)); 
        }
    },
    {
        name => 'span',
        test => sub 
        {
            # same mut, same span
            assertException(sub {$Ment1_1->span_end(11)}); 
            assertException(sub {$Ment1_1->span_end(12)}); 
            assertException(sub {$Ment1_1->span_begin(22)}); 
            assertException(sub {$Ment1_1->span_begin(20)}); 

            assertEquals($Ment1_1->span_begin, 12);
            assertEquals($Ment1_1->span_end, 20);

            assertNoException(sub {$Ment1_1->span_begin(13)}); 
            assertNoException(sub {$Ment1_1->span_begin(19)}); 
            assertNoException(sub {$Ment1_1->span_end(21)}); 
            assertNoException(sub {$Ment1_1->span_end(22)}); 

            assertEquals($Ment1_1->span_begin, 19);
            assertEquals($Ment1_1->span_end, 22);

            $Ment1_1->span_begin(12);
            $Ment1_1->span_end(20);
        }
    },
);

my ($Ext1_1, $Ext1_2, $Ext1_3, $Ext2_1, $Ext2_2);
my ($Ment2_2);
my @Extraction_Tests =
(
    # Require the module
    {
        name => 'require',
        test => sub
        {
            $RequireWasOkay = 0;
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::Mention };
            assertNoException { require MutationFinder::Mutation };
            assertNoException { require MutationFinder::Extraction };
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'setup',
        test => sub
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;

            $Pm = new MutationFinder::PointMutation({wNm => 'S42T'});
            $Pm2 = new MutationFinder::PointMutation({wNm => 'T42S'});
            assert($Pm);
            assert($Pm2);

            $Ment1_1 = new MutationFinder::Mention(
                {mutation => $Pm, span => [12, 20]});
            $Ment1_2 = new MutationFinder::Mention(
                {mutation => $Pm, span_begin => 12, span_end => 20});
            $Ment1_3 = new MutationFinder::Mention(
                {mutation => $Pm, span_begin => 97, span_end => 115});
            $Ment2_1 = new MutationFinder::Mention(
                {mutation => $Pm2, span => [12, 20]});
            $Ment2_2 = new MutationFinder::Mention(
                {mutation => $Pm2, span => [512, 520]});
            assert($Ment1_1);
            assert($Ment1_2);
            assert($Ment1_3);
            assert($Ment2_1);
            assert($Ment2_2);

            $Ext1_1 = new MutationFinder::Extraction(
                {id => 'one', mentions => [$Ment1_1, $Ment1_3]});
            $Ext1_2 = new MutationFinder::Extraction(
                {id => 'one', mentions => [$Ment1_1, $Ment1_3]});
            $Ext1_3 = new MutationFinder::Extraction(
                {id => 'one', mentions => [$Ment2_1, $Ment1_3]});
            $Ext2_1 = new MutationFinder::Extraction(
                {id => 'two', mentions => [$Ment1_1, $Ment1_3]});
            $Ext2_2 = new MutationFinder::Extraction(
                {id => 'two', mentions => [$Ment2_1, $Ment1_3]});
            assert($Ext1_1);
            assert($Ext1_2);
            assert($Ext1_3);
            assert($Ext2_1);
            assert($Ext2_2);
        }
    },
    {
        name => 'eq',
        test => sub
        {
            # same id, same mentions
            assert($Ext1_1->eq($Ext1_2));

            # same id, different mentions
            assertNot($Ext1_1->eq($Ext1_3));

            # different id, same mentions
            assertNot($Ext1_1->eq($Ext2_1));

            # different id, different mentions
            assertNot($Ext1_3->eq($Ext2_1));
        }
    },
    {
        name => 'ne',
        test => sub
        {
            # same id, same mentions
            assertNot($Ext1_1->ne($Ext1_2));

            # same id, different mentions
            assert($Ext1_1->ne($Ext1_3));

            # different id, same mentions
            assert($Ext1_1->ne($Ext2_1));

            # different id, different mentions
            assert($Ext1_3->ne($Ext2_1));
        }
    },
    {
        name => 'eq_normalized',
        test => sub
        {
            $Ext1_2->add_mention($Ment1_2);
            assert($Ext1_2->eq_normalized($Ext1_1));
            assertNot($Ext1_2->ne_normalized($Ext1_1));
            $Ext1_2->add_mention($Ment2_2);
            assertNot($Ext1_2->eq_normalized($Ext1_1));
            assert($Ext1_2->ne_normalized($Ext1_1));
        }
    },
    {
        name => 'count',
        test => sub
        {
            $Ext1_2->add_mention($Ment2_2);
            assertEquals($Ext1_2->mention_count(), 3);
            assertEquals($Ext1_2->normalized_count(), 2);
            $Ext1_2->add_mention($Ment1_2);
            assertEquals($Ext1_2->mention_count(), 4);
            assertEquals($Ext1_2->normalized_count(), 2);

            my @mut = $Ext1_2->normalized_mutations(); 
            assertEquals(scalar @mut, 2);
            foreach my $mut (@mut)
            {
                assert($mut->isa('MutationFinder::Mutation'));
                assert($mut->isa('MutationFinder::PointMutation'));
            }

            my @ment = $Ext1_2->mentions();
            assertEquals(scalar @ment, 4);
            foreach my $ment (@ment)
            {
                assert($ment->isa('MutationFinder::Mention'));
            }
        }
    },
    {
        name => 'eq_id',
        test => sub
        {
            assertEquals($Ext1_2->id(), 'one');
            assertEquals($Ext2_2->id(), 'two');

            assert($Ext1_1->eq_id($Ext1_2));
            assert($Ext1_1->eq_id($Ext1_3));
            assert($Ext1_1->ne_id($Ext2_1));
            assert($Ext1_1->ne_id($Ext2_2));

            $Ext2_2->id('one');
            assert($Ext1_1->eq_id($Ext2_2));
            assert($Ext1_1->ne_id($Ext2_1));
            assertNot($Ext1_1->eq_id($Ext2_1));
        }
    },
    {
        name => 'eq_mentions',
        test => sub
        {
            assert($Ext1_1->eq_mentions($Ext1_2));
            assert($Ext1_3->ne_mentions($Ext1_1));
            assert($Ext1_1->eq_mentions($Ext2_1));
        }
    },
    {
        name => 'cursor',
        test => sub
        {
            my $count = 0;
            while (my $ment = $Ext1_1->next())
            {
                assert($ment->isa('MutationFinder::Mention'));
                $count++;
            }
            assertEquals($count, 2);

            $Ext1_2->add_mention($Ment1_2);
            $Ext1_2->add_mention($Ment2_2);

            my @expected = ([12, 20], [12, 20], [97, 115], [512, 520]);

            $count = 0;
            while (my $ment = $Ext1_2->next_mention())
            {
                assert($ment->isa('MutationFinder::Mention'));
                assertEquals($expected[$count]->[0], $ment->span_begin);
                assertEquals($expected[$count]->[1], $ment->span_end);
                $count++;
            }
            assertEquals($count, 4);

            my @expected_span1 = ([12, 20], [12, 20], [97, 115]);
            my @expected_span2 = ([512, 520]);

            $count = 0;
            while (my $mut = $Ext1_2->next_mutation())
            {
                assert($mut->isa('MutationFinder::Mutation'));
                $count++;

                my @span = $Ext1_2->spans($mut);
                assert(@span);

                if ($count == 1)
                {
                    assertEquals(@span, 3);
                    for (my $spandex = 0; $spandex < scalar @expected_span1; $spandex++)
                    {
                        assertEquals($span[$spandex]->[0], $expected_span1[$spandex]->[0]);
                        assertEquals($span[$spandex]->[1], $expected_span1[$spandex]->[1]);
                    }
                }
                elsif ($count == 2)
                {
                    assertEquals(@span, 1);
                    for (my $spandex = 0; $spandex < @span; $spandex++)
                    {
                        assertEquals($span[$spandex]->[0], $expected_span2[$spandex]->[0]);
                        assertEquals($span[$spandex]->[1], $expected_span2[$spandex]->[1]);
                    }
                }
            }
            assertEquals($count, 2); # We only have 2 PointMutations defined.
        }
    },
);


my @BaselineMutationExtractor_Tests = 
(
    # Require the module
    {
        name => 'require',
        test => sub
        {
            $RequireWasOkay = 0;
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::BaselineMutationExtractor };
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'setup',
        test => sub 
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;
            $Me = new MutationFinder::BaselineMutationExtractor();
            $Pm = new MutationFinder::PointMutation({wNm => 'S42T'});
            assert($Me);
        }
    },
    {
        name => 'test_call_no_mutations',
        test => sub 
        {
            assertEquals($Me->call(''), 0);
            assertEquals($Me->call('There is no mutation data here.'), 0);
            assertEquals($Me->call('T64 is almost a valid mutation.'), 0);
            assertEquals($Me->call('So is 42S.'), 0);
        }
    },
    {
        name => 'test_call_single_mutation',
        test => sub 
        {
            # my ($result) = $Me->call('S42T');
            # assert($Pm->eq($result->mutation()));
            # ($result) = $Me->call('The S42T mutation was made.');
            # assert($Pm->eq($result->mutation()));
            assert(1);
        }
    },
    {
        name => 'test_call_boundaries_required',
        test => sub 
        {
            my ($result) = $Me->call('S42T');
            assert($Pm->eq($result->mutation()));

            ($result) = $Me->call('S42Test');
            assertNot($result);
            ($result) = $Me->call('The S42-Test mutation was made.');
            assertNot($result);
            ($result) = $Me->call('gfS42T');
            assertNot($result);
            ($result) = $Me->call('S42Thr');
            assertNot($result);
        }
    },
    {
        name => 'test_call_punc_ignored',
        test => sub 
        {
            my ($result) = $Me->call('S42-T');
            assert($Pm->eq($result->mutation));
            ($result) = $Me->call('?S42T');
            assert($Pm->eq($result->mutation));
            ($result) = $Me->call('S42T?');
            assert($Pm->eq($result->mutation));
            # my @puncs = split //, '!@#$%^&*()~`"\';:.,><?/{}[]\|+=-_';
            my @puncs = split //, ' . . . ()~`"\';:.,><?/{}[]\|+=-_';
            my $str = ''; 
            foreach my $mark (@puncs)
            {
                ($result) = $Me->call("${mark}S42T");
                assert($Pm->eq($result->mutation), "Bad punctuation mark: $mark");
                ($result) = $Me->call("S42T${mark}");
                assert($Pm->eq($result->mutation), "Bad punctuation mark: $mark");
                $str .= $mark;
                ($result) = $Me->call("${str}S42T");
                assert($Pm->eq($result->mutation), "Bad punctuation mark: $str");
                ($result) = $Me->call("S42T${str}");
                assert($Pm->eq($result->mutation), "Bad punctuation mark: $str");
            }
            $str = '!@#$%^&*()~`"\';:.,><?/{}[]\|+=-_S42T';
            ($result) = $Me->call($str);
            assert($Pm->eq($result->mutation), "Bad str: $str");
            $str = '!@#$%^&*()~`"\';S42T:.,><?/{}[]\|+=-_';
            ($result) = $Me->call($str);
            assert($Pm->eq($result->mutation), "Bad str: $str");
            $str = 'S42T!@#$%^&*()~`"\';:.,><?/{}[]\|+=-_';
            ($result) = $Me->call($str);
            assert($Pm->eq($result->mutation), "Bad str: $str");
        }
    },
    {
        name => 'test_call_multiple_mutations',
        test => sub 
        {
            my $pm1 = new MutationFinder::PointMutation(
                {position => 42, wild => 'S', mut => 'T'});
            my $pm2 = new MutationFinder::PointMutation(
                {position => 36, wild => 'W', mut => 'Y'});

            my ($result1, $result2) = $Me->call('S42T and W36Y');
            assert($pm1->eq($result1->mutation));
            assert($pm2->eq($result2->mutation));

            my ($result1, $result2) = $Me->call('S42T W36Y');
            assert($pm1->eq($result1->mutation));
            assert($pm2->eq($result2->mutation));
        }
    },
    {
        name => 'test_call_count',
        test => sub 
        {
            my $pm1 = new MutationFinder::PointMutation(
                {position => 42, wild => 'S', mut => 'T'});
            my $pm2 = new MutationFinder::PointMutation(
                {position => 36, wild => 'W', mut => 'Y'});

            my @result = $Me->call('S42T and W36Y');
            assert($pm1->eq($result[0]->mutation));
            assert($pm2->eq($result[1]->mutation));

            @result = $Me->call('S42T, W36Y, and W36Y');
            assert($pm1->eq($result[0]->mutation));
            assert($pm2->eq($result[1]->mutation));
            assert($pm2->eq($result[2]->mutation));

            @result = $Me->call('S42T, W36Y, Trp36Tyr, and W36Y');
            assert($pm1->eq($result[0]->mutation));
            assert($pm2->eq($result[1]->mutation));
            assert($pm2->eq($result[2]->mutation));
            assert($pm2->eq($result[3]->mutation));
        }
    },
    {
        name => 'test_call_three_to_one_letter_map',
        test => sub 
        {
            my $pm = new MutationFinder::PointMutation(
                {position => 42, wild => 'A', mut => 'G'});

            my @result = $Me->call('The A42G mutation was made.');
            assert($pm->eq($result[0]->mutation));

            @result = $Me->call('The Ala42Gly mutation was made.');
            assert($pm->eq($result[0]->mutation));

            @result = $Me->call('The A42 to glycine mutation was made.');
            assert($pm->eq($result[0]->mutation));

            @result = $Me->call('The A42 has been mutated to glycine with good effect.');
            assert($pm->eq($result[0]->mutation));
        }
    },
    {
        name => 'test_regex_case_sensitive',
        test => sub 
        {
            my @regex = @{$Me->{_word_regexs}};
            my $regex = $regex[0];
            assertNot('a64t' =~ /${regex}/);
            assertNot('A64t' =~ /${regex}/);
            assertNot('a64T' =~ /${regex}/);
            assert('A64T' =~ /${regex}/);

            my $regex = $regex[1];
            assertNot('ala64gly' =~ /${regex}/);
            assertNot('ALA64GLY' =~ /${regex}/);
            assertNot('aLa64gLy' =~ /${regex}/);
            assert('Ala64Gly' =~ /${regex}/);

            @regex = @{$Me->{_string_regexs}};
            my $regex = $regex[3];
            assert('Ala64 to glycine' =~ /${regex}/);
            assert('Ala64 to Glycine' =~ /${regex}/);
            assertNot('Ala64 to GLYCINE' =~ /${regex}/);
            assertNot('Ala64 to glYcine' =~ /${regex}/);
        }
    },
    {
        name => 'test_one_letter_match',
        test => sub 
        {
            my @regex = @{$Me->{_word_regexs}};
            my $regex = $regex[0];
            assert('A64G' =~ /${regex}/);
        }
    },
    {
        name => 'test_three_letter_match',
        test => sub 
        {
            my @regex = @{$Me->{_word_regexs}};
            my $regex = $regex[1];
            assert('Ala64Gly' =~ /${regex}/);
        }
    },
    {
        name => 'test_varied_digit_length',
        test => sub 
        {
            my @regex = @{$Me->{_word_regexs}};
            my $regex = $regex[0];
            assert('A4G' =~ /${regex}/);
            assert('A64G' =~ /${regex}/);
            assert('A864G' =~ /${regex}/);
            assert('A8864G' =~ /${regex}/);
        }
    },
    {
        name => 'test_word_boundary_requirement',
        test => sub 
        {
            my @regex = @{$Me->{_word_regexs}};
            for (my $i = 0; $i < scalar @regex; $i++)
            {
                my $regex = $regex[$i];
                assertNot('TheAla64Glymut' =~ /${regex}/);
                assertNot('Ala64Gly/p53634' =~ /${regex}/);
            }
        }
    },
    {
        name => 'test_mix_one_three_letter_match',
        test => sub 
        {
            my @regex = @{$Me->{_word_regexs}};
            for (my $i = 0; $i < scalar @regex; $i++)
            {
                my $regex = $regex[$i];
                assertNot('Ala64G' =~ /${regex}/);
                assertNot('A64Gly' =~ /${regex}/);
            }
        }
    },
    {
        name => 'test_preprocess_words',
        test => sub 
        {
            my $r = 'this is a t64g mutation.';
            my @expected = ('this', 'is', 'a', 't64g', 'mutation');
            my @actual = $Me->_preprocess_words($r);
            for (my $i = 0; $i < scalar @expected; $i++)
            {
                assertEquals($expected[$i], $actual[$i]);
            }
            $r = 'this is ! t64g mutation.';
            @expected = ('this', 'is', '', 't64g', 'mutation');
            @actual = $Me->_preprocess_words($r);
            for (my $i = 0; $i < scalar @expected; $i++)
            {
                assertEquals($expected[$i], $actual[$i]);
            }
        }
    },
    {
        name => 'test_preprocess_sentences',
        test => sub 
        {
            my $r = 'This is a test. The T65->Y mutation';
            my @expected = ('This is a test', 'The T65Y mutation');
            my @actual = $Me->_preprocess_sentences($r);
            for (my $i = 0; $i < scalar @expected; $i++)
            {
                assertEquals($expected[$i], $actual[$i]);
            }
        }
    },
    {
        name => 'test_replace_regex',
        test => sub 
        {
            my $regex = $Me->{_replace_regex};
            my $test_str = '';
            $test_str =~ s/${regex}//g;
            assertEquals($test_str, '');

            $test_str = 'a46t';
            $test_str =~ s/${regex}//g;
            assertEquals($test_str, 'a46t');

            $test_str = 'a46->t';
            $test_str =~ s/${regex}//g;
            assertEquals($test_str, 'a46t');

            $test_str = 'A234-T';
            $test_str =~ s/${regex}//g;
            assertEquals($test_str, 'A234T');

            $test_str = 'A(234)T';
            $test_str =~ s/${regex}//g;
            assertEquals($test_str, 'A234T');
     
            $test_str = 'The Gly64->Thr mutation.';
            $test_str =~ s/${regex}//g;
            assertEquals($test_str, 'The Gly64Thr mutation');
        }
    },
    {
        name => 'test_ten_word_match',
        test => sub 
        {
            my $pm = new MutationFinder::PointMutation(
                {position => 42, wild => 'S', mut => 'A'});

            my @result = $Me->call('Ser42 was mutated to Ala');
            assert($pm->eq($result[0]->mutation));

            @result = $Me->call('S42 was mutated to Ala');
            assert($pm->eq($result[0]->mutation));

            @result = $Me->call('Ser42 was mutated to alanine');
            assert($pm->eq($result[0]->mutation));

            @result = $Me->call('the S42 was mutated to alanine');
            assert($pm->eq($result[0]->mutation));
      
            # Alanine is tenth word, so match. 
            @result = $Me->call('S42 a a a a a a a a a alanine');
            assert($pm->eq($result[0]->mutation));

            # Alanine is 11th word, so no match.
            @result = $Me->call('S42 a a a a a a a a a a alanine');
            assertNot(@result);
        }
    },
);

my @MutationFinder_Tests =
(
  
    # Require the module
    {
        name => 'require',
        test => sub
        {
            $RequireWasOkay = 0;
            # Make sure we can load the module to be tested.
            assertNoException { require MutationFinder::MutationFinder };
            $RequireWasOkay = 1;
        }
    },
    {
        name => 'setup',
        test => sub 
        {
            # If the previous test didn't finish, it's untestable, so just skip the
            # rest of the tests
            skipAll "Module failed to load" unless $RequireWasOkay;
            $Me = new MutationFinder::MutationFinder(
                {regex_file => \@Regular_Expressions});
            assert($Me);
        }
    },
    {
        name => 'test_init',
        test => sub 
        {
            $Me = new MutationFinder::MutationFinder();
            assert($Me);
            $Me = new MutationFinder::MutationFinder(
                {regex_file => \@Regular_Expressions});
            $Pm = new MutationFinder::PointMutation({wNm => 'S42T'});
            assert($Me);
        }
    },
    {
        name => 'test_call_no_mutations',
        test => sub 
        {
            assertEquals($Me->call(''), 0);
            assertEquals($Me->call('There is no mutation data here.'), 0);
            assertEquals($Me->call('T64 is almost a valid mutation.'), 0);
            assertEquals($Me->call('So is 42S.'), 0);
        }
    },
    {
        name => 'test_call_single_mutation',
        test => sub 
        {
            my ($result) = $Me->call('S42T');
            assert($Pm->eq($result->mutation));
            ($result) = $Me->call('The S42T mutation was made.');
            assert($Pm->eq($result->mutation));
        }
    },
    {
        name => 'test_call_multiple_mutations',
        test => sub 
        {
            my $pm1 = new MutationFinder::PointMutation({wNm => 'S42T'});
            my $pm2 = new MutationFinder::PointMutation({wNm => 'W36Y'});

            my ($result1, $result2) = $Me->call('S42T and W36Y');
            assert($pm1->eq($result1->mutation));
            assert($pm2->eq($result2->mutation));

            my ($result1, $result2) = $Me->call('Ser42Thr and Trp36Tyr');
            assert($pm1->eq($result1->mutation));
            assert($pm2->eq($result2->mutation));
        }
    },
    {
        name => 'test_call_multiple_mutations_w_positive_lookahead',
        test => sub 
        {
            my $pm1 = new MutationFinder::PointMutation({wNm => 'S42T'});
            my $pm2 = new MutationFinder::PointMutation({wNm => 'W36Y'});

            my ($result1, $result2) = $Me->call('S42T W36Y');
            assert($pm1->eq($result1->mutation));
            assertEquals($result1->span_begin, 0);
            assertEquals($result1->span_end, 4);
            assert($pm2->eq($result2->mutation));
            assertEquals($result2->span_begin, 5);
            assertEquals($result2->span_end, 9);

            my ($result1, $result2) = $Me->call('Ser42Thr Trp36Tyr');
            assert($pm1->eq($result1->mutation));
            assertEquals($result1->span_begin, 0);
            assertEquals($result1->span_end, 8);
            assert($pm2->eq($result2->mutation));
            assertEquals($result2->span_begin, 9);
            assertEquals($result2->span_end, 17);
        }
    },
    {
        name => 'test_call_spans_tallied',
        test => sub 
        {
            my $pm1 = new MutationFinder::PointMutation({wNm => 'S42T'});
            my $pm2 = new MutationFinder::PointMutation({wNm => 'W36Y'});

            my ($result1, $result2) = $Me->call('S42T and W36Y');
            assert($pm1->eq($result1->mutation));
            assertEquals($result1->span->[0], 0);
            assertEquals($result1->span->[1], 4);
            assert($pm2->eq($result2->mutation));
            assertEquals($result2->span_begin, 9);
            assertEquals($result2->span_end, 13);

            my @result = $Me->call('S42T, W36Y, and W36Y');
            assert($pm1->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 0);
            assertEquals($result[0]->span_end, 4);
            assert($pm2->eq($result[1]->mutation));
            assertEquals($result[1]->span_begin, 6);
            assertEquals($result[1]->span_end, 10);
            assert($pm2->eq($result[2]->mutation));
            assertEquals($result[2]->span_begin, 16);
            assertEquals($result[2]->span_end, 20);

            my @result = $Me->call('S42T, W36Y, Trp36Tyr, and W36Y');
            assert($pm1->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 0);
            assertEquals($result[0]->span_end, 4);
            assert($pm2->eq($result[1]->mutation));
            assertEquals($result[1]->span_begin, 6);
            assertEquals($result[1]->span_end, 10);
            assert($pm2->eq($result[3]->mutation));
            assertEquals($result[3]->span_begin, 12);
            assertEquals($result[3]->span_end, 20);
            assert($pm2->eq($result[2]->mutation));
            assertEquals($result[2]->span_begin, 26);
            assertEquals($result[2]->span_end, 30);
        }
    },
    {
        name => 'test_call_spans_calculated_correctly_for_different_matches',
        test => sub 
        {
            my $pm = new MutationFinder::PointMutation({wNm => 'A42G'});

            my @result = $Me->call('The A42G mutation was made.');
            assert($pm->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 4);
            assertEquals($result[0]->span_end, 8);

            my @result = $Me->call('The Ala42-->Gly mutation was made.');
            assert($pm->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 4);
            assertEquals($result[0]->span_end, 15);

            my @result = $Me->call('The Ala42Gly mutation was made.');
            assert($pm->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 4);
            assertEquals($result[0]->span_end, 12);

            my @result = $Me->call('The Ala42 to Glycine mutation.');
            assert($pm->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 4);
            assertEquals($result[0]->span_end, 20);
        }
    },
    {
        name => 'test_regex_case_sensitive_flag_one_letter',
        test => sub 
        {
            my @regex = @{$Me->{_regexs}};
            my $regex = $regex[0];
            assertNot('a64t' =~ /${regex}/);
            assertNot('A64t' =~ /${regex}/);
            assertNot('a64T' =~ /${regex}/);
            assert('A64T' =~ /${regex}/);
        }
    },
    {
        name => 'test_regex_case_sensitive_flag_three_letter',
        test => sub 
        {
            my @regex = @{$Me->{_regexs}};
            my $regex = $regex[1];
            assert('ala64gly' =~ /${regex}/);
            assert('ALA64GLY' =~ /${regex}/);
            assert('aLa64gLy' =~ /${regex}/);
            assert('Ala64Gly' =~ /${regex}/);
        }
    },
    {
        name => 'test_one_letter_match',
        test => sub 
        {
            my @regex = @{$Me->{_regexs}};
            my $regex = $regex[0];
            assert('A64G' =~ /${regex}/);
        }
    },
    {
        name => 'test_one_letter_match_loc_restriction',
        test => sub 
        {
            my @regex = @{$Me->{_regexs}};
            my $regex = $regex[0];
            assert('A64G' =~ /${regex}/);
            assertNot('E2F' =~ /${regex}/);
            assertNot('H9A' =~ /${regex}/);
        }
    },
    {
        name => 'test_three_letter_match',
        test => sub 
        {
            my @regex = @{$Me->{_regexs}};
            my $regex = $regex[1];
            assert('Ala6Gly' =~ /${regex}/);
            assert('Ala64Gly' =~ /${regex}/);
        }
    },
    {
        name => 'test_varied_digit_length',
        test => sub 
        {
            my @regex = @{$Me->{_regexs}};
            my $regex = $regex[0];
            assert('A64G' =~ /${regex}/);
            assert('A864G' =~ /${regex}/);
            assert('A8864G' =~ /${regex}/);
            $regex = $regex[1];
            assert('Ala64Gly' =~ /${regex}/);
            assert('Ala864Gly' =~ /${regex}/);
            assert('Ala8864Gly' =~ /${regex}/);
        }
    },
    {
        name => 'test_post_process',
        test => sub 
        {
            my @ment;
            my $mutation = new MutationFinder::PointMutation({wNm => 'W460W'});
            assert($mutation, "Bad new");
            my @span = (0, 5);
            my $mention = new MutationFinder::Mention(
                {'mutation' => $mutation, 'span' => \@span});
            push @ment, $mention;
            my @cooked = $Me->_post_process(@ment);
            assertNot(@cooked);

            my $mutation2 = new MutationFinder::PointMutation({wNm => 'W460G'});
            assert($mutation2, "Bad new");
            my @span2 = (6, 11);
            my $mention2 = new MutationFinder::Mention(
                {'mutation' => $mutation2, 'span' => \@span2});
            push @ment, $mention2;
            my @cooked = $Me->_post_process(@ment);
            assertEquals(@cooked, 1);
            assert($cooked[0]->mutation->eq($mutation2));
        }
    },
    {
        name => 'test_unacceptable_general_word_boundaries',
        test => sub 
        {
            my @starts = split "", 
                'abcdefghijklmnopqrstuvwxyz0123456789~@#$%^&*_+=])';
            my @ends = split "",
                'abcdefghijklmnopqrstuvwxyz0123456789~@#$%^&*_+=([';
            my @mutation_texts = 
                ('A64G','Ala64Gly','Ala64-->Gly');

            foreach my $mutation_text (@mutation_texts)
            {
                foreach my $start (@starts)
                {
                    foreach my $end (@ends)
                    {
                        my $text = $start . $mutation_text . $end;
                        my @result = $Me->call($text);
                        assertNot(@result);
                    }
                } 
            }
        }
    },
    {
        name => 'test_acceptable_general_word_boundaries',
        test => sub 
        {
            my @ends = (".",",",""," ","\t","\n",")","]","'",'"',":",";","?","!","/","-");
            my @starts = (" ","\t","\n","'",'"',"(","[","","/",",","-");
            my @mutation_texts = 
                ('A64G','Ala64Gly','Ala64-->Gly');
            my $pm = new MutationFinder::PointMutation({wNm => 'A64G'});

            foreach my $mutation_text (@mutation_texts)
            {
                foreach my $start (@starts)
                {
                    foreach my $end (@ends)
                    {
                        my $text = $start . $mutation_text . $end;
                        my @result = $Me->call($text);
                        assert(@result);
                        assert($pm->eq($result[0]->mutation));
                        my $starting_index = index $text, 'A';
                        my $ending_index = $starting_index + length $mutation_text;
                        assertEquals($result[0]->span_begin, $starting_index);
                        assertEquals($result[0]->span_end, $ending_index);
                    }
                } 
            }
        }
    },
    {
        name => 'test_mix_one_three_letter_match',
        test => sub 
        {
            assertNot($Me->call('Ala64G'));
            assertNot($Me->call('A64Gly'));
        }
    },
    {
        name => 'test_full_name_matches',
        test => sub 
        {
            my $pm = new MutationFinder::PointMutation({wNm => 'A64G'});
            my @result = $Me->call('alanine64-->Gly');
            assert($pm->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 0);
            assertEquals($result[0]->span_end, 15);

            @result = $Me->call('Ala64-->glycine');
            assert($pm->eq($result[0]->mutation));
            assertEquals($result[0]->span_begin, 0);
            assertEquals($result[0]->span_end, 15);
        }
    },
    {
        name => 'test_single_residue_fails_non_xNy',
        test => sub 
        {
            my $pm = new MutationFinder::PointMutation({wNm => 'A64G'});
            my @result = $Me->call('A64-->glycine');
            assertNot(@result);

            @result = $Me->call('Ala64-->G');
            assertNot(@result);
        }
    },
    {
        name => 'test_text_based_matches_w_N_m',
        test => sub 
        {
            my $pm = new MutationFinder::PointMutation({wNm => 'A64G'});
            my @texts =
            (
                'Ala64 to Gly',
                'Alanine64 to Glycine',
                'Ala64 to glycine',
                'alanine64 to Gly'
            );
     
            foreach my $text (@texts)
            {
                my @result = $Me->call($text);
                assert($pm->eq($result[0]->mutation));
                my $ending_index = length $text;
                assertEquals($result[0]->span_begin, 0);
                assertEquals($result[0]->span_end, $ending_index);
            }
            
            @texts =
            (
                'The Ala64 to Gly substitution',
                'The Ala64 to glycine substitution',
                'The Ala64 to Gly substitution'
            );

            foreach my $text (@texts)
            {
                my @result = $Me->call($text);
                assert($pm->eq($result[0]->mutation));
                my $ending_index = length($text) - 13;
                assertEquals($result[0]->span_begin, 4);
                assertEquals($result[0]->span_end, $ending_index);
            }
        }
    },
    {
        name => 'def test_text_match_spacing',
        test => sub 
        {
            my @result = $Me->call('TheAla40toGlymutation');
            assertNot(@result);

            @result = $Me->call('arg40tomet');
            assertNot(@result);

            @result = $Me->call('ala25tohis');
            assertNot(@result);
        }
    },
);


print "\nObject_Tests\n";
runTests(@Object_Tests);

print "\nMutation_Tests\n";
runTests(@Mutation_Tests);

print "\nPointMutation_Tests\n";
runTests(@PointMutation_Tests);

print "\nMention_Tests\n";
runTests(@Mention_Tests);

print "\nExtraction_Tests\n";
runTests(@Extraction_Tests);

print "\nBaselineMutationExtractor_Tests\n";
runTests(@BaselineMutationExtractor_Tests);

print "\nMutationFinder_Tests\n";
runTests(@MutationFinder_Tests);

print "\nMutationExtractor_Tests\n";
runTests(@MutationExtractor_Tests);

