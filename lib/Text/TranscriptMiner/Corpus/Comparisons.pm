package Text::TranscriptMiner::Corpus::Comparisons;
use Moose;
extends 'Text::TranscriptMiner::Corpus';
use YAML;
use Storable qw/nstore retrieve/;
use Digest::MD5 qw/md5_hex/;
use Tree::Simple::WithMetaData;
use File::Basename;
use Text::TranscriptMiner::CodeTree;
use Tree::Simple::Visitor::FindByPath;
use Scalar::Util qw/weaken/;
use List::MoreUtils qw/any/;
use Data::Leaf::Walker;
use List::Compare;
use XML::Writer::String;
use XML::Writer;

=head1 DESCRIPTION

Text::TranscriptMiner::Corpus;:Comparisons

utility functions for comparing different parts of a corpus

=head2 SUMMARY

groups, get_code_structure

=cut

=head2 groups

Sub for getting the grouping variables from the directory tree containing the corpus

=cut

sub groups {
    my ($self) = @_;
    return $self->_recursive_get_node_names();
}

=head2 _recursive_get_node_names

internal sub to do the work for C<groups>

=cut

sub _recursive_get_node_names {
    my ($self, $level, $all_levels) = @_;
    $level ||=0;
    $all_levels ||=[];
    my @this_level;
    my @kids_names;
    $self->doctree->traverse(sub {
                                  my ($t) = @_;
                                  push @this_level, $t
                                      if $t->getDepth() == $level;
                               }
                         );
    push @kids_names, $_->getNodeValue() for @this_level;
    return $all_levels if !@kids_names;
    @kids_names = _get_interviews_meta(@kids_names);
    @kids_names = _unique(@kids_names);
    @kids_names = grep { defined $_ } @kids_names;
    push @$all_levels, \@kids_names;
    $self->_recursive_get_node_names(++$level, $all_levels);
}

=head2 sub _get_interviews_meta

internal only sub to get the metadata (person classification stuff) from the metadata embedded in the txt files filename.

=cut

sub _get_interviews_meta {
    my (@names) = @_;
    my @return;
    for (@names) {
        my $return;
        if ($_ =~ /\.txt/) {
            ($return) = $_ =~ /([[:upper:]]{2,})/;
            push @return, $return if $return;
        }
        else {
            push @return, $_;
        }
    }
    return @return;
}

=head2 _unique(@names)

internal sub to make a non-unique list unique.

=cut

sub _unique {
    my (@names) = @_;
    my %names;
    $names{$_} = '' for @names;
    return sort keys %names;
}

sub get_meta_start_dir {
    my ($self) = @_;
    my $startdir = $self->start_dir;
    my $structure_file = basename("$startdir");
    $structure_file = $self->start_dir->parent->subdir("${structure_file}_meta");
    die if ! -e $structure_file;
    return $structure_file;
}

=head2 sub get_code_structure

Given a file location (or C<<$self->start_dir ../[basename of start_dir]_meta>>
by default), return a Tree::Simple::WithMetaData of all the wanted codes for
this analysis run via Text::TranscriptMiner::CodeTree


=cut

sub get_code_structure {
    my ($self, $structure_file) = @_;
    if (!$structure_file) {
        $structure_file = $self->get_meta_start_dir->file('questions.txt');
    }
    die ("no file for codes structure") unless -e $structure_file;
    my $tree = Text::TranscriptMiner::CodeTree->get_code_tree($structure_file);
    return $tree;
}

=head2 make_comparison_report_tree ($groups [, $code_file])

The real work in this package.  Given an array ref of groups as follows,
returns the Tree::Simple report of the groups. 

The $groups array ref should look as follows:

   [
   [ first level categories],
   [ second level catogeries],
   [ ... nth level categories],
   [ last level categories],
   ]

It will return the tree structure from get_code_structure with the metadata
slots populated for the report

=cut

sub make_comparison_report_tree {
    my ($self, $groups, $code_file) = @_;
    $code_file ||= $self->get_meta_start_dir->file('questions.txt');
    $groups ||= $self->groups;
    my $cached_report = $self->find_cached_report_tree($groups, $code_file);
    return $cached_report->{data} if $cached_report;

    my $report_tree = $self->get_code_structure($code_file);
    my $doctree = $self->doctree;
    $report_tree->traverse( sub {
                                my ($t) = @_;
                                my $val = $t->getNodeValue();
                                my %groups_struct = $self->_get_groups_data_structure($groups);
                                my $code_tree_data = \%groups_struct;
                                my $node_data = $self->_get_txt_for_node(\%groups_struct, {}, $t, $val);
                                $t->addMetaData(
                                    'node_data' => $node_data)
                                    if $val;

                            });
    $self->cache_report_tree($groups, $code_file, $report_tree);
    return $report_tree;
}

=head2 sub _cache_file ($groups, $code_file)

Utility sub to get the cached file

=cut

sub _cache_file {
    my ($self, $groups, $code_file) = @_;
    $code_file ||= 'default';
    my $cache_dir = $self->get_meta_start_dir->subdir('cache');
    mkdir $cache_dir if !-e $cache_dir;
    my $storage_data = { groups => $groups,
                         code_file => "$code_file"};
    my $storage_file = md5_hex(Dump $storage_data);
    return ($cache_dir->file($storage_file), $storage_data);
    
}

