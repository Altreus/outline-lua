#!perl -T

use strict;
use Test::More 'no_plan';

use Outline::Lua;

my $test_str = "Hello world!\n"; # corny

sub test {
  print $test_str;
}

close STDOUT; open STDOUT, '>', \my $str;

my $lua = Outline::Lua->new;

$lua->register_perl_func('main::test', 'test', 0, 0);
$lua->run('test()');

is($str, $test_str);
