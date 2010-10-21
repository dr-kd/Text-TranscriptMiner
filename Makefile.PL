use inc::Module::Install;

name     'Text-TranscriptMiner';
all_from 'lib/Text/TranscriptMiner.pm';
author   'Kieren Diment <zarquon@cpan.org>';
license  'perl';

build_requires 'Test::More';
requires 'Moose';
requires 'MooseX::Types';
requires 'Path::Class';
requires 'Tree::Simple';
requires 'Tree::Simple::Visitor::PathToRoot';
requires 'Tree::Simple::Visitor::LoadDirectoryTree';
requires 'Tree::Simple::WithMetaData';
requires 'Tree::Simple::Visitor::FindByPath';
requires 'List::MoreUtils';
requires 'aliased';
requires 'Regexp::Common';
requires 'URI';
requires 'Data::Leaf::Walker';

auto_install;

WriteAll;

