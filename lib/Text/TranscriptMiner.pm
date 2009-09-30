package Text::TranscriptMiner;

use Moose;

=head1 NAME

Text::TranscriptMiner - Mine text data from interviews and other transcripted speech

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Text::TranscriptMiner;

    my $miner = Text::TranscriptMiner->new();
    ...

=head1 METHODS

=head1 attributes

nothing this is currently a blank class

=cut

has 'nothing' => (isa => 'Str', is => 'ro', required => 1);

=head1 AUTHOR

Kieren Diment, C<< <zarquon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-interviewminer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-TranscriptMiner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::TranscriptMiner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-TranscriptMiner>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-TranscriptMiner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-TranscriptMiner>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-TranscriptMiner/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Kieren Diment, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::TranscriptMiner
