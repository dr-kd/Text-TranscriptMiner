#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::TranscriptMiner' );
}

diag( "Testing Text::TranscriptMiner $Text::TranscriptMiner::VERSION, Perl $], $^X" );
