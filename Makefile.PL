
use inc::Module::Install;

name      'Outline-Lua';
all_from  'lib/Outline/Lua.pm';
author    'Alastair Douglas <altreus@perl.com>';

checklibs      lib => 'lua', header => 'lua.h';
checklibs      lib => 'm';
checklibs      lib => 'dl';

build_requires  'Test::More';
build_requires  'Test::Class';

requires  'List::Util';
requires  'Scalar::Util';
requires  'overload';

auto_provides;
auto_install;

WriteAll;
