package Khaospy::Conf::PiHosts;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Sys::Hostname;

use List::Compare;

use Khaospy::Exception qw(
    KhaospyExcept::InvalidDaemonScriptName
);

use Khaospy::Constants qw(
    $PI_HOSTS_CONF_FULLPATH

    $ALL_SCRIPTS

    $ONE_WIRED_SENDER_SCRIPT
    $ONE_WIRED_RECEIVER_SCRIPT
    $ONE_WIRE_HEATING_DAEMON
    $BOILER_DAEMON_SCRIPT
    $PI_CONTROLLER_DAEMON_SCRIPT
    $PI_CONTROLLER_QUEUE_DAEMON_SCRIPT

);

use Khaospy::Conf qw(
    get_conf
);

use Khaospy::Utils;

our @EXPORT_OK = qw(
    get_pi_host_config
    get_pi_hosts_conf
    get_this_pi_host_config
    get_pi_hosts_running_daemon
);

my $pi_hosts_conf;

sub _set_pi_hosts_conf {
    # needed for testing.
    $pi_hosts_conf = $_[0];
}

sub get_pi_hosts_conf {
    my ($force_reload) = @_;
    get_conf(
        \$pi_hosts_conf,
        $PI_HOSTS_CONF_FULLPATH,
        $force_reload,
        \&_validate_pi_hosts_conf
    );
}
sub get_pi_host_config {
    my ($host, $force_reload) = @_;
    get_pi_hosts_conf($force_reload);

    die "Host '$host' doesn't exist in $PI_HOSTS_CONF_FULLPATH\n"
        if ! exists $pi_hosts_conf->{$host};

    return $pi_hosts_conf->{$host};

}

sub get_this_pi_host_config {
    get_pi_host_config( hostname, @_ );
}

sub get_pi_hosts_running_daemon {
    my ( $daemon_script_full_path ) = @_;

    KhaospyExcept::InvalidDaemonScriptName->throw(
        error => "Invalid script name '$daemon_script_full_path'"
    )
        if ! grep { $_ eq $daemon_script_full_path } @$ALL_SCRIPTS;

    get_pi_hosts_conf();

    my $pi_hosts_run_d = [];

    for my $host ( keys %$pi_hosts_conf ){
        for my $daemon ( @{$pi_hosts_conf->{$host}{daemons}} ){
            my $script = $daemon->{script};
            push @$pi_hosts_run_d, $host
                if $script eq $daemon_script_full_path;
        }
    }

    return $pi_hosts_run_d;
}

sub _validate_pi_hosts_conf {
    #TODO !
}

#################################
# Checking the values of Pi GPIOs
#################################
# This isn't valid for all Pi-s some have more
# Also different configurations change the amount of GPIOs available.

# I would need someway for the code when running on the specific Pi
# to try and work out its model and revision.
# This would then need to work out when GPIOs are used for other functions. SPI/I2C etc.
#
# The first 8 gpios are generally available on all Pi-s, ( 0-7 ), all the way back to the first Pi in 2012.
#
# I guess one easy way for me to code this is to allow an override in the config, on a per-pi-host basis. TODO , what I've just said.
# So, not in the control config, but in a pi-host config as option something like :
# { hostname => {
#        valid_gpio => [0,1,2,3,4,5,6,7,8,9,10,11,12]
# }

######################################
# Checking the values of the Pi i2cBus
######################################
# for the Pi-i2cBus, this needs to be configured on a per-pi-host basis.
# sometimes the bus is 0 , sometimes its 1 . If you muck around with wiring and other stuff, its possible to run them both. There might even be an i2c_bus 2. Search the 'net ;)
#
# So a config option something like :
# { hostname => {
#        valid_i2c_bus => [0,1,2,3,4,5,6,7,8,9,10,11,12]
# }

1;
