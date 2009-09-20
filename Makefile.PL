use inc::Module::Install;

name     'Text-TranscriptMiner';
all_from 'lib/Text/TranscriptMiner.pm';
author   'Kieren Diment <zarquon@cpan.org>';
license  'perl';

build_requires 'Test::More';
requires 'Moose';
requires 'Path::Class';
auto_install;

WriteAll;

