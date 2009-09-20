#!/usr/bin/env perl
use Test::More;
use File::Slurp;
BEGIN { use_ok 'Text::InterviewMiner::Document';}
use FindBin qw/$Bin/;
my $file = "$Bin/lib/corydoctorow_transcript.txt";
my $mine = Text::InterviewMiner::Document->new({filename => $file});
ok((keys %{$mine->info->{interviewer}})[0] eq 'Sara', "got interviewer name");
ok((keys %{$mine->info->{interviewee}})[0] eq 'Cory', "got interviewee name");
ok($mine->txt =~ /Sara: \[999\]/, "match beginning of interview ok");
done_testing();

