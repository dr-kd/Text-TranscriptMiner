package Text::TranscriptMiner::Document::Interview;
use Moose;
extends 'Text::TranscriptMiner::Document';

=head1 Text::TranscriptMinder::Document::Interview

Subclass of Text::TranscriptMiner::Document specifically for interview
transcripts.

=cut

=head1 METHODS

=head2 interviewer

Convenience method.  Returns array of all interviewers included in
the keys of the C<<$mine->info->{interviewer}>> hashref

=cut

sub interviewer{
    my ($self) = @_;
    return keys %{$self->info->{interviewer}}
}

=head2 interviewee

Convenience method.  Returns array of al interviewers included in
the keys of the C<<$mine->info->{interviewee}>> hashref.

=cut


sub interviewee{
    my ($self) = @_;
    return keys %{$self->info->{interviewee}}
}

1;
