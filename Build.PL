use 5.008;
use strict;
use warnings;

use Config;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Mechanize::Script',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/WWW/Mechanize/Script.pm',
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
        'Module::Build' => '0.38',
    },
    requires => {
        'perl' => 5.014,
	'Config::Any' => 0,
	'File::Basename' => 0,
	'File::ConfigDir' => '0.004',
	'File::Slurp' => 0,
	'Hash::Merge' => 0.12,
	'JSON' => '2.00',
	'List::MoreUtils' => '0.22',
	'Module::Pluggable' => '4.0',
	'Params::Util' => '0.33',
	'Template' => '2.20',
	'WWW::Mechanize' => '1.72',
	'WWW::Mechanize::Timed' => '0.44',
    },
    add_to_cleanup => [ 'WWW-Mechanize-Script-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
