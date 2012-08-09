package WWW::Mechanize::Script::Plugin::StatusTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

# ABSTRACT: prove expected HTTP status of the response

our $VERSION = '0.001_003';

use 5.014;

sub check_value_names
{
    return qw(response);
}

sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $response_code = $self->get_check_value( $check, "response" );

    if ( $response_code != $mech->status() )
    {
        my $err_code = $self->get_check_value( $check, "response_code" ) // 1;
        return ( $err_code, "response code " . $mech->status() . " != $response_code" );
    }

    return (0);
}

1;
