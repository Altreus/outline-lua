#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Outline::Lua' );
}

diag( "Testing Outline::Lua $Outline::Lua::VERSION, Perl $], $^X" );
