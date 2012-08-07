package WWW::Mechanize::Script::Plugin::TextMatchTest;

use strict;
use warnings;

use parent qw(WWW::Mechanize::Script::Plugin);

use Params::Util qw(_ARRAY0);

our $VERSION = '0.001_002';

use 5.014;

sub check_value_names
{
    return qw(text_forbid text_require);
}

sub check_response
{
    my ( $self, $check, $mech ) = @_;

    my $text_require = $self->get_check_value( $check, "text_require" );
    my $text_forbid = $self->get_check_value( $check, "text_forbid" );
    my $ignore_case = $self->get_check_value_as_bool( $check, "ignore_case" );
    my $content = $mech->is_html() ? $mech->text() : $mech->content();

    _ARRAY0($text_require) or $text_require = [$text_require];
    _ARRAY0($text_forbid) or $text_forbid = [$text_forbid];

    my @match_fails;
    my $code = 0;
    my $case_ign = $ignore_case ? "(?i)" : "";
    my @msg;
    foreach my $text_line ( @{$text_require} )
    {
	if ( $content !~ m/$case_ign\Q$text_line\E/ )
	{
	    my $err_code = $self->get_check_value( $check, "text_require_code" ) // 1;
	    $code = &{ $check->{compute_code} }( $code, $err_code );
	    push( @match_fails, $text_line );
	}
    }
    @match_fails and push(@msg, "required text " . join( ", ", map { "'" . $_ . "'" } @match_fails ) . " not found in received content");

    @match_fails = ();
    foreach my $text_line ( @{$text_forbid} )
    {
	if ( $content =~ m/$case_ign\Q$text_line\E/ )
	{
	    my $err_code = $self->get_check_value( $check, "text_forbid_code" ) // 1;
	    $code = &{ $check->{compute_code} }( $code, $err_code );
	    push( @match_fails, $text_line );
	}
    }
    @match_fails and push(@msg, "forbidden text " . join( ", ", map { "'" . $_ . "'" } @match_fails ) . " found in received content");

    if( $code or @msg )
    {
	return ($code, @msg);
    }

    return (0);
}

1;
