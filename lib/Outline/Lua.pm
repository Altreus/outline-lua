package Outline::Lua;

use warnings;
use strict;

use Scalar::Util qw( looks_like_number );
use List::Util qw( first );

our $VERSION = '0.01';
our $TRUE    = Outline::Lua::Boolean->true;
our $FALSE   = Outline::Lua::Boolean->false;

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

  if (my $keys = _try_lua_array(%gumpf)) {
    return $keys;
  }
  
  return \%gumpf unless $want_array;
  return [ @gumpf{ sort { _key_cmp($a, $b) } keys %gumpf } ];
}

sub _try_lua_array {
  my %hash = @_;
  return if( first { /\D/ } keys %hash );

  my @keys = sort { $a + 0 <=> $b + 0 } keys %hash;
  return if ($keys[0] != 1 or $keys[-1] != scalar @keys);

  return \@keys;
}

# Sort the keys numbers first in number order, then strings in string order
sub _key_cmp {
  my ($a, $b) = @_;

  return -1 if looks_like_number($a) and not looks_like_number($b);
  return  1 if looks_like_number($b) and not looks_like_number($a);

  return $a <=> $b if looks_like_number($a) and looks_like_number($b);
  return $a cmp $b; 

}

# The Boolean class is used to create $Outline::Lua::TRUE and 
# $Outline::Lua::FALSE. These are values specifically different from any other
# value in order that we can convert between Lua's boolean type and Perl's
# slightly more arbitrary truth concept.

package Outline::Lua::Boolean;

use overload (bool => sub { 
                shift->[0] ? 1 : "" 
              },
#              "==" => sub {
#                my ($lhs, $rhs) = @_;
#                return ($lhs && $rhs) || (!$lhs && !$rhs);
#              },
              fallback => 1,
);

sub true { bless [1], shift };

sub false { bless[ "" ], shift };

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

=head1 TYPE CONVERSIONS

Since this module is designed to allow Perl code to be run from
Lua code (and not for Perl code to be able to call Lua functions),
type conversion happens in only one situation for each direction:

=over

=item 

Perl values are converted to Lua when you return them I<from> 
a Perl function.

=item

Lua values are converted to Perl when you provide them as 
arguments I<to> a Perl function.

=back

Most Lua types map happily to Perl types. Lua has its own rules
about converting between types, with which you should be familiar.
Consult the Lua docs for these rules.

Outline::Lua, nevertheless, will try to help you on your way.

B<Note:> You should definitely read about Booleans because this is
the only place where it is not automagic.

=head2 Numbers

Numbers will *always* be passed as strings, whether you are
returning them to Lua or passing them to Perl.

The reason for this is that Perl will truncate the string
C<"2.000000"> to the number 2 if you numberify it - and in some
cases this will introduce a bug, because you wanted the literal
string C<"2.000000">. Lua's conversion method here is similar
enough to Perl's that there is no reason to ever convert it to
a number until you explicitly use it as a number in either the
Perl or the Lua side.

=head2 Strings

Strings are strings on both sides. No conversion is done.

=head2 Arrays and Hashes

Arrays and hashes are the same in Lua but not in Perl. Your
Lua table will appear in your Perl function as a hashref; and
your Perl hashref or arrayref will be converted to a Lua table.

A future release will allow for the setting of an auto-convert
flag. When set, this will automatically convert any table whose
keys, when sorted, comprise a range of integers beginning with
1 and ending with the same integer as the length of the range,
to an array. Basically, if it looks like it was an array in Lua,
you will get a Perl arrayref back.

=head2 Booleans

Lua has a boolean type more explicitly than Perl does. Perl is
happy to take anything that is not false as true and have done
with.

Therefore, two Perl variables exist, C<$Outline::Lua::TRUE> and
C<$Outline::Lua::FALSE>. These can be used in any boolean context
and Perl will behave correctly (since operator 'bool' is 
overloaded). 

When a boolean-typed value is given to us from a Lua call it will
be converted to one of these and you can test it happily. This
has the side effect of allowing you to use it as a string or number
as well, using Perl's normal conventions.

When you wish to return a boolean-typed value back to Lua from
your Perl function, simply return $Outline::Lua::TRUE or
$Outline::Lua::FALSE and it will be converted back into a Lua
boolean.

Unfortunately this is a necessary evil because of Lua's true/false
typing. There is no reasonable way of knowing that you intended to
return a true or false value back to Lua because the Lua code gives
no clues as to what sort of variable is being assigned *to*: 
there is no context.

However, Lua is dynamic, like Perl, so in some cases you might
be able to expect it to Do The Right Thing. That, however, is
up to Lua.

=head2 undef and nil

The undefined value in Perl and the nil value in Lua will be
considered equivalent, even though they are functionally slightly
different. The user is advised that returning undef instead of
one of the boolean values from a Perl function will not necessarily
do what they expect.

=head2 Functions

Functions are not yet supported but I have an idea of how it
could be done. Inline::Lua manages to cope with func refs, so
I can take ideas from that.

=head1 EXPORT

Currently none.

=head1 METHODS

=head2 new

Create a new Outline::Lua object, with its own Lua environment.

=head2 register_perl_func

Register a Perl function by (fully-qualified) name into the Lua
environment. Currently upvalues and subrefs are not supported.

=head3 Args

TODO: support a) upvalues, b) subrefs and c) an array of hashrefs.

=over

=item {perl_func|func} => string

The fully-package-qualified function to register with Lua.

=item lua_name => string

The name by which the function will be called within the Lua script.
Defaults to the unqualified name of the perl function.

=back

=head2 run

Run lua code! Currently, the return values from the Lua itself have
not been implemented, but that is a TODO so cut me some slack.

=head3 Args

=over

=item $str

A string containing the Lua code to run.

=back

=head1 AUTHOR

Alastair Douglas, C<< <altreus at perl.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-outline-lua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Outline-Lua>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

=over

=item Function prototypes

To give the converter a bit of a clue as to what we're trying to
convert to.

=item Always/sometimes/never array conversion

Part of the above, we can implicitly convert any hash into an array
if we want to.

=item Func refs

Registering a Perl funcref instead of a real function is possible
but I haven't got around to stealing it from Tassilo von Parseval
yet.

=item Return values from the Lua itself

Have not yet implemented the return value of the Lua code itself,
which is supposed to happen.

=back

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

Thanks or maybe apologies to Tassilo von Parseval, author of Inline::Lua.
I took a fair amount of conversion code from Inline::Lua, which module
is the whole reason I wrote this one in the first place: and I think
I'll be nicking a bit more too!

=head1 COPYRIGHT & LICENSE

Copyright 2009 Alastair Douglas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
