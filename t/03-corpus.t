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
ok($tree->isa('Tree::Simple::WithMetaData'), "got a Tree::Simple::WithMetaData");
my $most_recent_mtime = $tmc->get_most_recent_mtime;
ok($most_recent_mtime =~ /^\d+$/, "got mtime of most recently modified file");

done_testing();
