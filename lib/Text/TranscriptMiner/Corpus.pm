package Text::TranscriptMiner::Corpus;

use Moose;
use MooseX::Types -declare => [qw/CorpusDir Str/];
use MooseX::Types::Moose qw/Str/;
use aliased 'Text::TranscriptMiner::Document::Interview';
use Path::Class;
use aliased 'Tree::Simple::Visitor::LoadDirectoryTree';
use Tree::Simple;
use Tree::Simple::Visitor::PathToRoot;

class_type CorpusDir, { class => 'Path::Class::Dir'} ;
coerce CorpusDir, from Str, via { Path::Class::Dir->new($_)};

=head1 Text::TranscriptMiner::Corpus

Represents a corpus of transcripts

=head2 ATTRIBUTES

start_dir (required Path::Class::Dir object or string)
doctree (hashref created from start_dir)

=head2 METHODS

=head3 new( { startdir => [Path::Class::Dir or string representing path to file])

=cut

has start_dir  => (isa => CorpusDir,
                   is => 'ro',
                   coerce => 1,
                   required => 1);
has doctree    => (isa => 'Tree::Simple',
                   is => 'ro',
                   lazy_build => 1);
has pathfinder => (isa => 'Tree::Simple::Visitor::PathToRoot',
                   is  => 'ro',
                   lazy => 1,
                   default => sub { Tree::Simple::Visitor::PathToRoot->new() }
                 );



=head3 _build_doctree

creates a hashref with the following structure:

...

=cut

sub _build_doctree {
    my ($self) = @_;
    my $tree = Tree::Simple->new($self->start_dir);
    my $visitor = LoadDirectoryTree->new();
    $visitor->setSortStyle($visitor->SORT_FILES_FIRST);
    $visitor->setNodeFilter(
        sub {
            my ($item) = @_;
            return 0 if $item =~ /^\.|mp3/;
            return 1;
        });
    $tree->accept($visitor);
    return $tree;
}




=head3 sort_by_mtime

what it says

=cut

__PACKAGE__->meta->make_immutable;