=head2 sub find_cached_report_tree ($groups, $code_file)

Get the cached report tree if it exists and is still valid.

=cut

sub find_cached_report_tree {
    my ($self, $groups, $code_file) = @_;
    my $most_recent_mtime = $self->get_most_recent_mtime;
    $most_recent_mtime ||=0;
    my ($cache_file, $cache_metadata) = $self->_cache_file($groups, $code_file);
    my $data = undef;
    if ( -e $cache_file && $cache_file->stat->mtime >= $most_recent_mtime) {
        $data = retrieve("$cache_file");
    }
    return $data;
}

=head2 cache_report_tree ($groups, $code_file, $data)

cache the report tree

=cut

sub cache_report_tree {
    my ($self, $groups, $code_file, $data) = @_;
    my ($cache_file, $cache_metadata) = $self->_cache_file($groups, $code_file);
    nstore {data => $data, search_info => $cache_metadata}, "$cache_file";
}

=head2 sub _get_groups_data_structure()

Get the data structure for gluing onto the end of each node of the code tree
for countaining the actual data we're eventually interested in.

=head2 IMPORTANT

This section of code in this method that does the work (the C<$inject> and
C<$visit> while clever is a bit fragile.  At present this means that we remove
all C<children> keys in the C<_get_txt_for_node> method.  This may need to
be fixed with better code Possibly L<CPS|http://search.cpan.org/perldoc?CPS>
can help with this kind of recursive descent problem.


=cut

sub _get_groups_data_structure {
    my ($self, $groups ) = @_;
    $groups ||= $self->groups;

    ## this implementation courtesy of ribasushi.  Must acknowledge in the
    ## paper.
    my %leaf;
    @leaf{@{$groups->[$#{$groups}]}} = '';

    my $inject = {
        -1 => {%{\%leaf}},
        0 =>  {%{\%leaf}},
        1 =>  {%{\%leaf}},
    };

    my ($visit, $v);
    $v = $visit = sub {  # get $visit in scope through a hack.  Could use
                         # Sub::Current instead.  Might want to do this in the
                         # situation that this code is called in a more complex
                         # situation.
        $_[0] ||= 0;
        +{ map
               {
                   $_ => $inject->{$_[0]}
                       ? { %{$inject->{$_[0]}}, children => $visit->($_[0]+1) }
                       : $_[0] == @$groups
                           ? $visit->($_[0]+1)
                           : $inject->{-1}
                       }
                   @{$groups->[$_[0]]}
               };
    };

    weaken($visit); # without this we have a memory leak
    my $data_tree = $visit->();
    return %$data_tree;
};

sub _get_txt_for_node {
    my ($self, $code_tree_data, $node_data, $t, $code) = @_;
    my $walker = Data::Leaf::Walker->new($code_tree_data);
    while (my ($k, $v) = $walker->each) {
        $v = [] if !$v;
        next unless any {$_ eq 'children'} @$k;
        my @wanted_path = @$k;
        @wanted_path = grep { $_ ne 'children'} @wanted_path;
        my $wanted_type = pop(@wanted_path);
        my $doctree = $self->doctree;
        $doctree->traverse(sub {
                               my ($_t) = @_;

                               ### STYLE WARNING.  rather than nested if
                               # statements, we just retun if a condition is
                               # not met repeatedly.  This reduces the amount
                               # of indentation in callback sub and keeps it
                               # perl debugger friendly.

                               # bail if wer're not on  a leaf
                               my $iview = $_t->fetchMetaData('interview');
                               return unless $iview;
                               my @this_path = @{$_t->fetchMetaData('path')};
                               # check we have the right kind of entry
                               return unless $_t->getNodeValue =~ /$wanted_type/;
                               # check we're on the right doc node
                               my @this = @this_path[0 .. $#this_path-1];
                               my $lc = List::Compare->new('--unsorted', \@wanted_path,
                                                           \@this);
                               return unless $lc->is_LequivalentR();
                               my $txt = { $code => $iview->get_this_tag($code)};
                               return unless @{$txt->{$code}};

                               # we want the data here.
                               my $data = {
                                   path => \@this_path,
                                   text => $txt,
                                        };
                               push @$v, $data;
                               $DB::single=1;
                               $node_data = $self->insert_node([@this_path, $wanted_type], $node_data, $v);
                               $node_data = $node_data;

                           });
    }
    return $node_data;
}

sub insert_node {
    my ($self, $path, $data, $leaf_data) = @_;
    $path = [$path] if !ref($path);
    my $this_level = $data;
    foreach my $p (@$path) {
        $this_level->{$p} = {} unless exists $this_level->{$p};
        $this_level = $this_level->{$p};
}
    my $walker = Data::Leaf::Walker->new($data);
    my $old_data = $walker->fetch($path);
    $old_data = [] unless ref($old_data) eq 'ARRAY';
    push @$old_data, $leaf_data;
    $walker->store($path, $old_data);
    return $data;
}




__PACKAGE__->meta->make_immutable;
1;
