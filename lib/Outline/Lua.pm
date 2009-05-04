package Outline::Lua;

use warnings;
use strict;

use Scalar::Util qw( looks_like_number );
use Data::Dumper;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Outline::Lua', $VERSION);

sub register_perl_func {
  my $self = shift;
  my %args = @_;

  $args{perl_func} = $args{func} if defined $args{func} and not defined $args{perl_func};

  defined $args{$_} or die "register_perl_func: required argument $_" for qw( perl_func );

  ($args{lua_name} = $args{perl_func}) =~ s/.*:://g if not defined $args{lua_name};

  $self->_add_func( $args{lua_name},
                    \%args );
}

sub run {
  my $self  = shift;

  $self->_run(@_);
}

sub _table_to_ref_p { # the p stands for perl to make it different from the XS one.
  my $want_array = shift;

  # Uhh ... what am I doing? Passing in pairs of stuff...
  # If we want an array, sort the keys and take the values;
  # if we want a hash, well, we have a hash.
  # OK here goes.
  my %gumpf = @_;

  my $retval = \%gumpf;
  return $retval unless $want_array;

  $retval = [ @gumpf{ sort { _key_cmp($a, $b) } keys %gumpf } ];
  return $retval;
}

# Sort the keys numbers first in number order, then strings in string order
sub _key_cmp {
  my ($a, $b) = @_;

  return -1 if looks_like_number($a) and not looks_like_number($b);
  return  1 if looks_like_number($b) and not looks_like_number($a);

  return $a <=> $b if looks_like_number($a) and looks_like_number($b);
  return $a cmp $b; 

}

1;

__END__

=head1 NAME

Outline::Lua - Not Inline!

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Register your Perl functions with Lua, then run arbitrary Lua
code.

=head1 SYNOPSIS


    use Outline::Lua;

    my $lua = Outline::Lua->new();
    $lua->register_perl_func(perl_func => 'MyApp::dostuff');

    if (my $error = $lua->run($lua_code)) {
      die $lua->errorstring;
    }
    else {
      my @return_vals = $lua->return_vals();
    }

=head1 EXPORT

Currently none.

=head1 METHODS

=head2 new

Create a new Outline::Lua object, with its own Lua environment.

=head2 register_perl_func

Register a Perl function by (fully-qualified) name into the Lua
environment. Currently upvalues and subrefs are not supported.

=head3 Args

=over

=item {perl_func|func} => string

The fully-package-qualified function to register with Lua.

TODO: support a) upvalues and b) subrefs

=item lua_name => string

The name by which the function will be called within the Lua script.
Defaults to the unqualified name of the perl function.

=back

=head1 AUTHOR

Alastair Douglas, C<< <altreus at perl.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-outline-lua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Outline-Lua>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Outline::Lua


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Outline-Lua>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Outline-Lua>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Outline-Lua>

=item * Search CPAN

L<http://search.cpan.org/dist/Outline-Lua>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Alastair Douglas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
