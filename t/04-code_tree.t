#!/usr/bin/env perl;
use warnings;
use strict;
use Test::More;
use FindBin qw/$Bin/;

use Tree::Simple::View::ASCII;

use Text::TranscriptMiner::Corpus::Comparisons;
my $corpus_dir = "$Bin/lib";
my $corpus = Text::TranscriptMiner::Corpus::Comparisons->new({start_dir => $corpus_dir});
my $struct_tree = $corpus->get_code_structure;
ok($struct_tree);
my $view = Tree::Simple::View::ASCII->new($struct_tree);
$view->includeTrunk(0);
my $expected_tree;
{ local $/;
      $expected_tree = <DATA>;
}
ok ($view->expandAll() eq $expected_tree, "code tree is as expected tree");
$DB::single=1;
done_testing;

__DATA__
q:add
q:communication
    |---q:find
            |---q:verbal
q:written
q:computer
    |---q:enhance
    |---q:print
q:communication_paper
q:skills
    |---q:others_skills
    |       |---q:illiteracy
    |---q:own_skills
            |---q:at_home
            |---q:length
            |---q:usage
            |---q:time
            |---q:your_skills
q:demographic
    |---q:duration
    |---q:career
    |---q:type
    |---q:name
    |---q:role
    |       |---q:shift
    |---q:staff
q:doc_practice
    |---q:location
    |---q:time_shift
    |---q:information
    |---q:paper
    |---q:doc_role
q:opinions
    |---q:benefits
    |---q:impact
    |---q:weakness
    |---q:concerns
    |---q:start
    |---q:experience
    |---q:frustrations
    |       |---q:reliability
    |---q:happiest
    |---q:care
    |---q:challenges
    |---q:risks
    |---q:used_well
    |---q:workstation
Resistance
    |---q:you_resistance
    |---q:other_resistance
Refusal
    |---q:you_refusal
    |---q:other_refusal
q:occupational
    |---q:practice
    |---q:environment
    |---q:hardest
    |---q:pattern
    |---q:quality
q:training
    |---q:improvements
    |---q:trainer
q:stable
