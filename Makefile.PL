use inc::Module::Install;

name     'Text-InterviewMiner';
all_from 'lib/Text/InterviewMiner.pm';
author   'Kieren Diment <zarquon@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

