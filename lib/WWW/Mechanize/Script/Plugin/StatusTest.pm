package WWW::Mechanize::Script::Plugin::StatusTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

# ABSTRACT: prove expected HTTP status of the response

our $VERSION = '0.001_004';

use 5.014;

=method check_value_names()

Returns qw(response).

=cut

sub check_value_names
{
    return qw(response);
}

=method check_response(\%check,$mech)

This methods proves whether the HTTP status code of the response matches the
value configured in I<response> and accumulates I<response_code> into I<$code>
when not.

Return the accumulated I<$code> and appropriate constructed message, if
coparisation failed.

=cut

sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $response_code = 0 + $self->get_check_value( $check, "response" );

    if ( $response_code != $mech->status() )
    {
        my $err_code = $self->get_check_value( $check, "response_code" ) // 1;
        return ( $err_code, "response code " . $mech->status() . " != $response_code" );
    }

    return (0);
}

1;
