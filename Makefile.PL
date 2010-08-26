use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Outline::Lua',
    VERSION_FROM      => 'lib/Outline/Lua.pm', # finds $VERSION
    PREREQ_PM         => {
    }, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => {
        Test::Class       => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Outline/Lua.pm', # retrieve abstract from module
       AUTHOR         => 'Al <al@podcats.in>') : ()),
    LIBS              => ['-lm -ldl -llua5.1'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I/usr/include/lua5.1/', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
