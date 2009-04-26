package Outline::Lua;

use warnings;
use strict;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Outline::Lua', $VERSION);

sub register_perl_func {
  my $self = shift;
  my %args = shift;

  if (!$args{context}) {
    if ($args{num_ret} > 1) {
      $args{context} = 'list';
    }

    elsif ($args{num_ret} == 1) {
      $args{context} = 'scalar';
    }

    else {
      $args{context} = 'void';
    }
  }

  $self->_add_func( $args{function},
                    $args{lua_name},
                    $args{num_args},
                    $args{num_ret},
                    $args{context}  );
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
    $lua->register_perl_func('MyApp::dostuff');

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

=item function => string

The fully-package-qualified function to register with Lua. 

TODO: support a) upvalues and b) subrefs

=item lua_name => string

The name by which the function will be called within the Lua script.

=item num_args => int

The number of arguments the function expects.

Variable argument numbers are not (yet) supported.

=item num_ret => int

Number of values the function returns.

Variable return lengths are not (yet) supported.

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
