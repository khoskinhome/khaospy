package Khaospy::Conf::Controls;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Scalar::Util qw(looks_like_number);

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
    KhaospyExcept::PiHostsDaemonNotOnHost
    KhaospyExcept::ControlsConfigInvalidGPIO
    KhaospyExcept::ControlsConfigDuplicateGPIO

    KhaospyExcept::PiHostsNoValidI2CBus
    KhaospyExcept::ControlsConfigInvalidI2CBus
    KhaospyExcept::ControlsConfigDuplicateMCP23017GPIO

    KhaospyExcept::ControlsConfigHostUnresovlable

    KhaospyExcept::GeneralError
);

use Khaospy::Constants qw(
    $JSON

    true  $true  OPEN   $OPEN   ON  $ON  PINGABLE     $PINGABLE     UNLOCKED $UNLOCKED
    false $false CLOSED $CLOSED OFF $OFF NOT_PINGABLE $NOT_PINGABLE LOCKED   $LOCKED

    $STATE_TYPE_ON_OFF                STATE_TYPE_ON_OFF
    $STATE_TYPE_OPEN_CLOSED           STATE_TYPE_OPEN_CLOSED
    $STATE_TYPE_PINGABLE_NOT_PINGABLE STATE_TYPE_PINGABLE_NOT_PINGABLE
    $STATE_TYPE_UNLOCKED_LOCKED       STATE_TYPE_UNLOCKED_LOCKED

    $CONTROLS_CONF_FULLPATH
    $PI_HOSTS_CONF_FULLPATH

    $PI_CONTROLLER_DAEMON_SCRIPT
    $OTHER_CONTROLS_DAEMON_SCRIPT
    $MAC_SWITCH_DAEMON_SCRIPT

    $ORVIBOS20_CONTROL_TYPE
    $ONEWIRE_THERM_CONTROL_TYPE
    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE
    $PI_GPIO_RELAY_CONTROL_TYPE
    $PI_GPIO_SWITCH_CONTROL_TYPE
    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE
    $PI_MCP23017_RELAY_CONTROL_TYPE
    $PI_MCP23017_SWITCH_CONTROL_TYPE
    $MAC_SWITCH_CONTROL_TYPE
    $MAC_SWITCH_CONTROL_SUB_TYPE_ALL
    $WEBUI_VAR_FLOAT_CONTROL_TYPE
    $WEBUI_VAR_INTEGER_CONTROL_TYPE
    $WEBUI_VAR_STRING_CONTROL_TYPE

);

use Khaospy::Conf qw(
    get_conf
);

use Khaospy::Conf::PiHosts qw(
    get_pi_host_config
    get_pi_hosts_running_daemon
);

use Khaospy::Utils qw(
    get_hashval
);


our @EXPORT_OK = qw(
    get_control_config
    control_exists
    get_controls_conf
    get_controls_conf_for_host
    get_control_name_for_one_wire
    is_control_rrd_graphed
    get_rrd_create_params_for_control

    can_operate
    can_set_value
    can_set_string

    state_trans_control
    state_to_binary_die
    state_to_binary
    is_state
    is_on_state
    is_off_state
);

my $check_mac = check_regex_sub(
    qr/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/
);

my $check_boolean = check_regex_sub(qr/^[01]$/);
my $check_optional_boolean
    = check_optional_regex_sub(qr/^[01]$/);
my $check_integer
    = check_regex_sub(qr/^\d+$/);
my $check_optional_integer
    = check_optional_regex_sub(qr/^\d+$/);

##################
# these are used by the webui to work out what type of control
# interface to display.
#
# TODO : following needs renaming to can_on_off :
my $can_operate = {
    $ORVIBOS20_CONTROL_TYPE                => true,
    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE     => true,
    $PI_GPIO_RELAY_CONTROL_TYPE            => true,
    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE => true,
    $PI_MCP23017_RELAY_CONTROL_TYPE        => true,
};

# will need :
#   can_set_multi_on_off
#   can_set_dimmable  ( 0 to 1 float )
#   can_set_multi_dimmable ( array of 0 to 1 floats )

