package WWW::Mechanize::Script::Plugin::TextMatchTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

use Params::Util qw(_ARRAY);

our $VERSION = '0.001_002';

use 5.014;

sub check_value_names
{
    return qw(text_require);
}

sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $text_require = $self->get_check_value( $check, "text_require" );
    my $content = $mech->is_html() ? $mech->text() : $mech->content();

    if ( _ARRAY($text_require) )
    {
        my @not_found;
        my $err_code = 0;
        foreach my $text_line ( @{$text_require} )
        {
            if ( $content !~ $text_line )
            {
                $err_code = $self->get_check_value( $check, "text_require_code" ) // 1;
                push( @not_found, $text_line );
            }
        }
        if ($err_code)
        {
            return (
                     $err_code,
                     "required text "
                       . join( ", ", map { "'" . $_ . "'" } @not_found )
                       . " not found in received content"
                   );
        }
    }
    elsif ( $content !~ $text_require )
    {
        my $err_code = $self->get_check_value( $check, "text_require_code" ) // 1;
        return ( $err_code, "required text $text_require not found in received content" );
    }

    return (0);
}

1;
