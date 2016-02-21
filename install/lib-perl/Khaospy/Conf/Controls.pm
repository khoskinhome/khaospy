package Khaospy::Conf::Controls;
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
    KhaospyExcept::ControlsConfig
    KhaospyExcept::ControlDoesnotExist
    KhaospyExcept::ControlsConfigNoType
    KhaospyExcept::ControlsConfigInvalidType
    KhaospyExcept::ControlsConfigUnknownKeys
    KhaospyExcept::ControlsConfigNoKey
    KhaospyExcept::ControlsConfigKeysInvalidValue

    KhaospyExcept::PiHostsNoValidGPIO
    KhaospyExcept::ControlsConfigInvalidGPIO
    KhaospyExcept::ControlsConfigDuplicateGPIO

    KhaospyExcept::PiHostsNoValidI2CBus
    KhaospyExcept::ControlsConfigInvalidI2CBus
    KhaospyExcept::ControlsConfigDuplicateMCP23017GPIO

    KhaospyExcept::ControlsConfigHostUnresovlable
);

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    $KHAOSPY_CONTROLS_CONF_FULLPATH
    $KHAOSPY_PI_HOSTS_CONF_FULLPATH
);

use Khaospy::Conf qw(
    get_conf
);

use Khaospy::Conf::PiHosts qw(
    get_pi_host_config
);

use Khaospy::Utils;

our @EXPORT_OK = qw(
    get_control_config
    get_controls_conf
    get_controls_conf_for_host
);

# ALL Control must have a key called "type".
# The $types below names the only keys allowed for each "type" of control
# along the callback to check it.

######################################
# "relay", "relay-manual" and "switch"
######################################
#
# Yes in reality "relays" are a type of "switch". Now forget that.
# For the purposes of making terminology clear in the Controls Config :
#
# a "relay" is something the Pi Controls to operate (should I say "switch", sorry!) a circuit.
#   hence it uses a gpio in "output" mode.
#
# a "switch" is a "input" (from Khaospy's perspective) from something.
#   The "input" can be a gpio ( pi direct or i2c-MCP23017-gpio ) in "input" mode.
#   The "input" can be seeing if a mac-address is nmap-able on the local network.
#   The "input" can be if an IP is pingable.
#
# a "relay-manual" is a circuit that is wired in electrical-2-way configuration ( like stairway-lighting usually is ).
#   One end of the 2 way circuit is a Pi-controlled-relay.
#   The other end of the 2 way circuit is a good old manual circuit.
#   To clearly explain this needs the electrical and electronic diagrams.
#   These diagrams are elsewhere in the docs.
#   There are several ways of doing this wiring.
#   All are useful under certain circumstances.
# The summary is a "relay-manual" is a circuit that is controlled by a Pi and a manual-switch somewhere.

#########################################
# invert_state
#########################################
#
# invert_state is needed to make 0's (false) in khaospy truly represent that the electrical circuit is OFF . Also that 1, true, ON the electrical circuit is truly ON.
#
# This is needed because certain circuit configurations work in reverse, in several different ways.
#
# The simplest to understand is that some relay modules ( facilla ones for Arduino's / Pi-s ) when you drive them with a 3.3v or 5v signal actually turn the relay off.
# Even if this was the more logical 3.3v output on the Pi GPIO turns the relay on , you could have wired up the Normally-Closed contacts of the circuit to energise the light ( or other load ) that you are driving.
# 
# When we get to the case of the relay-manual circuit, with several different wiring types it gets even more complicated.
#
# Even the "switch" type control can suffer from a 5v signal on the GPIO pin actually meaning the electrical load is really off.
#
# So invert_state solves these issues. It works differently depending on whether the control type is a simple "relay", "switch" or whether it is the more complicated "relay-manual".
#
# "relay" and invert-state.
# ---------------------
# For this type of control invert_state just changes 0 to 1 ( and vice-versa ) when the # signal is sent to the GPIO.
#
# "switch" and invert-state.
# ----------------------
# This is pretty much the same as the "relay" . Only here the GPIO is polled for its value, and a 0 is returned as 1 in the code ( and vice-versa )
#
# "relay-manual" and invert_state and ex_or_for_state.
# --------------------------------
# This is where the real fun begins.
# Here the invert_state works almost like the "switch".
# It only operates on the status value that is going to be returned in the code.
# It doesn't operate on the "relay" output. That doesn't matter.
# It only works on the "gpio_detect" input. This is because the gpio_detect should represent the voltage on the circuit. In most cases it does.
# However there is one extra part to this ..... ex_or_for_state.
#
# The wiring diagrams of some controls the voltage that is applied to the "gpio_detect" pin is the voltage of what is being applied to another relay. ( makes for less wiring, and simpler control electronics ! )
# Now on this circuit the gpio_relay output and the gpio_relay have to be exclusively-or-ed to get the circuit state ( 2 way lighting control is effectively an ex-or ), it is the result of this ex_or that invert_state operates on, this is what will be returned as the state of the control.
#
# This is best shown with some diagrams. That will be somewhere !
#
####
# relay-manual : manual_auto_timeout
####
# this optional setting says "if a relay-manual control has been manually operated then do not auto-control for this many seconds"



