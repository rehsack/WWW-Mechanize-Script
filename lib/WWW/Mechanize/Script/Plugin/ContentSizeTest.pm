package WWW::Mechanize::Script::Plugin::ContentSizeTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

our $VERSION = '0.001_002';

use 5.014;

sub check_value_names
{
    return qw(min_bytes max_bytes);
}

sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $code = 0;
    my $msg;

    my $min_bytes = $self->get_check_value( $check, "min_bytes" );
    my $max_bytes = $self->get_check_value( $check, "max_bytes" );
    my $content_len = length $mech->response()->content();

    if ( defined($min_bytes) and $min_bytes > $content_len )
    {
        my $err_code = $self->get_check_value( $check, "min_bytes_code" ) // 1;
        $code = &{ $check->{compute_code} }( $code, $err_code );
        $msg = "received $content_len bytes exceeds lower threshold ($min_bytes)";
    }

    if ( defined($max_bytes) and $max_bytes < $content_len )
    {
        my $err_code = $self->get_check_value( $check, "max_bytes_code" ) // 1;
        $code = &{ $check->{compute_code} }( $code, $err_code );
        if ($msg)
        {
            $msg .= " and upper threshold ($max_bytes )";
        }
        else
        {
            $msg = "received $content_len bytes exceeds upper limit ($max_bytes)";
        }
    }

    return ( $code, ( $msg ? ($msg) : () ) );
}

1;
