use 5.010001;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

my (%liblua, %liblualib, $cflags, $libs, $lua_version);

   eval {%liblua = ExtUtils::PkgConfig->find('lua5.1')}
or eval {%liblua = ExtUtils::PkgConfig->find('lua5.2')};

if (%liblua) {
  $cflags = $liblua{cflags};
  $libs   = $liblua{libs};
}
else {
  $libs = '-llua5.1 -lm -ldl';
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Outline::Lua',
    VERSION_FROM      => 'lib/Outline/Lua.pm', # finds $VERSION
    PREREQ_PM         => {
        List::Util        => 0,
        Scalar::Util      => 0,
        overload          => 0,
    },
    BUILD_REQUIRES    => {
        Test::Class       => 0,
        Test::More        => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Outline/Lua.pm', # retrieve abstract from module
       AUTHOR         => 'Al <al@podcats.in>') : ()),
    LIBS              => [$libs], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $cflags, # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