my $check_mac = check_regex(
    qr/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/
);

my $check_boolean = check_regex(qr/^[01]$/);
my $check_optional_boolean
    = check_optional_regex(qr/^[01]$/);
my $check_optional_integer
    = check_optional_regex(qr/^\d+$/);

my $check_types = {
    "orvibos20" => {
        alias        => \&check_optional,
        rrd_graph    => $check_optional_boolean,
        db_log       => $check_optional_boolean,
        poll_timeout => $check_optional_integer,
        host         => \&check_host,
        mac          => $check_mac,
        manual_auto_timeout => $check_optional_integer,
    },
    "onewire-thermometer" => {
        alias         => \&check_optional,
        rrd_graph     => $check_optional_boolean,
        db_log        => $check_optional_boolean,
        onewire_addr  => check_regex(
            qr/^[0-9A-Fa-f]{2}-[0-9A-Fa-f]{12}$/
        ),
    },
    "pi-gpio-relay-manual" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        ex_or_for_state => $check_boolean,
        invert_state    => $check_boolean,
        manual_auto_timeout => $check_optional_integer,
        gpio_relay      => \&check_pi_gpio,
        gpio_detect     => \&check_pi_gpio,
    },
    "pi-gpio-relay" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_gpio,
    },
    "pi-gpio-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_gpio,
    },
    "pi-mcp23017-relay-manual" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        ex_or_for_state => $check_boolean,
        invert_state    => $check_boolean,
        manual_auto_timeout => $check_optional_integer,
        gpio_relay      => \&check_pi_mcp23017,
        gpio_detect     => \&check_pi_mcp23017,
    },
    "pi-mcp23017-relay" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_mcp23017,
    },
    "pi-mcp23017-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_mcp23017,
    },
    "mac-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        mac             => $check_mac,
    },
    "ping-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        db_log          => $check_optional_boolean,
        host            => \&check_host,
    }
};

# TODO need a better way of forcing the loading of the control config
# doing the following makes testing hard :
#get_controls_conf();

my $controls_conf;

sub _set_controls_conf {
    # needed for testing.
    $controls_conf = $_[0];
}

sub get_controls_conf {
    my ($force_reload) = @_;
    get_conf(
        \$controls_conf,
        $KHAOSPY_CONTROLS_CONF_FULLPATH,
        $force_reload,
        \&_validate_controls_conf,
    );
}

sub get_controls_conf_for_host {
    my ($host) = @_;
    $host = $host || hostname;
    get_controls_conf();
    my $ret_controls = {};

    for my $control_name ( keys %$controls_conf ){
        my $control = $controls_conf->{$control_name};

        next if ! exists $control->{host};

        $ret_controls->{$control_name} = $control
            if $host eq $control->{host};
    }

    return $ret_controls;
}

sub get_control_config {
    my ( $control_name, $force_reload ) = @_;

    get_controls_conf($force_reload);

    KhaospyExcept::ControlDoesnotExist->throw(
        error => "Control '$control_name' doesn't exist in "
            ."$KHAOSPY_CONTROLS_CONF_FULLPATH\n"
    )
        if ! exists $controls_conf->{$control_name};

    return $controls_conf->{$control_name};
}

