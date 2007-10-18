use inc::Module::Install;

name 'Catalyst-View-JSON';
all_from 'lib/Catalyst/View/JSON.pm';

build_requires 'Test::More';
build_requires $_ for qw( JSON JSON::Parser JSON::Converter );

requires 'JSON::Any', 1.11;
requires 'Catalyst', 5.60;

auto_include;
WriteAll;
