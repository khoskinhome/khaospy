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

use Khaospy::Constants qw(
    $ONE_WIRED_SENDER_SCRIPT
    $ONE_WIRED_RECEIVER_SCRIPT
    $HEATING_DAEMON_SCRIPT
    $BOILER_DAEMON_SCRIPT
    $PI_CONTROLLER_DAEMON_SCRIPT
    $COMMAND_QUEUE_DAEMON_SCRIPT

);

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
my $return ;

# TODO actually test this.

throws_ok { get_pi_hosts_running_daemon('bad-daemon-name') }
    KhaospyExcept::InvalidDaemonScriptName->new,
    "dies with bad script name";

lives_ok { get_pi_hosts_running_daemon( $PI_CONTROLLER_DAEMON_SCRIPT ) }
    "lives with good script name";

$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [
            {
                script=>$PI_CONTROLLER_DAEMON_SCRIPT,
                options =>{},
            },
            {
                script=>$COMMAND_QUEUE_DAEMON_SCRIPT,
                options =>{},
            },
        ],
    },
    pitestanother => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [
            {
                script=>$PI_CONTROLLER_DAEMON_SCRIPT,
                options =>{},
            },
            {
                script=>$ONE_WIRED_SENDER_SCRIPT,
                options =>{},
            },
        ],
    },

};

ok ( $return = get_pi_hosts_running_daemon( $PI_CONTROLLER_DAEMON_SCRIPT) ,
     "Getting hosts that run $PI_CONTROLLER_DAEMON_SCRIPT"
);
cmp_deeply( $return, bag(qw/pitest pitestanother/) , "Got the hosts expected" );


ok ( $return = get_pi_hosts_running_daemon( $COMMAND_QUEUE_DAEMON_SCRIPT) ,
     "Getting hosts that run $COMMAND_QUEUE_DAEMON_SCRIPT"
);
cmp_deeply( $return, bag(qw/pitest/) , "Got the hosts expected" );


ok ( $return = get_pi_hosts_running_daemon( $ONE_WIRED_SENDER_SCRIPT) ,
     "Getting hosts that run $ONE_WIRED_SENDER_SCRIPT"
);
cmp_deeply( $return, bag(qw/pitestanother/) , "Got the hosts expected" );


#############################
# one-wire-thermometer conf :

#
#ok ( $cont_cfg = get_control_config('therm-loft') , "Can get onewire-thermometer control");
#cmp_deeply( $cont_cfg, $controls_return->{'therm-loft'} , "Got the control data" );
#
#

