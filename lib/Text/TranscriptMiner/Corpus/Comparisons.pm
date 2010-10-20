package Text::TranscriptMiner::Corpus::Comparisons;
use Moose;
extends 'Text::TranscriptMiner::Corpus';

use Tree::Simple::WithMetaData;
use File::Basename;
use Text::TranscriptMiner::CodeTree;
use Scalar::Util qw/weaken/;


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
    return $self->_recursive_get_node_names(0);
}

=head2 _recursive_get_node_names

internal sub to do the work for C<groups>

=cut

sub _recursive_get_node_names {
    my ($self, $level, $all_levels) = @_;
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
    for (@names) {
        if ($_ =~ /\.txt/) {
            $_ =~ /^(?=.*?|_)([[:upper:]]{2,})_?.*?\.txt$/;
            $_ = $1 if $_;
        }
    }
    @names = grep {defined $_} @names;
    use YAML;
    return @names;
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

=head2 sub get_code_structure

Given a file location (or C<<$self->start_dir ../[basename of start_dir]_meta>>
by default), return a Tree::Simple::WithMetaData of all the wanted codes for
this analysis run via Text::TranscriptMiner::CodeTree


=cut

sub get_code_structure {
    my ($self, $structure_file) = @_;
    if (!$structure_file) {
        my $startdir = $self->start_dir;
        $structure_file = basename("$startdir");
        $structure_file = $self->start_dir->parent->subdir("${structure_file}_meta")->file("questions.txt");
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
    my $doctree = $self->doctree;
    $groups ||= $self->groups;
    my $test_groups = [];
    my $report_tree = $self->get_code_structure($code_file);
    my $groups_struct = $self->_get_groups_data_structure;
    $report_tree->traverse( sub {
                                my ($t) = @_;
                                $t->addMetaData(data => \%groups_struct);
                                $self->_insert_txt_for_node(\%groups_struct, $t);

                            });
    
    return $test_groups;
    # return $tree
}

=head2 sub _get_groups_data_structure()

Get the data structure for gluing onto the end of each node of the code tree
for countaining the actual data we're eventually interested in.

=cut



sub _get_groups_data_structure {
    my ($self, $groups ) = @_;
    $groups ||= $self->groups;



    ## this implementation courtesy of ribasushi.  Must acknowledge in the
    ## paper.
    my $inject = {
        -1 => 'leaf',
        0 => { some_data => 'lvl0' },
        1 => { some_data => 'lvl1' },
    };

    my ($visit, $v);
    $v = $visit = $visit = sub { # get $visit in scope through a hack
        $_[0] ||= 0;
        $DB::single=1;
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
    my $data_tree = $visit->(0);
    return $data_tree;
};


__PACKAGE__->meta->make_immutable;
1;
