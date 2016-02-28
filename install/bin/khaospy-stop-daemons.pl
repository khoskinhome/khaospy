#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";
# by Karl Kount-Khaos Hoskin. 2015-2016
#
use Data::Dumper;

die "Not root user" if $>;

use Khaospy::Constants qw(
    $JSON
    $LOG_DIR
    $PID_DIR
);

use Khaospy::Conf::PiHosts qw(
    get_this_pi_host_config
);

chdir ($PID_DIR) or die "can't chdir to $PID_DIR\n";

for my $pidfile ( <*.pid> ) {
    my $cmd = sprintf ("/usr/bin/daemon --pidfiles=%s --stop --name=%s", $PID_DIR, $pidfile);
    say $cmd;
    system ( $cmd ) ;
}


