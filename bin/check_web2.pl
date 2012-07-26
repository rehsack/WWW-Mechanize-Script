#! perl

use strict;
use warnings;

use v5.10.1;

use Config::Any;
use File::Basename qw(fileparse);
use File::ConfigDir qw(config_dirs);
use File::Find::Rule;
use Getopt::Long;
use Hash::Merge ();
use Pod::Usage;
use POSIX qw(isatty);

use WWW::Mechanize::Script;

my $VERSION = 0.001;
my %opts;
my @options = ( "file=s", "help|h", "usage|?" );

GetOptions( \%opts, @options ) or pod2usage(2);

defined( $opts{help} )
  and $opts{help}
  and pod2usage(
                 {
                   -verbose => 2,
                   -exitval => 0
                 }
               );
defined( $opts{usage} ) and $opts{usage} and pod2usage(1);
defined( $opts{file} ) or isatty(*STDOUT) ? pod2usage(1) : die "Missing --file argument";

my %cfg = (
          defaults => {
              save_output    => 'yes',
              ignore_case    => 'yes',
              show_html      => 'yes',
              accept_cookies => 'yes',
              show_cookie    => 'yes',
              show_headers   => 'yes',
              send_cookie    => 'yes',
              terse          => 'failed_only',
              request        => {
                  agent => {
                      agent => (
                          ( $opts{file} =~ /(_w$|^wap\/)/ )
                          ? "Nokia6210/1.0 (03.01) UP.Link/5.0.0.4 VZDE-check_wap $VERSION"
                          : "Mozilla/5.0 (Windows; U; WinNT4.0; en-US; rv: VZDE-check_web $VERSION)"
                      )
                  }
              },
              text_forbid => [
                               'Premature end of script headers',
                               'Error processing directive',
                               'XML Parsing partner document',
                               'sun.io.MalformedInputException',
                               'an error occurred while processing this directive'
                             ],
                      },
          );

# find config file
my @cfg_dirs    = config_dirs();
my $progname    = fileparse( $0, qr/\.[^.]*$/ );
my @cfg_pattern = map { $progname . "." . $_ } Config::Any->extensions();
my @cfg_files   = File::Find::Rule->file()->name(@cfg_pattern)->maxdepth(1)->in(@cfg_dirs);
if (@cfg_files)
{
    my $merger = Hash::Merge->new('LEFT_PRECEDENT');
    # read config file(s)
    my $all_cfg = Config::Any->load_files(
                                           {
                                             files           => [@cfg_files],
                                             use_ext         => 1,
                                             flatten_to_hash => 1,
                                           }
                                         );

    foreach my $filename (@cfg_files)
    {
        defined( $all_cfg->{$filename} )
          or next;    # file not found or not parsable ...
                      # merge into default and previous loaded config ...
        %cfg = %{ $merger->merge( \%cfg, $all_cfg->{$filename} ) };
    }
}

do
{
    my %cfgvar = ( OPTS_FILE => $opts{file} );
    my $cfgkeys = join( "|", keys %cfgvar );
    $cfg{summary}->{target} =~ s/@($cfgkeys)[@]/$cfgvar{$1}/ge;
    $cfg{report}->{target}  =~ s/@($cfgkeys)[@]/$cfgvar{$1}/ge;
} while (0);

my $wms = WWW::Mechanize::Script->new( \%cfg );

if ( -f $opts{file} and -r $opts{file} )
{
    @cfg_files = ( $opts{file} );
}
else
{
    my ( $volume, $directories, $fn ) = File::Spec->splitpath( $opts{file} );
    @cfg_dirs = config_dirs( $cfg{script_dir} // "check_web" );
    @cfg_dirs =
      grep { -d $_ }
      map { File::Spec->catdir( $_, $directories ) }
      config_dirs( $cfg{script_dir} // "check_web" );    # XXX basename $0
    @cfg_pattern = map { $fn . "." . $_ } Config::Any->extensions();
    @cfg_files = File::Find::Rule->file()->name(@cfg_pattern)->maxdepth(1)->in(@cfg_dirs);
}

my ( $code, @msgs ) = (0);
eval {
    my @script;
    my $scripts = Config::Any->load_files(
                                           {
                                             files           => [@cfg_files],
                                             use_ext         => 1,
                                             flatten_to_hash => 1,
                                           }
                                         );
    foreach my $filename (@cfg_files)
    {
        defined( $scripts->{$filename} )
          or next;    # file not found or not parsable ...
                      # merge into default and previous loaded config ...
        push( @script, @{ $scripts->{$filename} } );
    }
    ( $code, @msgs ) = $wms->run_script(@script);
};
$@ and say("UNKNOWN - $@");
exit( $@ ? 255 : $code );

__END__

=head1 NAME

check_web2 - allows checking of website according to configured specifications

=head1 DESCRIPTION

check_web2 is intended to be used to check web-sites accoring a configuration.
The configuration covers the request configuration (including agent part) and
check configuration to specify check parameters.

See C<WWW::Mechanize::Script> for details about the configuration options.

=head2 HISTORY

This script is created as successor of an check_web script of a nagios setup
based on HTTP::WebCheck. This module isn't longer maintained, so decision
was made to create a new environment simulating the old one basing on
WWW::Mechanize.

=head1 SYNOPSIS

  $ check_web2 --file domain1/site1.json
  $ check_web2 --file domain2/site1.yml
  # for compatibility
  $ check_web2 --file domain1/site2.wts

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-mechanize-script at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Script>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW:Mechanize::Script

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Mechanize-Script>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Mechanize-Script>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Mechanize-Script/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
