#!/usr/bin/env perl;
use warnings;
use strict;
use Test::More;
use FindBin qw/$Bin/;

use Tree::Simple::View::ASCII;

use Text::TranscriptMiner::Corpus::Comparisons;

#TODO need to make tests from generic redistributable data.
my $corpus_dir = "$Bin/../../interviews";

if (! -e $corpus_dir) {
    diag "Not running without a valid test tree.  Current test data for this function are not redistributable because of confidentiality issues";
    plan skip_all => "don't have generically redistributable data for these tests";
}
my $corpus = Text::TranscriptMiner::Corpus::Comparisons->new({start_dir => $corpus_dir});

use YAML;
diag Dump $corpus->_get_groups_data_structure();
ok(1);

done_testing;