my $can_set_value = {
    $WEBUI_VAR_FLOAT_CONTROL_TYPE          => true,
    $WEBUI_VAR_INTEGER_CONTROL_TYPE        => true,
};

my $can_set_string = {
    $WEBUI_VAR_STRING_CONTROL_TYPE         => true,
};

# will probably need :
# my $can_set_ datetime_tz date time hours mins interval etc ...


###########################
# state type translations types :

my $state_trans_type = {
    STATE_TYPE_ON_OFF                => \&state_trans_on_off,
    STATE_TYPE_OPEN_CLOSED           => \&state_trans_open_closed,
    STATE_TYPE_PINGABLE_NOT_PINGABLE => \&state_trans_pingable_not_pingable,
    STATE_TYPE_UNLOCKED_LOCKED       => \&state_trans_unlocked_locked,
};


###########################
# control conf checking definition :

my $check_types = {
    $ORVIBOS20_CONTROL_TYPE => {
        alias        => \&check_optional,
        state_type   => \&check_optional_state_type,
        rrd_graph    => $check_optional_boolean,
        poll_timeout => $check_optional_integer,
        poll_host    =>
            check_host_runs_sub($OTHER_CONTROLS_DAEMON_SCRIPT),
        host         => \&check_host,
        mac          => $check_mac,
        manual_auto_timeout => $check_optional_integer,
    },
    $ONEWIRE_THERM_CONTROL_TYPE => {
        alias         => \&check_optional,
        rrd_graph     => $check_optional_boolean,
        onewire_addr  => check_regex_sub(
            qr/^[0-9A-Fa-f]{2}-[0-9A-Fa-f]{12}$/
        ),
    },
    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        ex_or_for_state => $check_boolean,
        invert_state    => $check_boolean,
        manual_auto_timeout => $check_optional_integer,
        gpio_relay      => \&check_pi_gpio,
        gpio_detect     => \&check_pi_gpio,
    },
    $PI_GPIO_RELAY_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_gpio,
    },
    $PI_GPIO_SWITCH_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_gpio,
    },
    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        ex_or_for_state => $check_boolean,
        invert_state    => $check_boolean,
        manual_auto_timeout => $check_optional_integer,
        gpio_relay      => \&check_pi_mcp23017,
        gpio_detect     => \&check_pi_mcp23017,
    },
    $PI_MCP23017_RELAY_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_mcp23017,
    },
    $PI_MCP23017_SWITCH_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_mcp23017,
    },
    $MAC_SWITCH_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        mac             => $check_mac,
        sub_type        => \&check_mac_sub_type,
    },
    $WEBUI_VAR_FLOAT_CONTROL_TYPE => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        value           => \&check_number,
        upper_limit     => \&check_optional_number,
        lower_limit     => \&check_optional_number,
    },
    $WEBUI_VAR_INTEGER_CONTROL_TYPE => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        value           => $check_integer,
        upper_limit     => $check_optional_integer,
        lower_limit     => $check_optional_integer,
    },
#    $WEBUI_VAR_STRING_CONTROL_TYPE  => {
#        alias           => \&check_optional,
#        value           => ,
#        valid_regex     => ,
#    },
};

# TODO WEBUI_VARs with upper and lower limits need to be checked that upper>lower where defined.

my $rrd_create_thermometer = [qw(
    --start  now  --step 60
    DS:a:GAUGE:120:-40:90
    RRA:AVERAGE:0.5:1:1440
    RRA:AVERAGE:0.5:4:1440
    RRA:AVERAGE:0.5:8:1440
    RRA:AVERAGE:0.5:32:1440
    RRA:AVERAGE:0.5:60:17520
)];

my $rrd_create_switch = [qw(
    --start  now  --step 60
    DS:a:GAUGE:120:0:1
    RRA:AVERAGE:0.5:1:1440
    RRA:AVERAGE:0.5:4:1440
    RRA:AVERAGE:0.5:8:1440
    RRA:AVERAGE:0.5:32:1440
    RRA:AVERAGE:0.5:60:17520
)];

