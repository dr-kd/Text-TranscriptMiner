#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::InterviewMiner' );
}

diag( "Testing Text::InterviewMiner $Text::InterviewMiner::VERSION, Perl $], $^X" );
