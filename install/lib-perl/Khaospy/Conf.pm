package Khaospy::Conf;
use strict;
use warnings;

use Carp qw/croak/;
use Data::Dumper;
use Exporter qw/import/;
use JSON;
my $json = JSON->new->allow_nonref;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $KHAOSPY_CONTROLS_CONF_FULLPATH
    $KHAOSPY_BOILERS_CONF_FULLPATH
);

use Khaospy::Utils; # qw( slurp );

our @EXPORT_OK = qw(
    get_heating_thermometer_conf
    get_controls_conf
    get_daemon_runner_conf
    get_boiler_conf
);

# reads in the confs once, unless it is a conf that can change whilst the daemons
# are running. confs are thus got from a method/sub

{
    my $therm_conf;
    my $therm_conf_last_loaded;

    sub get_heating_thermometer_conf {
        # reload the thermometer conf every 5 mins.
        if ( ! $therm_conf
            or $therm_conf_last_loaded + 20 < time  # TODO FIX THIS BACK TO 300 SECONDS.
        ) {
            $therm_conf = $json->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH )
            );
            $therm_conf_last_loaded = time ;
        }
        return $therm_conf;
    }
}

{
    my $boiler_conf;
    my $boiler_conf_last_loaded;

    sub get_boiler_conf {
        # reload the boiler conf every 5 mins.
        if ( ! $boiler_conf
            or $boiler_conf_last_loaded + 20 < time  # TODO FIX THIS BACK TO 300 SECONDS.
        ) {
            $boiler_conf = $json->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_BOILERS_CONF_FULLPATH )
            );
            $boiler_conf_last_loaded = time ;
        }
        return $boiler_conf;
    }
}

{
    my $controls_conf;

    sub get_controls_conf {
        # reload the thermometer conf every 5 mins.
        if ( ! $controls_conf ) {
            $controls_conf = $json->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_CONTROLS_CONF_FULLPATH )
            );
        }
        return $controls_conf;
    }

}

{
    my $daemon_runner_conf;

    sub get_daemon_runner_conf {
        if ( ! $daemon_runner_conf ) {
            $daemon_runner_conf = $json->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH )
            );
        }
        return $daemon_runner_conf;
    }
}

1;