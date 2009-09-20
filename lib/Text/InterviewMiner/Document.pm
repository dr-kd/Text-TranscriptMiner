package Text::InterviewMiner::Document;
use Moose;
use Path::Class;
use Carp;

has 'txt' =>       (isa => 'Str', is => 'ro');
has 'filename' =>  (isa => 'Str', is => 'ro');
has 'file' =>      (isa => 'Path::Class::File', is => 'ro');
has 'metadata' =>  (isa => 'HashRef', lazy_build => 1);

sub BUILD {
    my ($self) = @_;
    croak "Can't instantiate with both file and txt\n" if $self->txt && $self->filename;
    croak "Need to instantiate with either filename or text\n" if ! $self->txt || ! $self->filename;
    if ($self->filename) {
        $self->file(Path::Class::File->new($self->filename));
    }
    if (! $self->txt) {
        $self->txt($self->file->slurp);
    }
}


sub _build_metadata {
    my ($self) = @_;
    my ($metatxt) = $self->txt =~ /<!--(.*)-->/m;
    my @metatxt = split /\n+/m, $metatxt;
    my %metadata;
    for my $m (@metatxt) {
        my ($key, $val) = split /(.*?):\s*(.*?)/;
        my @val = split /,\s*/, $val;
        my %val;
        $val{$_} = '' for @val;
        $metadata{$key} = \%val;
    }
    return \%metadata;
}

1;
