use 5.010001;
use ExtUtils::MakeMaker;

my $instpath = '/share/opensim/lib';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    PREFIX            => $instpath,
    LIB               => $instpath,
    NAME              => 'Simian',
    VERSION_FROM      => 'lib/Simian.pm', # finds $VERSION
    AUTHOR            => 'Mic Bowman <cmickeyb@gmail.com>',
    PREREQ_PM         => {
        # Used to create identities in useradmin.pl
        "Digest::MD5"	=> 0,

        # Used to communicate with the Simian services
        "JSON"		=> 0,
        "LWP::UserAgent" => 0,
    },
);