my $rrd_create_params = {
    $ORVIBOS20_CONTROL_TYPE                 => $rrd_create_switch,
    $ONEWIRE_THERM_CONTROL_TYPE             => $rrd_create_thermometer,
    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE      => $rrd_create_switch,
    $PI_GPIO_RELAY_CONTROL_TYPE             => $rrd_create_switch,
    $PI_GPIO_SWITCH_CONTROL_TYPE            => $rrd_create_switch,
    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE  => $rrd_create_switch,
    $PI_MCP23017_RELAY_CONTROL_TYPE         => $rrd_create_switch,
    $PI_MCP23017_SWITCH_CONTROL_TYPE        => $rrd_create_switch,
    $MAC_SWITCH_CONTROL_TYPE                => $rrd_create_switch,
#    $WEBUI_VAR_FLOAT_CONTROL_TYPE                 => ?, TODO
#    $WEBUI_VAR_INTEGER_CONTROL_TYPE               => ?, TODO
#    $WEBUI_VAR_STRING_CONTROL_TYPE                => ?, TODO

};

# TODO need a better way of forcing the loading of the control config
# doing the following makes testing hard :
# get_controls_conf();

my $controls_conf;

sub get_rrd_create_params_for_control {

    my ($control_name) = @_;
    get_controls_conf();

    my $control = get_hashval($controls_conf,$control_name);

    return if ! is_control_rrd_graphed($control_name);

    return
        get_hashval($rrd_create_params,
            get_hashval($control,'type')
        );
}

sub is_control_rrd_graphed {
    my ($control_name) = @_;
    get_controls_conf();

    my $control = get_hashval($controls_conf,$control_name);

    return get_hashval($control,'rrd_graph',false,false,false);
}

sub can_operate {
    my ($control_name) = @_;
    get_controls_conf();
    my $control = get_hashval($controls_conf, $control_name);

    return true if exists $can_operate->{get_hashval($control,'type')};
    return false;
}

sub can_set_value {
    my ($control_name) = @_;
    get_controls_conf();
    my $control = get_hashval($controls_conf, $control_name);

    return true if exists $can_set_value->{get_hashval($control,'type')};
    return false;
}

sub can_set_string {
    my ($control_name) = @_;
    get_controls_conf();
    my $control = get_hashval($controls_conf, $control_name);

    return true if exists $can_set_string->{get_hashval($control,'type')};
    return false;
}

sub _set_controls_conf {
    # needed for testing.
    $controls_conf = $_[0];
}

sub get_controls_conf {
    my ($force_reload) = @_;
    get_conf(
        \$controls_conf,
        $CONTROLS_CONF_FULLPATH,
        $force_reload,
        \&_validate_controls_conf,
    );
}

sub get_controls_conf_for_host {
    my ($host, $host_key) = @_;
    $host = $host || hostname;
    $host_key = $host_key || "host";

    get_controls_conf();
    my $ret_controls = {};

    for my $control_name ( keys %$controls_conf ){
        my $control = $controls_conf->{$control_name};

        next if ! exists $control->{$host_key};

        $ret_controls->{$control_name} = $control
            if $host eq get_hashval($control, $host_key);
    }

    return $ret_controls;
}

sub control_exists {
    # only use where you wish to avoid the error thrown by
    # get_control_config
    # deliberately doesn't return the control's config.
    my ( $control_name, $force_reload ) = @_;
    get_controls_conf($force_reload);

    return exists $controls_conf->{$control_name};
}


sub get_control_config {
    my ( $control_name, $force_reload ) = @_;

    get_controls_conf($force_reload);

    KhaospyExcept::ControlDoesnotExist->throw(
        error => "Control '$control_name' doesn't exist in "
            ."$CONTROLS_CONF_FULLPATH\n"
    )
        if ! exists $controls_conf->{$control_name};

    return $controls_conf->{$control_name};
}

