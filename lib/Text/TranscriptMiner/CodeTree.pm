package Text::TranscriptMiner::CodeTree;
use warnings;
use strict;
use Carp;
use Tree::Simple::WithMetaData;

=head1 DESCRIPTION

Generate a Tree::Simple::WithMetaData from a leading-space delimeted file

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

=head2 sub get_code_tree($location)

Get the location from a Path::Class::File object or a string

=cut

sub get_code_tree {
    my ($self, $structure_file) = @_;
    carp "no file for code tree structure" if ! $structure_file;

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

1;
