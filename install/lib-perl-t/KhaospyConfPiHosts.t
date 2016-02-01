#!perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl/";
# by Karl Kount-Khaos Hoskin. 2015-2016

use Test::More 'no_plan';
use Test::Exception;
use Test::Deep;

use Sub::Override;
use Data::Dumper;

sub true  { 1 };
sub false { 0 };

use_ok ( "Khaospy::Conf::PiHosts"
    , 'get_pi_host_config'
    , 'get_pi_hosts_running_daemon'
);

# TODO test the loading of a JSON file, for the pi-hosts .

# stop the host resolution from dying.

my $pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};
my $override_get_pi_hosts_conf
    = Sub::Override->new(
        'Khaospy::Conf::PiHosts::get_pi_hosts_conf',
        sub {
            # simulate the forced setting of the cached
            # $pi_hosts_conf and its validation
            Khaospy::Conf::PiHosts::_set_pi_hosts_conf(
                $pi_hosts_return
            );
            Khaospy::Conf::PiHosts::_validate_pi_hosts_conf();
            return $pi_hosts_return;
        }
);

#######################
# Testing Khaospy::Conf::PiHosts
my $pi_host_cfg ;

# TODO actually test this.

throws_ok { get_pi_hosts_running_daemon('bad-daemon-name') }
    qr/invalid.*?type/,
    "dies";

#############################
# one-wire-thermometer conf :

#
#ok ( $cont_cfg = get_control_config('therm-loft') , "Can get onewire-thermometer control");
#cmp_deeply( $cont_cfg, $controls_return->{'therm-loft'} , "Got the control data" );
#
#

