#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Path::Class;
BEGIN { use_ok 'Text::TranscriptMiner::Document::Interview';}
use FindBin qw/$Bin/;
my $file = Path::Class::File->new("$Bin/lib/corydoctorow_transcript.txt");
my $mine = Text::TranscriptMiner::Document::Interview->new({file => $file});
my @interviewer = $mine->interviewer;
ok($interviewer[0] eq 'Sara', "got correct interviewer name");
my @interviewee = $mine->interviewee;
ok($interviewee[0] eq 'Cory', "got correct interviewee name");
done_testing();
