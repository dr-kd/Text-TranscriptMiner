package Text::TranscriptMiner::Corpus::Comparisons;
use Moose;
extends 'Text::TranscriptMiner::Corpus';

use List::MoreUtils qw/any/;
use Tree::Simple::WithMetaData;
use File::Basename;

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
this analysis run.

The file structure is one code per line to reflect the tree structure:

  - Code title {code_name}
   - Another code title below this one {another_code_name}
  - Code title up one {blah}
   - Down one {blahblah}
    - Down two {asdf}
  - Up to to one above root {etc}
  - Final code {final}

Delimiting of the tree level can be a single space per level or a single tab
character per level.  You can mix the two but that would probably be silly.

TODO:  Split this out into its own CPAN module.

=cut

sub get_code_structure {
    my ($self, $structure_file) = @_;
    if (!$structure_file) {
        my $startdir = $self->start_dir;
        $structure_file = basename("$startdir");
        $structure_file = $self->start_dir->parent->subdir("${structure_file}_meta")->file("questions.txt");
    }
    die ("no file for codes structure") unless -e $structure_file;

    # now generate the tree with slots for metadata.
    my $tree = Tree::Simple::WithMetaData
        ->new('0', Tree::Simple::WithMetaData->ROOT);
    open my $FH, "<", $structure_file;
    my $oldlength = 0;
    my $node = $tree;
    while (<$FH>) {
        next if /^#/; # skip comments
        chomp $_;
        my ($pos, $name, $code) = $_ =~ /(\s+)?-\s(.*?)(?=\s?\{(.*?)\})/;
        if (!$name & ! $code) {
            ($pos, $name ) = $_ =~ /(\s+)?-\s(.*?)$/;
        }
        $pos ||='';
        $pos = length($pos);
        $code = $name if ! $code;
        my $newnode = Tree::Simple::WithMetaData->new($code);
        $newnode->addMetaData( description => $name,
                               data => { } );
        if ($pos == $oldlength) { # child to root node, or sibling to non-root
            if ($node->getDepth() == -1) {
                $node->addChild($newnode);
            }
            else {
                $node->addSibling($newnode);
            }
        }
        elsif ($pos > $oldlength) { # add child
            $node->addChild($newnode);
        }
        elsif ($pos < $oldlength) { #add sibling to parent
            if ($node->getDepth() == -1) {
                $node->addChild($newnode);
            }
            else {
                for ($pos .. ($oldlength - 1 ) ) {
                    last if $node->getDepth() == -1;
                    $node = $node->getParent();
                }
                if ($node->getDepth() == -1) {
                    $node->addChild($newnode);
                }
                else {
                    $node->addSibling($newnode);
                }
            }
        }
        # track position in the tree for next run.
        $node = $newnode;
        $oldlength = $pos;
    }
    return $tree;
}

__PACKAGE__->meta->make_immutable;
1;
