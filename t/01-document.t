#!/usr/bin/env perl
use Test::More;
use Path::Class;
BEGIN { use_ok 'Text::TranscriptMiner::Document';}
use FindBin qw/$Bin/;
my $file = Path::Class::File->new("$Bin/lib/corydoctorow_transcript.txt");
my $mine = Text::TranscriptMiner::Document->new({file => $file});
ok($mine->txt =~ /Sara: \[999\]/, "match beginning of interview ok");
my $tags = $mine->get_all_tags;
my $tags_ref = {
    'q:activity' => 1,
    'q:copyfight' => 1,
    'q:piracy' => 2,
    'q:international' => 2,
    'q:name' => 1,
    'q:copyright' => 1,
    'q:commons' => 3,
    'q:usa' => 1,
    'q:formats' => 1,
    'q:publisher' => 1,
    'q:enforcement' => 1,
    'q:ebook' => 2
};

is_deeply($tags, $tags_ref, "expected tags list matches got tags");
ok (!$mine->get_tagged_txt('missing'), "nonexistent tag returns undef");
my $tagged_txt = $mine->get_tagged_txt('q:commons');
ok(scalar(@$tagged_txt) == 3, "got the right number of tags back");

my $tagged_txt2 = $mine->get_tagged_txt('q:copyfight');
ok(scalar(@$tagged_txt2) == 1, "got the right number of tags back");


done_testing();

