package Text::TranscriptMiner::Document::Comparisons;

use Moose;
use MooseX::Types -declare => [qw/ SummaryDir Str/];
use MooseX::Types::Moose qw/Str ArrayRef/;
use Path::Class;
use aliased 'Tree::Simple::Visitor::LoadDirectoryTree';
use Tree::Simple;
use Tree::Simple::View::ASCII;
use aliased 'Tree::Simple::WithMetaData';
use aliased 'Tree::Simple::Visitor::PathToRoot';
use File::Temp;
use File::Basename;
use File::Copy::Recursive qw/dircopy/;
use Carp;

=head1 Text::TranscriptMiner::Comparisons

Data structures for representing a set of comparisons of summaries of data.

=head2 ATTRIBUTES

=over

=item start_dir

required Path::Class::Dir object or string

=item cmp_name

required Dir name (string) beneath start_dir which contains the comparisons

=item comparison

auto build attribute found by getting the directory names immediately below
cmp_name, via an array ref (in case it's deep).

=item summary_tree

auto built from start_dir, cmp_name and summary tree.  We merge the two
directory trees into one in a temporary directory in order to obatain the full
tree.

At some point we might want to make these into hard links rather than copies
for space reasons but that requires work as nothing is available on CPAN to
merge two dir trees into one tree of hard links just now.

=back

=cut

class_type SummaryDir, { class => 'Path::Class::Dir'} ;
coerce SummaryDir, from Str, via { Path::Class::Dir->new($_)};


has start_dir      => (isa => SummaryDir,
                       is => 'ro',
                       coerce => 1,
                       required => 1);
has cmp_name       => (isa => ArrayRef,
                       is  => 'ro',
                       required => 1);
has comparison         => (isa => ArrayRef,
                       is =>  'ro',
                       lazy_build => 1);

has summary_tree    => (isa => 'Tree::Simple',
                       is => 'ro',
                       lazy_build => 1);

has _pathfinder    => (isa => 'Tree::Simple::Visitor::PathToRoot',
                       is  => 'ro',
                       lazy => 1,
                       default => sub { PathToRoot->new() }
                   );

has _dir_tree      => (isa => Str,
                       is => 'ro',
                       lazy_build => 1,
                   );

has _categories     => (isa => ArrayRef,
                       is  => 'ro',
                       lazy_build => 1,
                   );


=head3 _build_comparison

Get the comparison dirs from the top level dirs below the C<dirname> root.
Note you can exclude comparisons by prepending the dir name with an underscore.

=cut

sub _build_comparison {
    my ($self) = @_;

    # warning:  this needs to be made more generic!
    warn "This call is not generic and needs to be fixed";
    my $start = $self->start_dir->subdir('pre_implementation_first_cut')->subdir('summary');
    
    opendir (my $dh, $start);
    my @cmps = grep { !/^(\.|_)/ && -d $start->subdir("$_") } readdir($dh);
    return \@cmps;
}

=head3 _build__dir_tree

Creates a Tree::Simple of a temporary dir of the merged comparison dirs.

=cut

sub _build__dir_tree {
    my ($self) = @_;
    my $tmpdir = File::Temp->newdir->dirname;
    my @cmp_dirs = @{$self->comparison};
    my @cmp_names;
    croak "no comparison dirs available" if !@{$self->comparison};
    push @cmp_names, $self->start_dir->subdir(@{$self->cmp_name})->subdir($_)
        for @{$self->comparison};
    foreach (@cmp_names) {
        dircopy($_,$tmpdir);
    }

    return $tmpdir;
}

=head3 _build_summary_tree

Build the master dir structure

=cut

sub _build_summary_tree {
    my ($self) = @_;
    my $tree = Tree::Simple->new($self->_dir_tree);
    my $visitor = LoadDirectoryTree->new();
    $visitor->setSortStyle($visitor->SORT_FILES_FIRST);
    $visitor->setNodeFilter(
        sub {
            my ($item) = @_;
            if ($item eq 'descr.txt' || $item =~ /^\w+$/) {
                return 1;
            }
            else { return 0 }
        });
    $tree->accept($visitor);
    $self->_add_metadata($tree);
    return $tree;

}

=head2 _build__categories()

Grab the complete list of categories for the corpus of comparisons

=cut

sub _build__categories {
    my ($self) = @_;
    my $tree = Tree::Simple->new($self->_dir_tree);
    my $visitor = LoadDirectoryTree->new();
    $visitor->setSortStyle($visitor->SORT_FILES_FIRST);
    $tree->accept($visitor);
    my %cats;
    $tree->traverse( sub {
                         my ($_tree) = @_;
                         my $val = $_tree->getNodeValue();
                         return if $val =~ /^(q-.*?|descr)\.txt/;
                         if ($val =~ /\.txt$/) {
                             $val = fileparse($val);
                             $cats{$val} = '';
                         }
                     });
    return [keys %cats];
}


=head2 _add_metadata($tree)

Internal sub to add the comparisons metadata to the comparison tree

For each node (going to be ending in descr.txt) it will grab the dir hierarchy
under the comparisons dir in the original place where the summaries are stored
and

=cut

sub _add_metadata {
    my ($self, $tree) = @_;
    $tree->traverse( sub {
                         my ($_tree) = @_; $self->_add_metadata_to_node($_tree);
                     });
}

=head1

Grabs the metadata for the terminal nodes

=cut

sub _add_metadata_to_node {
    my ($self, $node) = @_;
    $self->_pathfinder->includeTrunk;
    $node->accept($self->_pathfinder);
    if ($node->getNodeValue eq 'descr.txt') {
        $node = WithMetaData->new($node);
        my $file = Path::Class::Dir->new($self->_dir_tree)->file($self->_pathfinder->getPath());
        my $rel_path = $self->_pathfinder->getPath();
        my $descr = $file->slurp;
        chomp($descr);
        my $source_dir = $file->dir();
        foreach my $c (@{$self->comparison}) {
            my $data_dir = $self->start_dir->subdir(@{$self->cmp_name})->subdir($c)->file(@$rel_path)->dir;
            $node->addMetaData( summary =>  $self->_get_metadata_for_leaf($data_dir));
        }
    }
}

sub _get_metadata_for_leaf {
    my ($self, $dir) = @_;
    my %data;
    my $info = [];
    foreach my $c (@{$self->_categories}) {
        my $key = (fileparse($c,".txt"))[0];
        my $file = $dir->file($c);
        if ( -e $file ) {
            $info = $self->_get_file_info($file);
        }
    }
    return $info;
}

sub _get_file_info{
    my ($self, $file) = @_;
    my $data = [];
    my @chunks = split /^s*(?=http)/ms, $file->slurp;
    foreach my $c (@chunks) {
        use Regexp::Common qw/URI/;
        my ($uri, $chunk) = $c =~ /\s*($RE{URI}#\S+)\n*(.*)$/ms;
        my (@bits) = $c  =~  /\n*--\s*(.*?)$/msg;
        push @$data, { uri => $uri, summary => \@bits };
    }
    return $data;
}


1;
