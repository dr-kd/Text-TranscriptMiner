package Text::TranscriptMiner::Corpus::Comparisons;
use Moose;
extends 'Text::TranscriptMiner::Corpus';
use YAML;
use Digest::MD5 qw/md5_hex/;
use Tree::Simple::WithMetaData;
use File::Basename;
use Text::TranscriptMiner::CodeTree;
use Tree::Simple::Visitor::FindByPath;
use File::Path qw/make_path/;
use Path::Class;

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

    my $report_tree = $self->get_code_structure($code_file);
    my $doctree = $self->doctree;
    return $report_tree;
}

=head2 sub get_results_for_node($path)

Given a path of the following format:

[ code_name, (path down dir tree), (match for terminal node) ] return the text
for that node as an array ref.

=cut

sub get_results_for_node{
    my ($self, $path) = @_;
    my $code = shift @$path;
    my $terminal = pop @$path;
    my $branch = $self->get_this_branch($path);
    my @docs;

    $branch->traverse(
        sub {
            my ($t) = @_;
            push @docs, $t->fetchMetaData('interview')
                if $t->getNodeValue =~ /(^|_|\.)$terminal(_|\.)/;
        }) if $branch;
    my $result = [];
    foreach my $d (@docs) {
        my $tagged_text = $d->get_this_tag($code);
        my $file_path = $d->file->relative($self->start_dir);
        push @$result,
            { txt => $tagged_text,
              path => $file_path,
              notes => $self->get_notes($file_path, $code),
          };
    }
    return $result;
}

sub get_notes {
    my ($self, $path, $code) = @_;
    my $notes_dir = $self->get_meta_start_dir->subdir('notes', $path);
    make_path("$notes_dir") if ! -e $notes_dir;
    my $notes_file = $notes_dir->file($code);
    my $notes;
    $notes = $notes_file->slurp() if -e $notes_file;
    my $data = {};
    my $status;
    $status = 'pending' if ! $notes;
    if ($notes) {
        my $transcript_file_mtime = $self->start_dir->file($path)->stat->mtime;
        my $notes_file_mtime = $notes_file->stat->mtime;
        $status = 'outdated' if $notes_file_mtime < $transcript_file_mtime;
    }
    return { status => $status, notes => $notes};
}

sub write_notes {
    my ($self, $file, $notes, $code) = @_;
    $DB::single=1;
    my $notes_dir = $self->get_meta_start_dir->subdir('notes', $file);
    make_path("$notes_dir") if ! -e $notes_dir;
    my $notes_file = $notes_dir->file($code);
    $notes_file->touch if ! -e $notes_file;
    my $FH = $notes_file->openw();
    print $FH $notes;
    return 'OK';
}

__PACKAGE__->meta->make_immutable;
1;
