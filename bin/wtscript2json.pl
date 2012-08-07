#! perl

use strict;
use warnings;

use v5.10.1;

use File::Slurp qw(write_file);
use Getopt::Long;
use JSON ();
use List::MoreUtils qw(zip);
use Params::Util qw(_ARRAY);
use Pod::Usage;

use WWW::Mechanize::Script::Util qw(:ALL);
use WWW::Mechanize::Script;

my $VERSION = 0.001;
my %opts;
my @options = ( "input-files=s@", "output-files=s@", "output-pattern=s{2}", "help|h", "usage|?" );

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
opt_required_all( \%opts, qw(input-files) );
opt_exclusive( \%opts, qw(output-files output-pattern) );
opt_required_one( \%opts, qw(output-files output-pattern) );
_ARRAY( $opts{"input-files"} )
  and _ARRAY( $opts{"output-files"} )
  and scalar( @{ $opts{"input-files"} } ) != scalar( @{ $opts{"output-files"} } )
  and pod2usage(
                 {
                   -message => "Count of --input-files and --output-files doesn't match",
                   -exitval => 1
                 }
               );

my %in2out =
    _ARRAY( $opts{"input-files"} )
  ? zip( @{ $opts{"input-files"} }, @{ $opts{"output-files"} } )
  : map {
    my $f = $_;
    $f =~ s/$opts{"output-pattern"}->[0]/$opts{"output-pattern"}->[1]/;
    ( $_, $f );
  } @{ $opts{"input-files"} };
my %cfg = load_config();

my $coder = JSON->new();
_ARRAY( $cfg{wtscript_extensions} )
  and Config::Any::WTScript->extensions( @{ $cfg{wtscript_extensions} } );
foreach my $filename ( @{ $opts{"input-files"} } )
{
    my @script_files = find_scripts( \%cfg, $filename );
    my $scripts = Config::Any->load_files(
                                           {
                                             files           => [@script_files],
                                             use_ext         => 1,
                                             flatten_to_hash => 1,
                                           }
                                         );
    @script_files = keys %{$scripts};
    scalar(@script_files) > 1
      and pod2usage(
                   {
                     -message => "filename $filename is ambigious: " . join( ", ", @script_files ),
                     -exitval => 1
                   }
      );
    scalar(@script_files) < 1
      and next;    # file not found or not parsable ...
                   # merge into default and previous loaded config ...
    my $json = $coder->pretty->encode( $scripts->{ $script_files[0] } );
    write_file( $in2out{$filename}, $json );
}

__END__

=head1 NAME

check_web2 - allows checking of website according to configured specifications

=head1 DESCRIPTION

check_web2 is intended to be used to check web-sites according a configuration.
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
