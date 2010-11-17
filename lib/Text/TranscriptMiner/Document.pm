package Text::TranscriptMiner::Document;
use Moose;
use Path::Class;
use MooseX::Types -declare => [qw/InterviewFile/];
use MooseX::Types::Moose qw/Str HashRef/;

class_type InterviewFile, { class => 'Path::Class::File'} ;
coerce InterviewFile, from Str, via { Path::Class::File->new($_)};

use Carp;

has 'txt'      =>  (isa => Str, is => 'ro', lazy_build => 1);
has 'file'     =>  (isa => InterviewFile, is => 'ro');
has 'info'     =>  (isa => HashRef, is => 'ro', lazy_build => 1);

=head2 _build_info()

Returns the metadata embedded in html style comment tags in the file as a
hashref.

=cut

sub _build_info {
    my ($self) = @_;
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

=head2 _build_txt

Creates the text representation of the document

=cut

sub _build_txt {
    my ($self) = @_;
    return $self->file->slurp || '';
}

=head2 sub get_tagged_txt($tag, [$txt])

Returns an array reference containing the tagged text (one array entry per instance of that tag) from either C<<$self->txt>> or optionally the passed in
C<$txt> (which is intended to be a subset of C<<$self->txt>>, but could be
anything).

=cut

sub get_tagged_txt {
    my ($self, $tag, $txt) = @_;
    croak "Need to supply a tag" if ! $tag;
    my $tags = $self->get_all_tags;
    $txt ||= $self->txt;
    if (! exists $tags->{$tag}) {
        warn "Tag \"$tag\" is not present in " . $self->file . "\n";
        return undef;
    }
    else {
        return $self->get_this_tag($tag, $txt);
    }
}

=head2 sub get_all_tags([$txt])

Returns a hashref keyed by the tag label, with the number of occurences of that
tag as the value

=cut

sub get_all_tags {
    my ($self, $txt) = @_;
    $txt ||= $self->txt;
    my (@tagged_txt) = $txt =~ /\{\/(.*?)\}/msg; # just count by closing tag
    my %tagged_txt;
    $tagged_txt{$_}++ for @tagged_txt;
    return \%tagged_txt;
}

=head2 sub get_this_tag($tag, [$txt])

Worker sub for L<get_tagged_txt> which returns the arrayref described in the
documentation for L<get_tagged_txt>.

=cut

sub get_this_tag {
    my ($self, $tag, $txt) = @_;
    $txt ||= $self->txt;
    my (@tagged_txt) = $txt =~ /({$tag}.*?{\/$tag})/sg;
    return \@tagged_txt;
}

=head2 sub get_tags_for_docs(@docs)

get all tags for a list of files

=cut

sub get_tags_for_docs {
    my ($self, @docs) = @_;
    my $tags = {};
    foreach my $d (@docs) {
        my $iv = $self->new({file => Path::Class::File->new($d)});
        my $doctags = $iv->get_all_tags;
        foreach my $k (keys %$doctags) {
            $tags->{$k} += $doctags->{$k};
        }
    }
    return $tags;
}

1;
