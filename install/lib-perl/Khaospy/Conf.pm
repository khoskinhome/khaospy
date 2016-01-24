package Khaospy::Conf;
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    $KHAOSPY_BOILERS_CONF_FULLPATH
    $KHAOSPY_GLOBAL_CONF_FULLPATH

    $MESSAGES_OVER_SECS_INVALID
);

use Khaospy::Utils;

our @EXPORT_OK = qw(
    get_daemon_runner_conf
    get_one_wire_heating_control_conf
    get_boiler_conf
    get_global_conf
);

# reads in the confs once, unless it is a conf that can change whilst the daemons
# are running. confs are thus got from a method/sub

{
    my $daemon_runner_conf;

    sub get_daemon_runner_conf {
        if ( ! $daemon_runner_conf ) {
            $daemon_runner_conf = $JSON->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH )
            );
        }
        return $daemon_runner_conf;
    }
}

{
    my $therm_conf;
    my $therm_conf_last_loaded;

    sub get_one_wire_heating_control_conf {
        # reload the thermometer conf every 5 mins.
        if ( ! $therm_conf
            or $therm_conf_last_loaded + 20 < time  # TODO FIX THIS BACK TO 300 SECONDS.
        ) {
            $therm_conf = $JSON->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH )
            );
            $therm_conf_last_loaded = time ;
        }
        return $therm_conf;
    }
}

{
    my $boiler_conf;

    sub get_boiler_conf {
        if ( ! $boiler_conf ) {
            $boiler_conf = $JSON->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_BOILERS_CONF_FULLPATH )
            );
        }
        return $boiler_conf;
    }
}

{
    my $global_conf;

    sub get_global_conf {
        if ( ! $global_conf ) {
            $global_conf = $JSON->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_GLOBAL_CONF_FULLPATH )
            );
        }
        return $global_conf;
    }
}


1;
