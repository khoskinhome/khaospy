package Khaospy::Conf;
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use List::Compare;

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

{
    # ALL Control must have a key called "type".
    # The $types below names the only keys allowed for each "type" of control
    # along the callback to check it.

    my $check_mac = check_regex(
        qr/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/
    );

    my $check_boolean = check_regex(qr/^[01]$/);

    # this isn't valid for all Pi-s some have more.
    # TODO think about this.
    # Also a gpio should only be used once per host.
    # so this should be checked to.
    # Going to need more than a regex.
    # Need to keep track of what host has used gpio pins
    my $check_pi_gpio = check_regex(qr/^[0-7]$/);

    my $check_types = {
        "orvibos20" => {
            alias => \&check_optional,
            host  => \&check_host,
            mac   => $check_mac,
        },
        "onewire-thermometer" => {
            alias         => \&check_optional,
            onewire_addr  => check_regex(
                qr/^[0-9A-Fa-f]{2}-[0-9A-Fa-f]{12}$/
            ),
        },
        "pi-gpio-relay-manual" => {
            alias           => \&check_optional,
            host            => \&check_host_runs_pi_controls,
            ex_or_for_state => $check_boolean,
            invert_state    => $check_boolean,
            gpio_relay      => $check_pi_gpio,
            gpio_detect     => $check_pi_gpio,
        },
        "pi-gpio-relay" => {
            alias           => \&check_optional,
            host            => \&check_host_runs_pi_controls,
            invert_state    => $check_boolean,
            gpio_relay      => $check_pi_gpio,
        },
        "pi-gpio-switch" => {
            alias           => \&check_optional,
            host            => \&check_host_runs_pi_controls,
            invert_state    => $check_boolean,
            gpio_switch     => $check_pi_gpio,
        },
        "pi-mcp23017-relay-manual" => {
            alias           => \&check_optional,
            host            => \&check_host_runs_pi_controls,
            ex_or_for_state => $check_boolean,
            invert_state    => $check_boolean,
            gpio_relay      => \&check_pi_mcp23017,
            gpio_detect     => \&check_pi_mcp23017,
        },
        "pi-mcp23017-relay" => {
            alias           => \&check_optional,
            host            => \&check_host_runs_pi_controls,
            ex_or_for_state => $check_boolean,
            invert_state    => $check_boolean,
            gpio_relay      => \&check_pi_mcp23017,
        },
        "pi-mcp23017-switch" => {
            alias           => \&check_optional,
            host            => \&check_host_runs_pi_controls,
            ex_or_for_state => $check_boolean,
            invert_state    => $check_boolean,
            gpio_switch     => \&check_pi_mcp23017,
        },
        "mac-switch" => {
            alias           => \&check_optional,
            mac             => $check_mac,
        },
        "ping-switch" => {
            alias           => \&check_optional,
            host            => \&check_host,
        }
    };

    my $controls_conf;

    sub get_controls_conf {
        my ($not_needed) = @_;
        confess "get_controls_conf doesn't need a parameter. Probably need to call get_control_config\n" if $not_needed;

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

        confess "Control '$control_name' doesn't exist in $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
            if ! exists $controls_conf->{$control_name};

        return $controls_conf->{$control_name};
    }

    sub _validate_controls_conf {

        my $collate_errors = '';

        for my $control_name ( keys %$controls_conf ){
            eval{check_config($control_name);};
            check_config($control_name);
            $collate_errors .= "$@\n" if $@;
        }

        croak $collate_errors if $collate_errors;
    }

    sub check_config {
        my ($control_name) = @_;

        my $control = $controls_conf->{$control_name};

        croak "ERROR in config. Control '$control_name' doesn't have a 'type' key\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
            if ! exists $control->{type};

        my $type_from_file = lc($control->{type});

        croak "ERROR in config. Control '$control_name' has an invalid 'type' of $type_from_file\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
            if ! exists $check_types->{$type_from_file};

        my $chk_type = $check_types->{$type_from_file};
        $chk_type->{type} = ''; # to make the List::Compare work

        my $lc = List::Compare->new ( '-u', [ keys %$chk_type ], [ keys %$control ] );
        if ( ! $lc->is_LequivalentR && ! $lc->is_RsubsetL ){
            croak "The control '$control_name' has unknown keys in the config ( ".join ("," , $lc->get_Ronly)." )";
        } else {
            # so no extra keys in $control . Good.
            delete $chk_type->{type}; # only needed for List::Compare.
            for my $chk ( keys %$chk_type ) {
                $chk_type->{$chk}->($control_name, $control, $chk);
            }
        }
    }

    sub check_exists {
        my ($control_name, $control, $chk) = @_;
        croak "ERROR control $control_name doesn't have a $chk configured"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
            if ! exists $control->{$chk};
    }

    sub check_regex {
        my ($regex) = @_;
        return sub {
            my ($control_name, $control, $chk) = @_;
            check_exists(@_);
            my $val = $control->{$chk};
            croak "ERROR control $control_name has an invalid $chk ($val) configured"
                ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
                if ( $val !~ $regex );
        }
    }

    sub check_host {
        my ($control_name, $control, $chk) = @_;
        check_exists(@_);
        my $val = $control->{$chk};
        # TODO could check if its resolvable.
    }

    sub check_host_runs_pi_controls {
        my ($control_name, $control, $chk) = @_;
        check_host(@_);
        my $val = $control->{$chk};
        # TODO check the daemon-runner-conf for all the known hosts.
        # that run pi-controller-daemons.
    }

    sub check_pi_mcp23017 {
        my ($control_name, $control, $chk) = @_;
        check_exists(@_);
        my $val = $control->{$chk};

        # TODO validate one of these.
        #     gpio_relay => {
        #           i2c_bus  => 0,
        #		i2c_addr => '0x20',
        #		portname =>'b',
        #		portnum  => 0,
        #            },

        # also need to keep track of what pins have been used on a host basis.
        # The unique key is :
        #   host | i2c_bus | i2c_addr | portname | portnumber
        # A pin can only be used once for any control.

    }

    sub check_optional {}

}

1;
