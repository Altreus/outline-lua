#!/usr/bin/perl

#This file should work in order to say that
#Outline::Lua works.

use warnings;
use strict;

use lib 'lib';

use Outline::Lua;
use Data::Dumper;

$| = 1;

my $lua = Outline::Lua->new();

$lua->loadstdio(); # stdin, stdout, stderr
$lua->register_perl_func(
{
  lua_name    => 'get_vector',
  perl_name   => 'main::get_vector',  # OR func => \&get_vector
},
{
  lua_name      => 'add_vectors',
  func          => \&add_vectors,
},
{
  lua_name      => 'vector_list',
  func          => \&vector_list,
  context       => 'list',
}.
);

$lua->run( <<EOLUA );
vector1 = get_vector(4, 4, 4)
vector2 = get_vector(1, 2, 3)
vector3 = add_vectors(vector1, vector2)

print(vector3)
EOLUA
