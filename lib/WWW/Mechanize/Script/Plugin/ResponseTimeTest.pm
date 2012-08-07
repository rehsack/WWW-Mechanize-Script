package WWW::Mechanize::Script::Plugin::ResponseTimeTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

our $VERSION = '0.001_002';

use 5.014;

sub check_value_names
{
    return qw(min_elapsed_time max_elapsed_time);
}

sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $code = 0;
    my $msg;

    my $min_time = $self->get_check_value( $check, "min_elapsed_time" );
    my $max_time = $self->get_check_value( $check, "max_elapsed_time" );
    my $total_time = $mech->client_elapsed_time();

    if ( defined($min_time) and $min_time > $total_time )
    {
        my $err_code = $self->get_check_value( $check, "min_elapsed_time_code" ) // 1;
        $code = &{ $check->{compute_code} }( $code, $err_code );
        $msg = "elapsed time $total_time exceeded lower threshold ($min_time)";
    }
    if ( defined($max_time) and $max_time < $total_time )
    {
        my $err_code = $self->get_check_value( $check, "max_elapsed_time_code" ) // 1;
        $code = &{ $check->{compute_code} }( $code, $err_code );
        if ($msg)
        {
            $msg .= " and upper threshold ($max_time)";
        }
        else
        {
            $msg = "elapsed time $total_time exceeded upper threshold ($max_time)";
        }
    }

    return ( $code, ( $msg ? ($msg) : () ) );
}

1;

