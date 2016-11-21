#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::MACSwitchDaemon qw(
    run_mac_switch_daemon
);

use Khaospy::Constants qw(
    true false
);

use Getopt::Long;

my $nmap_iprange;
my $nmap_args;
my $timer;
my $help;

GetOptions (
    "i|ip|iprange=s" => \$nmap_iprange,
    "a|args=s"       => \$nmap_args,
    "t|timer=s"      => \$timer,
    "h|help"         => \$help,
) or usage();

usage() if $help;

run_mac_switch_daemon ( {
    nmap_iprange => $nmap_iprange,
    nmap_args    => $nmap_args,
    timer        => $timer,
} );

sub usage {
    print "khaospy-mac-switch-d.pl CLI options : \n";
    print "  -i --ip --iprange to nmap\n";
    print "  -a --args         to nmap\n";
    print "  -t --timer        how many seconds between nmap scans\n";
    exit 1;
}

exit 0;
