package t::Outline::Lua::perl_to_lua;

use strict;
use warnings;

use Test::Class;
use Test::More 'no_plan';
use base qw( Test::Class );

use Outline::Lua;

# These are here until I implement funcref registration.
sub test_nothing {
  return;
}

sub test_hashref {
  +{
    test1 => 'one',
    test2 => 'two',
  };
}

sub test_arrayref {
  [
    1..10
  ];
}

sub test_string {
  "foo";
}

sub test_number {
  10
}

sub test_multivar {
  1..10;
}

sub test_undef {
  undef;
}

sub setup : Test( setup ) {
  my $self = shift;

  $self->{lua} = Outline::Lua::new;
}

sub t01_void_context : Tests {
  my $self = shift;
  my $lua  = $self->{lua};

  $lua->register_perl_func(
    perl_func => __PACKAGE__ . '::test_nothing',
  };
  my $lua_code = <<EOLUA;
foo = test_nothing();
print foo;

EOLUA

  $lua->run( $lua_code );
}

1;

__END__

