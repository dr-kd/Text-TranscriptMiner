package Text::TranscriptMiner::Corpus;

use Moose;
use MooseX::Types -declare => [qw/CorpusDir Str/];
use MooseX::Types::Moose qw/Str/;
use aliased 'Text::TranscriptMiner::Document::Interview';
use Path::Class;
use aliased 'Tree::Simple::Visitor::LoadDirectoryTree';
use Tree::Simple::WithMetaData;
use Tree::Simple::Visitor::PathToRoot;
use List::MoreUtils qw/all/;
use Carp;
use File::Find;
use List::Util qw/max/;
use aliased 'Text::TranscriptMiner::Document::Interview';

class_type CorpusDir, { class => 'Path::Class::Dir'} ;
coerce CorpusDir, from Str, via { Path::Class::Dir->new($_)};

=head1 Text::TranscriptMiner::Corpus

Represents a corpus of transcripts

=head2 ATTRIBUTES

start_dir (required Path::Class::Dir object or string)
doctree (Tree::Simple::WithMetaData created from start_dir)

=head2 METHODS

=head3 new( { startdir => [Path::Class::Dir or string representing path to file])

=cut

has start_dir  => (isa => CorpusDir,
                   is => 'ro',
                   coerce => 1,
                   required => 1);
has doctree    => (isa => 'Tree::Simple::WithMetaData',
                   is => 'ro',
                   lazy_build => 1);
has pathfinder => (isa => 'Tree::Simple::Visitor::PathToRoot',
                   is  => 'ro',
                   lazy => 1,
                   default => sub { Tree::Simple::Visitor::PathToRoot->new() }
                 );



=head3 _build_doctree

creates a Tree::Simple::WithMetaData of the document tree.



=cut

sub _build_doctree {
    my ($self) = @_;
    my $tree = Tree::Simple::WithMetaData->new($self->start_dir);
    my $visitor = LoadDirectoryTree->new();
    $visitor->setSortStyle($visitor->SORT_FILES_FIRST);
    $visitor->setNodeFilter(
        sub {
            my ($item) = @_;
            return 0 if $item =~ /^\.|mp3/;
            return 1;
        });
    $tree->accept($visitor);
    $tree->traverse(sub {
                        my ($_t) = @_;
                        if ($_t->isRoot()) {
                            $_t->addMetaData('most_recent_mtime' => $self->get_most_recent_mtime());
                        }
                        $_t->accept($self->pathfinder);
                        my $file = Path::Class::Dir->new($self->start_dir)
                            ->file($self->pathfinder->getPathAsString('/'));
                        my $path = $self->pathfinder->getPath();
                        $path ||= [];
                        $_t->addMetaData(path => $path);
                        if (-f $file && -e $file) {
                            my $interview = Interview->new({file => $file});
                            $_t->addMetaData(interview => $interview,
                                             file => $file,
                                         );
                        }
                    });
    return $tree;
}

=head2 get_most_recent_mtime

Find the mtime for the most recently modified file in the doctree

=cut

sub get_most_recent_mtime {
    my ($self) = @_;
    my $start_dir = $self->start_dir;
    my @mtimes;
    find ( sub {
               my $file = $_;
               return unless $_ =~ /.txt$/;
               $file = $self->start_dir->file($file);
               return if ! -e $file;
               push @mtimes, $file->stat->mtime;
           }, "$start_dir");
    return max(@mtimes);
}

=head2 get_files_info

Grabs metadata from the file names and paths.  Directory names are assumed to contain information.  File names have words delimited by '_' characters, and only words in all capitals are assumed to be worth collecting;

=cut


sub get_files_info {
    my ($self) = @_;
    my $nodes = $self->get_subnodes;
    my $data = {};
    foreach my $n (@$nodes) {
        my @data = split '/', $n;
        my $file = pop @data;
        $file =~ s/\.txt$//;
        my @fileinfo = split '_', $file;
        @fileinfo =  grep { /^[A-Z]+$/ } @fileinfo;
        $data->{$_}++ for (@data, @fileinfo);
    }
    return $data;
}

=head2 sub get_subnodes ($node [, $data])

Recursive function to get subnodesfrom this part $self->doctree and return as
an array ref.

=cut

sub get_subnodes {
    my ($self, $node, $data) = @_;
    $node ||= $self->doctree;
    $data ||= [];
    foreach my $n ($node->getAllChildren) {
        push @$data, $n;
        if ($node->getAllChildren) {
            $self->get_subnodes($n, $data);
        }
    }
    return $data;
}

=head2 sub search_for_subnodes ($tags, $doctree)

get all array ref of $tags present for this list of documents from $doctree

=cut

sub search_for_subnodes {
    my ($self, $tags, $doctree) = @_;
    croak "not an array reference" unless ref($tags) eq 'ARRAY';
    my @tags;
    @tags = grep { $_ ne '_remove'} @$tags;
    my $pages = $self->get_subnodes;
    my @pages;
    # if all of @tags are in each $page then add to @pages;
    foreach my $p (@$pages) {
        push @pages, $p if (all { $p =~ /$_/} @tags);
    }
    return \@pages;
}

=head2 sub get_interviews ($docs)

for an array ref of docs, get all the applicable Test::TranscriptMiner::Interview objects and return in an array

=cut

sub get_interviews {
    my ($self, $start_dir, $docs) = @_;
    my @docs = map {Interview->new({file => Path::Class::Dir->new($start_dir)->file($_)}) } @$docs;
    @docs = grep {$_->txt} @docs;
    return @docs;
}

=head2 sub get_all_tags_for_interviews($doctree)

get all the tags for a $doctree array of interviews

=cut

sub get_all_tags_for_interviews {
    my ($self, $doctree) = @_;
    $doctree ||= $self->doctree;
    my $data = $self->get_subnodes;
    my @files = grep { -f $self->start_dir->file($_) } @$data;
    my @docs = $self->get_interviews($self->start_dir, \@files);
    my %tags;
    foreach (@docs) {
        $DB::single=1;
        my %this_tags = %{$_->get_all_tags()};
        foreach my $k (keys %this_tags) {
            $tags{$k} += $this_tags{$k}
        }
    }
    return \%tags;
}

__PACKAGE__->meta->make_immutable;

1;
