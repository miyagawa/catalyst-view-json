use inc::Module::Install;
use Module::Install::Repository;

name 'Catalyst-View-JSON';
all_from 'lib/Catalyst/View/JSON.pm';

build_requires 'Test::More';

requires 'JSON::Any', 1.15;
requires 'Catalyst', 5.60;
requires 'MRO::Compat';

auto_set_repository;
auto_include;
WriteAll;
