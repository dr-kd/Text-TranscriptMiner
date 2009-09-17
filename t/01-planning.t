#!/usr/bin/env perl
use Test::More;
use File::Slurp;
my @files = @ARGV;
ok(@files, "passed in a list of files to process");
done_testing();

my $txt = get_file_contents($files[0]);
my %contents = parse_file_contents($txt);


sub get_file_contents {
    my ($file) = @_;
    return read_file($file);
}

sub parse_file_contents {
    my ($txt) = @_;
    
}
