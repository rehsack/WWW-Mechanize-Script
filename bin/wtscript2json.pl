#! perl

use strict;
use warnings;

# PODNAME: wtscript2json
# ABSTRACT: convert read configuration into JSON

use v5.10.1;

use File::Slurp qw(write_file);
use Getopt::Long;
use JSON ();
use List::MoreUtils qw(zip);
use Params::Util qw(_ARRAY);
use Pod::Usage;

use WWW::Mechanize::Script::Util qw(:ALL);
use WWW::Mechanize::Script;

our $VERSION = '0.001_003';
my %opts = (
             "input-files"    => [],
             "output-files"   => [],
             "output-pattern" => []
           );
my @options = (
                "input-files=s@"      => $opts{"input-files"},
                "output-files=s@"     => $opts{"output-files"},
                "output-pattern=s{2}" => $opts{"output-pattern"},
                "help|h", "usage|?"
              );

GetOptions( \%opts, @options ) or pod2usage(2);

# clean-up defaults
@{ $opts{"input-files"} }    or delete $opts{"input-files"};
@{ $opts{"output-files"} }   or delete $opts{"output-files"};
@{ $opts{"output-pattern"} } or delete $opts{"output-pattern"};

# check ...
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
    _ARRAY( $opts{"output-files"} )
  ? zip( @{ $opts{"input-files"} }, @{ $opts{"output-files"} } )
  : ();
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
    if ( $opts{"output-files"} )
    {
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
    else
    {
        while ( my ( $script_file, $script ) = each(%$scripts) )
        {
            my $json = $coder->pretty->encode($script);
            ( my $target = $script_file ) =~
              s/$opts{"output-pattern"}->[0]/$opts{"output-pattern"}->[1]/;
            write_file( $target, $json );
        }
    }
}

__END__

