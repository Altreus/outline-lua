use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Outline::Lua',
    AUTHOR              => 'Alastair Douglas <altreus@perl.com>',
    VERSION_FROM        => 'lib/Outline/Lua.pm',
    ABSTRACT_FROM       => 'lib/Outline/Lua.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Outline-Lua-*' },
);
