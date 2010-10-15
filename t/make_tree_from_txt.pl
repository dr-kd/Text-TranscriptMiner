#!/usr/bin/env perl
use warnings;
use strict;
use Tree::Simple::WithMetaData;

my $tree = Tree::Simple::WithMetaData
    ->new('0', Tree::Simple::WithMetaData->ROOT);
open my $FH, "<", "questions.txt";
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
print_tree($tree);

use Tree::Simple::View::ASCII;

sub print_tree {
    my $tree = shift;
    my $view = Tree::Simple::View::ASCII->new($tree);
    $view->includeTrunk(0);
    print $view->expandAll();
}