sub get_control_name_for_one_wire {
    my ( $one_wire_addr ) = @_;
    get_controls_conf();

    my @controls_one_wire_conf =
        grep { $controls_conf->{$_}{onewire_addr} eq $one_wire_addr }
        grep { $controls_conf->{$_}{type} eq $ONEWIRE_THERM_CONTROL_TYPE }
        keys %$controls_conf;


    KhaospyExcept::GeneralError->throw(
        error => "Got more than one control for one-wire-address $one_wire_addr : ".join( ",", @controls_one_wire_conf)."\n",
    )
        if scalar @controls_one_wire_conf > 1;

    return $controls_one_wire_conf[0] if @controls_one_wire_conf;

    return;
}

my $pi_mcp23017_unique;
my $pi_gpio_unique;

sub _validate_controls_conf {
    $pi_mcp23017_unique = {};
    $pi_gpio_unique     = {};
    my $collate_errors = '';

    for my $control_name ( sort keys %$controls_conf ){
        try {
            check_config($control_name)
        } catch {
            $collate_errors .= ref( $_ )." $_\n";
        }
    }

    KhaospyExcept::ControlsConfig->throw(
        error => "Errors checking the controls config"
            ." $CONTROLS_CONF_FULLPATH\n\n"
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

sub check_number {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};

    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error => "Control '$control_name' has an invalid '$chk' "
            ."($val) configured (not a number)"
    )
        if ! looks_like_number($val);
}

sub check_optional_number {
    my ($control_name, $control, $chk) = @_;
    return if ! exists $control->{$chk} || ! defined $control->{$chk};
    return check_number(@_);
}

sub check_regex_sub {
    my ($regex) = @_;
    return sub {
        check_exists(@_);
        _regex_check($regex, @_);
    }
}

sub check_optional_regex_sub {
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

sub check_optional_state_type {
    my ($control_name, $control, $chk) = @_;

    return if ! exists $control->{$chk};

    my $val = $control->{$chk};

    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error => "Control '$control_name' has an invalid '$chk' "
            ."($val) configured"
    ) if ! exists $state_trans_type->{$val};
}

sub check_host {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};
    _is_host_resolvable($val);
}

sub check_host_runs_sub {
    my ($daemon_script_name) = @_;
    return sub {
        my ($control_name, $control, $chk) = @_;
        check_host(@_);
        my $val = $control->{$chk};

        KhaospyExcept::PiHostsDaemonNotOnHost->throw(
            error => "Control $control_name has a $chk of $val. $val is not running $daemon_script_name",
        ) if ! grep { $_ eq $val }
            @{get_pi_hosts_running_daemon($daemon_script_name)};
    };
}

sub check_pi_gpio {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};

    my $host = $control->{host};

    my $valid_gpios = get_pi_host_config($host)->{valid_gpios};

    KhaospyExcept::PiHostsNoValidGPIO->throw(
        error => "Pi-host '$host' doesn't have 'valid_gpios' configured.\n"
            ."The valid_gpios are defined in the pi-host config $PI_HOSTS_CONF_FULLPATH.\n"
            ."Control '$control_name' cannot be checked for the validity of '$chk'"
    )
        if ! defined $valid_gpios;

    KhaospyExcept::ControlsConfigInvalidGPIO->throw(
        error => "Control '$control_name' has an invalid gpio for '$chk' of '$val'\n"
            ."The valid_gpios defined for the pi-host '$host'"
            ." in $PI_HOSTS_CONF_FULLPATH are (".join(',', @$valid_gpios).")"
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

    # check the sub keys.
    # first check i2c_bus sub-key against valid ones in pi-host config.
    my $host = $control->{host};

    my $i2c_bus = $val->{i2c_bus};

    my $valid_i2c_buses = get_pi_host_config($host)->{valid_i2c_buses};

    KhaospyExcept::PiHostsNoValidI2CBus->throw(
        error => "Pi-host '$host' doesn't have 'valid_i2c_buses' configured.\n"
            ."The valid_i2c_buses are defined in the pi-host config $PI_HOSTS_CONF_FULLPATH.\n"
            ."Control '$control_name' cannot be checked for the validity of '$chk' (i2c_bus)"
    )
        if ! defined $valid_i2c_buses;

    KhaospyExcept::ControlsConfigInvalidI2CBus->throw(
        error => "Control '$control_name' has an invalid i2c_bus for '$chk' of '$val'\n"
            ."The valid_i2c_buses defined for the pi-host '$host'"
            ." in $PI_HOSTS_CONF_FULLPATH are (".join(',', @$valid_i2c_buses).")"
    )
        if ! grep { $_ == $i2c_bus } @$valid_i2c_buses;


    # check the rest of the sub-keys :
    check_regex_sub(qr/^0x2[0-7]$/)->( $control_name , $val, "i2c_addr", "(on $chk)");
    check_regex_sub(qr/^[AB]$/i)->(    $control_name , $val, "portname", "(on $chk)");
    check_regex_sub(qr/^[0-7]$/)->(    $control_name , $val, "portnum",  "(on $chk)");

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

sub check_mac_sub_type {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};

    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error => "Control '$control_name' has an invalid '$chk' "
            ."($val) configured"
    )
        if ! exists $MAC_SWITCH_CONTROL_SUB_TYPE_ALL->{$val};

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

