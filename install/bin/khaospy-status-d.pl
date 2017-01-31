#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::StatusD qw(
    run_status_d
);

use Khaospy::Conf::Global qw(
);

use Khaospy::Constants qw(
    $DB_CONTROL_STATUS_DAYS_HISTORY
    $DB_CONTROL_STATUS_PURGE_TIMEOUT_SECS
);

use Getopt::Long;

my %opts = (
    "d|days|days-to-keep=i"   => \my $days_to_keep,
    "p|purge|purge-seconds=i" => \my $purge_secs,
    "l|log-level=s"           => \my $log_level,
    "h|help"                  => \my $help,
) or usage();

GetOptions (%opts);

$days_to_keep = $days_to_keep ||
    $DB_CONTROL_STATUS_DAYS_HISTORY;

$purge_secs   = $purge_secs ||
    $DB_CONTROL_STATUS_PURGE_TIMEOUT_SECS;

usage() if $help;
run_status_d( {
   days_to_keep => $days_to_keep,
   purge_secs   => $purge_secs,
   log_level    => $log_level,
   help         => $help,
});

sub usage {
    print "CLI params :\n";
    print "  ".join "\n  ", sort keys %opts;
    print "\n";
    exit 0 ;
}

exit 0;
