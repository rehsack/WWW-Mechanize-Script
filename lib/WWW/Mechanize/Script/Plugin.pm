package WWW::Mechanize::Script::Plugin;

use strict;
use warnings;

our $VERSION = 0.001_001;

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

sub can_check
{
    my ( $self, $check ) = @_;
    my $ok = 0;

    my @value_names = $self->check_value_names();
    foreach my $value_name (@value_names)
    {
        my $cv = $self->get_check_value( $check, $value_name );
        $cv and $ok = 1;
    }

    return $ok;

}

sub check_value_names { ... }

sub check_response { ... }

1;
