package WWW::Mechanize::Script;

use strict;
use warnings;

use File::Basename qw(fileparse);
use File::Path qw(make_path);
use Hash::Merge               ();
use IO::File;
use Module::Pluggable::Object ();
use Template                  ();
use WWW::Mechanize            ();
use WWW::Mechanize::Timed     ();

=head1 NAME

WWW::Mechanize::Script - fetch websites and executes tests on the results

=head1 SYNOPSIS

  use WWW::Mechanize::Script;

  my $wms = WWW::Mechanize::Script->new();
  $wms->run_script(@script);

  foreach my $test (@script) {
    $wms->run_test(%{$test});
  }

=head1 METHODS

=cut

our $VERSION = 0.001_001;

sub new
{
    my ( $class, $cfg ) = @_;

    my $self = bless( { cfg => { %{$cfg} } }, $class );

    my $default = $cfg->{default};

    return $self;
}

sub _gen_code_compute
{
    my $check_cfg = $_[0];
    my $compute_code;

    if ( defined( $check_cfg->{code_func} ) )
    {
        my $compute_str = "sub { " . $check_cfg->{code_func} . " };";
        $compute_code = eval $compute_str;
        $@ and die $@;
    }

    if ( !defined($compute_code) and defined( $check_cfg->{code_cmp} ) )
    {
        my $compute_str =
            "sub { my (\$cur,\$new) = \@_; \$cur "
          . $check_cfg->{code_cmp}
          . " \$new ? \$cur : \$new; };";
        $compute_code = eval $compute_str;
        $@ and die $@;
    }

    if ( !defined($compute_code) )
    {
        my $compute_str = "sub { my (\$cur,\$new) = \@_; \$cur > \$new ? \$cur : \$new; };";
        $compute_code = eval $compute_str;
        $@ and die $@;
    }

    return $compute_code;
}

=head2 test_plugins( )

The C<plugins()> classmethod returns the names of configuration loading plugins as 
found by L<Module::Pluggable::Object|Module::Pluggable::Object>.

=cut

sub test_plugins
{
    my ( $self, $test ) = @_;

    unless ( defined( $self->{all_plugins} ) )
    {
        my $plugin_base = join( "::", __PACKAGE__, "Plugin" );
        my $finder =
          Module::Pluggable::Object->new(
                                          require     => 1,
                                          search_path => [$plugin_base],
                                          except      => [$plugin_base],
                                          inner       => 0,
                                          only        => qr/^${plugin_base}::\p{Word}+$/,
                                        );

        # filter out things that don't look like our plugins
        my @ap =
          map  { $_->new( $self->{cfg}->{defaults} ) }
          grep { $_->isa($plugin_base) } $finder->plugins();
        $self->{all_plugins} = \@ap;
    }

    my @tp = grep { $_->can_check($test) } @{ $self->{all_plugins} };
    return @tp;
}

sub get_request_value
{
    my ( $self, $request, $value_name ) = @_;

    $value_name or return;

    return $request->{$value_name} // $self->{cfg}->{default}->{request}->{$value_name};
}

sub _get_target
{
    my $def = shift;

    my $target = $def->{target};
    $target //= "-";

    if( $target ne "-" and $def->{append} )
    {
	my ($name,$path,$suffix) = fileparse($target);
	-d $path or make_path($path);
	my $fh = IO::File->new($target, ">>");
	$fh->seek(0,SEEK_END);
	$target = $fh;
    }

    return $target;
}

my @codes = qw(OK WARNING CRITICAL UNKNOWN DEPENDENT EXCEPTION);

sub summarize
{
    my ( $self, $code, @msgs ) = @_;

    my %vars = (
                 CODE      => $code,
                 CODE_NAME => $codes[$code] // $codes[-1],
                 MESSAGES  => [@msgs]
               );

    my $input = $self->{cfg}->{summary}->{source} // \$self->{cfg}->{summary}->{template};
    my $output = _get_target($self->{cfg}->{summary});
    my $template = Template->new();
    $template->process( $input, \%vars, $output )
      or die $template->error();

    return;
}

sub gen_report
{
    my ( $self, $full_test, $mech, $code, @msgs ) = @_;
    my $response = $mech->response();
    my %vars = (
                 CODE      => $code,
                 CODE_NAME => $codes[$code] // $codes[-1],
                 MESSAGES  => [@msgs],
                 RESPONSE  => {
                               CODE    => $response->code(),
                               CONTENT => $response->content(),
                               BASE    => $response->base(),
                               HEADER  => {
                                           map { $_ => $response->headers()->header($_) }
                                             $response->headers()->header_field_names()
                                         },
                               CODE => $response->code(),
                             }
               );

    my $input = $self->{cfg}->{report}->{source} // \$self->{cfg}->{report}->{template};
    my $output = _get_target($self->{cfg}->{report});
    my $template = Template->new();
    $template->process( $input, \%vars, $output )
      or die $template->error();

    return;
}

sub run_script
{
    my ( $self, @script ) = @_;
    my $code = 0;    # XXX
    my @msgs;
    my $compute_code = _gen_code_compute( $self->{cfg}->{defaults}->{check} );

    foreach my $test (@script)
    {
        my ( $test_code, @test_msgs ) = $self->run_test($test);
        $code = &{$compute_code}( $code, $test_code );
        push( @msgs, @test_msgs );
    }

    if ( $self->{cfg}->{summary} )
    {
        my $summary = $self->summarize( $code, @msgs );
    }

    return ( $code, @msgs );
}

sub run_test
{
    my ( $self, $test ) = @_;

    my $merger = Hash::Merge->new('LEFT_PRECEDENT');
    my $full_test = $merger->merge( $test, $self->{cfg}->{defaults} );

    my $mech = WWW::Mechanize::Timed->new();
    foreach my $akey ( keys %{ $full_test->{request}->{agent} } )
    {
        # XXX clone and delete array args before
        $mech->$akey( $full_test->{request}->{agent}->{$akey} );
    }

    my $method = $full_test->{request}->{method};
    defined( $test->{request}->{http_headers} )
      ? $mech->$method( $full_test->{request}->{uri}, %{ $full_test->{request}->{http_headers} } )
      : $mech->$method( $full_test->{request}->{uri} );

    $full_test->{compute_code} = _gen_code_compute( $full_test->{check} );

    my $code = 0;
    my @msgs;
    foreach my $tp ( $self->test_plugins($full_test) )
    {
        my ( $plug_code, @plug_msgs ) = $tp->check_response( $full_test, $mech );
        $code = &{ $full_test->{compute_code} }( $code, $plug_code );
        push( @msgs, @plug_msgs );
    }

    if ( $self->{cfg}->{report} )
    {
        $self->gen_report( $full_test, $mech, $code, @msgs );
    }

    return ( $code, @msgs );
}

1;
