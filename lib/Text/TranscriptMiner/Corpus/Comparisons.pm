package Text::TranscriptMiner::Corpus::Comparisons;
use Moose;
extends 'Text::TranscriptMiner::Corpus';

use List::MoreUtils qw/any/;

sub groups {
    my ($self) = @_;
    return $self->_recursive_get_node_names(0);
}

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
    $DB::single = 1 if $level == 1;
    push @kids_names, $_->getNodeValue() for @this_level;
    return $all_levels if !@kids_names;
    @kids_names = _get_interviews_meta(@kids_names);
    @kids_names = _unique(@kids_names);
    @kids_names = grep { defined $_ } @kids_names;
    push @$all_levels, \@kids_names;
    $self->_recursive_get_node_names(++$level, $all_levels);
}

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

sub _unique {
    my (@names) = @_;
    my %names;
    $names{$_} = '' for @names;
    return sort keys %names;
}

__PACKAGE__->meta->make_immutable;
1;
