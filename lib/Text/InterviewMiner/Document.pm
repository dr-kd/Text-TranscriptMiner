package Text::InterviewMiner::Document;
use Moose;
use Path::Class;
use Carp;

has 'txt'      =>  (isa => 'Str', is => 'rw');
has 'filename' =>  (isa => 'Str', is => 'rw');
has 'file'     =>  (isa => 'Path::Class::File', is => 'rw');
has 'info'     =>  (isa => 'HashRef', is => 'ro', lazy_build => 1);

sub _build_info {
    my ($self) = @_;
    $DB::single=1;
    my ($metatxt) = $self->txt =~ /<!--(.*)-->/ms;
    my @metatxt = split /\n+/m, $metatxt;
    my %metadata;
    for my $m (@metatxt) {
        chomp $m;
        next if $m =~ /^\s*$/;
        my ($key, $val) = split /:\s*/, $m;
        my @val = split /,\s*/, $val;
        my %val;
        $val{$_} = '' for @val;
        $metadata{$key} = \%val;
    }
    return \%metadata;
}


sub BUILD {
    my ($self) = @_;
    croak "Can't instantiate with both file and txt\n" if $self->txt && $self->filename;
    croak "Need to instantiate with either filename or text\n" unless $self->txt|| $self->filename;
    if ($self->filename) {
        $self->file(Path::Class::File->new($self->filename));
    }
    if (! $self->txt) {
        $self->txt(scalar($self->file->slurp));
    }
    # standardise newlines of txt
    my $txt = $self->txt;
    $txt =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;
    $self->txt($txt);
}

1;