my $pi_mcp23017_unique;
my $pi_gpio_unique;

sub _validate_controls_conf {
    $pi_mcp23017_unique = {};
    $pi_gpio_unique     = {};
    my $collate_errors = '';

    for my $control_name ( keys %$controls_conf ){
        try {
            check_config($control_name)
        } catch {
            $collate_errors .= ref( $_ )." $_\n";
        }
    }

    KhaospyExcept::ControlsConfig->throw(
        error => "Errors checking the controls config"
            ." $KHAOSPY_CONTROLS_CONF_FULLPATH\n\n"
            ."$collate_errors\n"
    )
        if $collate_errors;

}

sub check_config {
    my ($control_name) = @_;

    my $control = $controls_conf->{$control_name};

    KhaospyExcept::ControlsConfigNoType->throw(
        error => "Control '$control_name' doesn't have a 'type' key"
    )
        if ! exists $control->{type};

    my $type_from_file = lc($control->{type});

    KhaospyExcept::ControlsConfigInvalidType->throw(
        error => "Control '$control_name' has an invalid 'type' of $type_from_file"
    )
        if ! exists $check_types->{$type_from_file};

    my $collate_errors = '';

    my $chk_type = $check_types->{$type_from_file};
    $chk_type->{type} = ''; # to make the List::Compare work

    my $lc = List::Compare->new(
        '-u',
        [ keys %$chk_type ],
        [ keys %$control ]
    );

    KhaospyExcept::ControlsConfigUnknownKeys->throw(
        error => "Control '$control_name' has unknown keys in the config ( ".join ("," , $lc->get_Ronly)." )\n"
    )
        if ! $lc->is_LequivalentR && ! $lc->is_RsubsetL ;

    # TODO think about the Exception collation here.
    # No extra keys in $control. Good.
    delete $chk_type->{type}; # only needed for List::Compare.
    for my $chk ( keys %$chk_type ){
        try {
            $chk_type->{$chk}->($control_name, $control, $chk);
        }
        catch {
            $collate_errors .= ref( $_ )." $_\n";
        };
    }

    KhaospyExcept::ControlsConfig->throw(
        error => $collate_errors
    ) if $collate_errors;
}

sub check_exists {
    my ($control_name, $control, $chk, $extra ) = @_;
    $extra = "" if ! $extra;
    KhaospyExcept::ControlsConfigNoKey->throw(
        error => "Control '$control_name' doesn't have a '$chk' configured. $extra"
    )
        if ! exists $control->{$chk};
}

sub check_regex {
    my ($regex) = @_;
    return sub {
        check_exists(@_);
        _regex_check($regex, @_);
    }
}

sub check_optional_regex {
    my ($regex) = @_;
    return sub {
        my (undef, $control, $chk) = @_;
        return if ! exists $control->{$chk} || ! defined $control->{$chk};
        _regex_check($regex, @_);
    }
}

sub _regex_check {
    my ( $regex, $control_name, $control, $chk, $extra ) = @_;

    $extra = "" if ! $extra;
    my $val = $control->{$chk};
    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error => "Control '$control_name' has an invalid '$chk' "
            ."($val) configured. $extra"
    )
        if ( $val !~ $regex );
}

sub check_host {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};
    _is_host_resolvable($val);
}

sub check_host_runs_pi_controls {
    my ($control_name, $control, $chk) = @_;
    check_host(@_);
    my $val = $control->{$chk};
    # TODO check the pi-host-conf for all the known hosts.
    # that run pi-controller-daemons.
}

