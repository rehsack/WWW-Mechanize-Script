package WWW::Mechanize::Script::Plugin;

use strict;
use warnings;

# ABSTRACT: plugin base class for check plugins

our $VERSION = '0.001_003';

use 5.014;

=method new()

Instantiates new WWW::Mechanize::Script::Plugin. This is an abstract class.

=cut

sub new
{
    my ($class) = @_;

    my $self = bless( {}, $class );

    return $self;
}

=method get_check_value(\%check,$value_name)

Retrieves the value for I<$value_name> from the hash I<%check>.

=cut

sub get_check_value
{
    my ( $self, $check, $value_name ) = @_;

    $value_name or return;

    return $check->{check}->{$value_name};
}

=method get_check_value_as_bool(\%check,$value_name)

Retrieves the value for I<$value_name> from the hash I<%check> and returns
true when it can be interpreted as a boolean value with true content
(any object is always returned as it is, (?:(?i)true|on|yes) evaluates to
I<true>, anything else to I<false>).

=cut

sub get_check_value_as_bool
{
    my ( $self, $check, $value_name ) = @_;

    $value_name or return;

    my $val = $check->{check}->{$value_name};

    defined($val) or return;
    ref($val) and return $val;
    if ( _STRING($val) )
    {
        $val =~ m/(?:true|on|yes)/i and return 1;
    }

    return 0;
}

=method can_check(\%check)

Proves whether this instance can check anything on the current run test.
Looks if any of the required L</check_value_names> are specified in the
check parameters of the current test.

=cut

sub can_check
{
    my ( $self, $check ) = @_;
    my $ok = 0;

    my @value_names = $self->check_value_names();
    foreach my $value_name (@value_names)
    {
        my $cv = $self->get_check_value( $check, $value_name );
        $cv and $ok = 1 and last;
    }

    return $ok;

}

=method check_value_names()

Returns list of check values which are used to check the response.

Each I<value> has a I<value>C<_code> counterpart which is used to modify
the return value of L</check_response> when the check upon that value
fails.

=cut

sub check_value_names { ... }

=method check_response(\%check,$mech)

Checks the response based on test specifications. See individual plugins
for specific test information.

Returns the accumulated code for each failing check along with optional
messages containing details about each failure.

  # no error
  return (0);
  # some error
  return ($code,@messages);
  # some error but no details
  return ($code);

=cut

sub check_response { ... }

1;
