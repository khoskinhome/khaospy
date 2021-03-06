#!/usr/bin/perl
use strict; use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2017

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Data::Dumper;

use Khaospy::Conf::Controls;
use Khaospy::Conf::PiHosts;
use Khaospy::Conf::Global;

use Khaospy::Conf qw/
    get_daemon_runner_conf
    get_one_wire_heating_control_conf
    get_boiler_conf
/;

my $conf_rc = [
    \&Khaospy::Conf::Controls::get_controls_conf,
    \&get_daemon_runner_conf,
    \&get_one_wire_heating_control_conf,
    \&get_boiler_conf,
    \&Khaospy::Conf::get_global_conf,
    \&Khaospy::Conf::PiHosts::get_pi_hosts_conf,
];

for my $rc ( @$conf_rc ) {
    print Dumper ( $rc->() );
}

