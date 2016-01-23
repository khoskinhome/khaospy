package Khaospy::PiHostPublishers;
use strict;
use warnings;

use Exporter qw/import/;

our @EXPORT_OK = qw(
    get_onewire_thermometer_daemon_hosts
    get_status_daemon_hosts
    get_pi_controller_daemon_hosts
    get_pi_controller_queue_daemon_hosts
    get_ping_daemon_hosts
    get_mac_daemon_hosts
);

# Has methods that return what Pi Hosts are running what services.
# Hence other hosts know which ones to subscribe to when receiving messages.

# TODO this will use the daemon_runner_config, but at present its hard coded for testing.

sub get_onewire_thermometer_daemon_hosts {

    return [qw/pitest/];

}

sub get_status_daemon_hosts {

    return [qw/pitest/];

}

sub get_pi_controller_daemon_hosts {

    return [qw/pitest/];
}

sub get_pi_controller_queue_daemon_hosts {

    return [qw/pitest/];

}

sub get_ping_daemon_hosts {

    return [qw/pitest/];

}

sub get_mac_daemon_hosts {

    return [qw/pitest/];

}

1;
