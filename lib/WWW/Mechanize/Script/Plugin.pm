package WWW::Mechanize::Script::Plugin;

use strict;
use warnings;

our $VERSION = '0.001_002';

use 5.014;

sub new
{
    my ( $class, $default ) = @_;

    my $self = bless( { %{$default} }, $class );

    return $self;
}

sub get_check_value
{
    my ( $self, $check, $value_name ) = @_;

    $value_name or return;

    return $check->{check}->{$value_name} // $self->{check}->{$value_name};
}

sub get_check_value_as_bool
{
    my ( $self, $check, $value_name ) = @_;

    $value_name or return;

    my $val = $check->{check}->{$value_name} // $self->{check}->{$value_name};

    defined($val) or return;
    ref($val) and return $val;
    if(_STRING($val))
    {
	$val =~ m/(?:true|on|yes)/i and return 1;
    }

    return 0;
}

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

sub check_value_names { ... }

sub check_response { ... }

1;