sub check_pi_gpio {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};

    my $host = $control->{host};

    my $valid_gpios = get_pi_host_config($host)->{valid_gpios};

    KhaospyExcept::PiHostsNoValidGPIO->throw(
        error => "Pi-host '$host' doesn't have 'valid_gpios' configured.\n"
            ."The valid_gpios are defined in the pi-host config $KHAOSPY_PI_HOSTS_CONF_FULLPATH.\n"
            ."Control '$control_name' cannot be checked for the validity of '$chk'"
    )
        if ! defined $valid_gpios;

    KhaospyExcept::ControlsConfigInvalidGPIO->throw(
        error => "Control '$control_name' has an invalid gpio for '$chk' of '$val'\n"
            ."The valid_gpios defined for the pi-host '$host'"
            ." in $KHAOSPY_PI_HOSTS_CONF_FULLPATH are (".join(',', @$valid_gpios).")"
    )
        if ! grep { $_ == $val } @$valid_gpios;

    my $uniq = "host=$control->{host}|gpio=$val";

    KhaospyExcept::ControlsConfigDuplicateGPIO->throw(
        error => "Control '$control_name' is using the same "
            ."pi_gpio as control '$pi_gpio_unique->{$uniq}'"
            .". unique-key = '$uniq'"
    )
        if exists $pi_gpio_unique->{$uniq};

    $pi_gpio_unique->{$uniq} = $control_name;
}

sub check_pi_mcp23017 {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};

    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error =>
            "Control '$control_name' has an invalid '$chk' ($val) "
            ."configured. Should be a hashref"
    )
        if ( ref $val ne 'HASH' );

    # need to check the sub keys.

    # first check i2c_bus sub-key against valid ones in pi-host config.
    my $host = $control->{host};

    my $i2c_bus = $val->{i2c_bus};

    my $valid_i2c_buses = get_pi_host_config($host)->{valid_i2c_buses};

    KhaospyExcept::PiHostsNoValidI2CBus->throw(
        error => "Pi-host '$host' doesn't have 'valid_i2c_buses' configured.\n"
            ."The valid_i2c_buses are defined in the pi-host config $KHAOSPY_PI_HOSTS_CONF_FULLPATH.\n"
            ."Control '$control_name' cannot be checked for the validity of '$chk' (i2c_bus)"
    )
        if ! defined $valid_i2c_buses;

    KhaospyExcept::ControlsConfigInvalidI2CBus->throw(
        error => "Control '$control_name' has an invalid i2c_bus for '$chk' of '$val'\n"
            ."The valid_i2c_buses defined for the pi-host '$host'"
            ." in $KHAOSPY_PI_HOSTS_CONF_FULLPATH are (".join(',', @$valid_i2c_buses).")"
    )
        if ! grep { $_ == $i2c_bus } @$valid_i2c_buses;


    # check the reset of the sub-keys :
    check_regex(qr/^0x2[0-7]$/)->( $control_name , $val, "i2c_addr", "(on $chk)");
    check_regex(qr/^[abAB]$/)->(   $control_name , $val, "portname", "(on $chk)");
    check_regex(qr/^[0-7]$/)->(    $control_name , $val, "portnum",  "(on $chk)");

    # Need to keep track of what mcp23017 gpios have been used on a host basis.
    # The unique key is :
    #   host | i2c_bus | i2c_addr | portname | portnum
    # A gpio can only be used for one control. OBVIOUSLY !

    my $uniq = "host=".$control->{host}
          ."|i2c_bus=".$control->{$chk}{i2c_bus}
          ."|i2c_addr=".$control->{$chk}{i2c_addr}
          ."|portname=".lc($control->{$chk}{portname})
          ."|portnum=".$control->{$chk}{portnum};

    KhaospyExcept::ControlsConfigDuplicateMCP23017GPIO->throw(
        error => "Control '$control_name' is using the same "
            ."pi_mcp23017 gpio as control '$pi_mcp23017_unique->{$uniq}'"
            .". unique-key = '$uniq'"
    )
        if exists $pi_mcp23017_unique->{$uniq};

    $pi_mcp23017_unique->{$uniq} = $control_name;
}

sub check_optional {
    # Do absolutely "nuffin MATE !"
    # aka "null op".
}



sub _is_host_resolvable {
    my ($host) = @_;

    #TODO use Net::DNS / gethostbyname etc....

#    KhaospyExcept::ControlsConfigHostUnresovlable->throw(
#        error => "",
#    )
#        if host-is-not-resolvable;

    return;
}

1;
