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
requires 'List::MoreUtils';
requires 'aliased';

auto_install;

WriteAll;

