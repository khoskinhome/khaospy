package Khaospy::Conf;
use strict;
use warnings;

use Carp qw/confess/;
use Data::Dumper;
use Exporter qw/import/;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    $KHAOSPY_CONTROLS_CONF_FULLPATH
    $KHAOSPY_BOILERS_CONF_FULLPATH
    $KHAOSPY_GLOBAL_CONF_FULLPATH

    $MESSAGES_OVER_SECS_INVALID
);

use Khaospy::Utils;

our @EXPORT_OK = qw(
    get_daemon_runner_conf
    get_one_wire_heating_control_conf
    get_controls_conf
    get_boiler_conf
    get_global_conf
    get_control_config
);

# maybe the following should be built of the Classes that handle the different types of control .... dunno. When they're written I guess.
my $control_types = {
    'orvibos20'                => 1,
    'pi-gpio-relay-manual'     => 1,
    'pi-gpio-relay'            => 1,
    'pi-gpio-switch'           => 1,
    'pi-mcp23017-relay-manual' => 1,
    'pi-mcp23017-relay'        => 1,
    'pi-mcp23017-switch'       => 1,
};

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
    my $controls_conf;

    sub get_controls_conf {
        my ($not_needed) = @_;
        confess "ERROR. get_controls_conf doesn't need a parameter. Probably need to call get_control_config\n" if $not_needed;

        if ( ! $controls_conf ) {
            $controls_conf = $JSON->decode(
                 Khaospy::Utils::slurp( $KHAOSPY_CONTROLS_CONF_FULLPATH )
            );
            _validate_controls_conf();
        }
        return $controls_conf;
    }

    sub get_control_config {
        my ( $control_name ) = @_;

        get_controls_conf() if ! $controls_conf ;

        confess "ERROR in config. Control '$control_name' "
            ."doesn't exist in $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
            if ! exists $controls_conf->{$control_name};

        return $controls_conf->{$control_name};

    }

    sub _validate_controls_conf {

        for my $control_name ( keys %$controls_conf ) {

            my $control = $controls_conf->{$control_name};

            confess "ERROR control $control_name doesn't have a host configured"
                ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
                if ! exists $control->{host};

            confess "ERROR control $control_name doesn't have a type configured"
                ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
                if ! exists $control->{type};

            confess "ERROR in config. Control '$control_name' doesn't have a 'type' key\n"
                ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
                if ! exists $control->{type};

            my $type = lc($control->{type});

            confess "ERROR in config. Control '$control_name' has an invalid 'type' of $type\n"
                ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
                if ! exists $control_types->{$type};

            # TODO validate all the different $control_types
            # That validation should be dispatch to something in say
            # Khaospy::PiGPIO and Khaospy::PiMCP23017 modules ( and the types of controls they handle )
        }
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
