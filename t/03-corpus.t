#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
BEGIN { use_ok 'Text::TranscriptMiner::Corpus';}
use FindBin qw/$Bin/;
use YAML;
use Path::Class;

my $pc = Path::Class::Dir->new("$Bin/lib");
my $tmc =  Text::TranscriptMiner::Corpus->new({start_dir => $pc });

ok($tmc->start_dir->isa('Path::Class::Dir'), "got path::class::dir");
$tmc = Text::TranscriptMiner::Corpus->new({start_dir => "$Bin/lib" });
ok($tmc->start_dir->isa('Path::Class::Dir'), "got coerced path::class::dir");

my $tree =  $tmc->doctree;
ok($tree->isa('Tree::Simple'), "got a Tree::Simple");


done_testing();
