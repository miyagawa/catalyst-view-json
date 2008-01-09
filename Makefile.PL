use inc::Module::Install;

name 'Catalyst-View-JSON';
all_from 'lib/Catalyst/View/JSON.pm';

build_requires 'Test::More';

requires 'JSON::Any', 1.15;
requires 'Catalyst', 5.60;

auto_include;
WriteAll;