####################
# state_trans subs :
sub state_trans_control {
    my ($control_name, $value) = @_;
    get_controls_conf();
    my $control = get_hashval($controls_conf, $control_name);

    my $control_type = get_hashval($control,'type');
    my $state_type = $control->{state_type};

    if (! $state_type ){
        # some control-types are easy to work out a default state_type for :
        if (   $control_type eq $ORVIBOS20_CONTROL_TYPE
            || $control_type eq $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE
            || $control_type eq $PI_GPIO_RELAY_CONTROL_TYPE
            || $control_type eq $PI_GPIO_SWITCH_CONTROL_TYPE
            || $control_type eq $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE
            || $control_type eq $PI_MCP23017_RELAY_CONTROL_TYPE
            || $control_type eq $PI_MCP23017_SWITCH_CONTROL_TYPE
        ){
            $state_type = STATE_TYPE_ON_OFF;
        } elsif ($control_type eq $MAC_SWITCH_CONTROL_TYPE ){
            $state_type = STATE_TYPE_PINGABLE_NOT_PINGABLE;
        }
        return if ! $state_type;
    }
    return $state_trans_type->{$state_type}->($value);
}

sub state_trans_on_off{
    my ($value) = @_;
    return $value if $value eq ON || $value eq OFF;
    return ON  if $value == true;
    return OFF if $value == false;
    return state_to_binary_die($value) ? ON : OFF;
}

sub state_trans_open_closed{
    my ($value) = @_;
    return $value if $value eq OPEN || $value eq CLOSED;
    return OPEN   if $value == true;
    return CLOSED if $value == false;
    return state_to_binary_die($value) ? OPEN : CLOSED;
}

sub state_trans_pingable_not_pingable{
    my ($value) = @_;
    return $value if $value eq PINGABLE || $value eq NOT_PINGABLE;
    return PINGABLE     if $value == true;
    return NOT_PINGABLE if $value == false;
    return state_to_binary_die($value) ? PINGABLE : NOT_PINGABLE;
}

sub state_trans_unlocked_locked{
    my ($value) = @_;
    return $value if $value eq LOCKED || $value eq UNLOCKED;
    return UNLOCKED if $value == true;
    return LOCKED   if $value == false;
    return state_to_binary_die($value) ? UNLOCKED : LOCKED;
}

sub state_to_binary_die {
    return state_to_binary($_[0],true);
}

sub state_to_binary {
    my ($value, $die_on_error) = @_;
    return true  if is_on_state($value);
    return false if is_off_state($value);

    confess "Can't translate state '$value' to binary" if $die_on_error;
    return $value;
}

sub is_state {
    my ($value) = @_;
    return true if is_on_state($value) || is_off_state($value);
    return false;
}

sub is_on_state {
    my ($value) = @_;
    return true if $value == true
        || $value eq ON       || $value eq OPEN
        || $value eq PINGABLE || $value eq UNLOCKED;
    return false;
}

sub is_off_state {
    my ($value) = @_;
    return true if $value == false
        || $value eq OFF          || $value eq CLOSED
        || $value eq NOT_PINGABLE || $value eq LOCKED;
    return false;
}

1;
