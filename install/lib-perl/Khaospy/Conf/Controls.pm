package Khaospy::Conf::Controls;
use strict; use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2017

use Exporter qw/import/;

our @EXPORT_OK = qw(
    get_control_config
    control_exists
    get_controls_conf
    get_controls_conf_for_host
    get_control_name_for_one_wire
    is_control_rrd_graphed
    get_rrd_create_params_for_control

    can_set_on_off
    can_set_value
    can_set_string

    state_trans_control
    state_to_binary_die
    state_to_binary

    control_good_state
    get_one_wire_therm_desired_range
    validate_control_state_action
);

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
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

    STATUS

    true  $true  OPEN   $OPEN   ON  $ON  PINGABLE     $PINGABLE     UNLOCKED $UNLOCKED
    false $false CLOSED $CLOSED OFF $OFF NOT_PINGABLE $NOT_PINGABLE LOCKED   $LOCKED

    STATE_TYPE_ON_OFF
    STATE_TYPE_OPEN_CLOSED
    STATE_TYPE_PINGABLE_NOT_PINGABLE
    STATE_TYPE_UNLOCKED_LOCKED

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

use Khaospy::Conf;

use Khaospy::Conf::Global qw(
    gc_TEMP_RANGE_DEG_C
);

use Khaospy::Conf::PiHosts qw(
    get_pi_host_config
    get_pi_hosts_running_daemon
);

use Khaospy::Utils qw(
    get_hashval
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

my $check_optional_on_off
    = check_optional_regex_sub(qr/^(on|off)$/);

##################
# can_set_XXXX() methods
# These are used by the webui to work out what type of control
# interface to display.

my $can_set_on_off = {
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
    STATE_TYPE_ON_OFF()                => \&state_trans_on_off,
    STATE_TYPE_OPEN_CLOSED()           => \&state_trans_open_closed,
    STATE_TYPE_PINGABLE_NOT_PINGABLE() => \&state_trans_pingable_unpingable,
    STATE_TYPE_UNLOCKED_LOCKED()       => \&state_trans_unlocked_locked,
};


###########################
# control conf checking definition :

my $check_types = {
    $ORVIBOS20_CONTROL_TYPE => {
        alias        => \&check_optional,
        state_type   => \&check_optional_state_type,
        rrd_graph    => $check_optional_boolean,
        good_state   => $check_optional_on_off,
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
        desired_temp_float_control =>
            \&check_optional_webui_float_control,
        desired_temp_range_float_control =>
            \&check_optional_webui_float_control,
    },
    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        good_state      => $check_optional_on_off,
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
        good_state      => $check_optional_on_off,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_gpio,
    },
    $PI_GPIO_SWITCH_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        good_state      => $check_optional_on_off,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_gpio,
    },
    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        good_state      => $check_optional_on_off,
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
        good_state      => $check_optional_on_off,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_mcp23017,
    },
    $PI_MCP23017_SWITCH_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        good_state      => $check_optional_on_off,
        host            =>
            check_host_runs_sub($PI_CONTROLLER_DAEMON_SCRIPT),
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_mcp23017,
    },
    $MAC_SWITCH_CONTROL_TYPE => {
        alias           => \&check_optional,
        state_type      => \&check_optional_state_type,
        rrd_graph       => $check_optional_boolean,
        good_state      => $check_optional_on_off,
        mac             => $check_mac,
        sub_type        => \&check_mac_sub_type,
    },
    $WEBUI_VAR_FLOAT_CONTROL_TYPE => {
        alias           => \&check_optional,
#        rrd_graph       => $check_optional_boolean,
        value           => \&check_number,
        upper_limit     => \&check_optional_number,
        lower_limit     => \&check_optional_number,
    },
    $WEBUI_VAR_INTEGER_CONTROL_TYPE => {
        alias           => \&check_optional,
#        rrd_graph       => $check_optional_boolean,
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

sub can_set_on_off {
    my ($control_name) = @_;
    get_controls_conf();
    my $control = get_hashval($controls_conf, $control_name);

    return true if exists $can_set_on_off->{get_hashval($control,'type')};
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
    Khaospy::Conf::get_conf(
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
        # TODO , can this be simplified ? :
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

sub check_optional_webui_float_control {
    my ($control_name, $control, $chk) = @_;

    return if ! exists $control->{$chk};

    # wvflt = webui-var-float
    my $wvflt_control_name = $control->{$chk};

    # the control doesn't exist error
    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error => "Control '$control_name' has an invalid '$chk' "
            ."control ($wvflt_control_name) doesn't exist"
    )
        if ! exists $controls_conf->{$wvflt_control_name};

    my $wvflt_control = $controls_conf->{$wvflt_control_name};
    my $wvflt_control_type = get_hashval($wvflt_control,'type');

    # wvflt control is of the wrong type.
    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error => "Control '$control_name' has an invalid '$chk' "
            ."control ($wvflt_control_name) is not of type "
            .$WEBUI_VAR_FLOAT_CONTROL_TYPE
    )
        if $wvflt_control_type ne $WEBUI_VAR_FLOAT_CONTROL_TYPE;

}

sub check_optional_state_type {
    my ($control_name, $control, $chk) = @_;

    return if ! exists $control->{$chk};

    my $val = $control->{$chk};

    KhaospyExcept::ControlsConfigKeysInvalidValue->throw(
        error => "Control '$control_name' has an invalid '$chk' "
            ."($val) configured ".Dumper($state_trans_type)
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
    # "null op".
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

# TODO some of the state_trans stuff really could be simplified.
# the original idea was dropped.
# Now this is just doing translations for the webui ...

sub state_trans_control {
    # used by Khaospy::DBH::Controls calls to make the current_state_trans field

    my ($control_name, $value) = @_;
    return '' if ! defined $value;
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
        } elsif ( $control_type eq $ONEWIRE_THERM_CONTROL_TYPE ) {
            return sprintf('%+0.1f', $value);
        }
        return $value if ! $state_type;
    }
    return $state_trans_type->{$state_type}->($value);
}

sub state_trans_on_off{
    my ($value) = @_;
    return if ! defined $value;
    return ON  if $value eq ON  || $value =~ /^1$/;
    return OFF if $value eq OFF || $value =~ /^0$/;
    confess "can't translate $value to ON or OFF";
}

sub state_trans_open_closed{
    my ($value) = @_;
    return if ! defined $value;
    return OPEN   if $value eq ON  || $value =~ /^1$/;
    return CLOSED if $value eq OFF || $value =~ /^0$/;
    confess "can't translate $value to OPEN or CLOSED";
}

sub state_trans_pingable_unpingable{
    my ($value) = @_;
    return if ! defined $value;
    return PINGABLE     if $value eq ON  || $value =~ /^1$/;
    return NOT_PINGABLE if $value eq OFF || $value =~ /^0$/;
    confess "can't translate $value to PINGABLE OR UNPINGABLE";
}

sub state_trans_unlocked_locked{
    my ($value) = @_;
    return if ! defined $value;
    return UNLOCKED if $value eq ON  || $value =~ /^1$/;
    return LOCKED   if $value eq OFF || $value =~ /^0$/;
    confess "can't translate $value to UNLOCKED or LOCKED";
}

sub state_to_binary_die {
    return state_to_binary($_[0],true);
}

sub state_to_binary {
    my ($value, $die_on_error) = @_;
    $value = '' if ! defined $value;
    return true  if $value eq ON  || $value =~ /^1$/;
    return false if $value eq OFF || $value =~ /^0$/;

    confess "Can't translate state '$value' to binary" if $die_on_error;
    return $value;
}

sub is_state {
    # This is only used by validate_control_state_action, do I need it ?
    my ($value) = @_;

    return true if
          $value eq ON  || $value =~ /^1$/
       || $value eq OFF || $value =~ /^0$/;

    return false;
}

sub is_binary_control {
    my ($control_name) = @_;
    die "TODO not implemented";
    # will return true for on/off, open/closed, unlocked/locked, pingable/not-pingable
    # types of control
    # will return false for everything else.

}

sub control_good_state {
    # used by Khaospy::DBH::Controls calls to make the good_state field
    my ($control_name) = @_;

    my $control = get_control_config($control_name);

    my $control_type = get_hashval($control,'type');
    my $good_state = $control->{good_state};

    return $good_state if $good_state;

    # All binary on-off controls should have a default "good_state".
    # Good is usually "off".
    # Good will display "green" in the webui.
    if (   $control_type eq $ORVIBOS20_CONTROL_TYPE
        || $control_type eq $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE
        || $control_type eq $PI_GPIO_RELAY_CONTROL_TYPE
        || $control_type eq $PI_GPIO_SWITCH_CONTROL_TYPE
        || $control_type eq $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE
        || $control_type eq $PI_MCP23017_RELAY_CONTROL_TYPE
        || $control_type eq $PI_MCP23017_SWITCH_CONTROL_TYPE
    ){
        return OFF;
    } elsif ($control_type eq $MAC_SWITCH_CONTROL_TYPE ){
        # Good for a mac address is "pingable" which is ON.
        return ON;
    }

    # non binary controls don't have a good_state.
    return '';
}

sub validate_control_state_action {
    my ($control_name, $action) = @_;
    get_controls_conf();

    # $action is also really $state.
    #
    # TODO needs to validate what $action ( or $state) is valid for a control

    confess "The state/action is not defined" if ! defined $action;

    # $action can be :
    #  a valid state ( see is_state() ) or STATUS
    #  a numeric value
    #  an array-ref or hash-ref of :
    #       ON or OFF strings
    #       numeric values
    #  Also an array or hash ref all have to be of the same type.
    #  That is they either have to all be ( ON, OFF or STATUS)
    #   OR they can all be numerics.

    # this sub serialises the arrays so that they can be used in _get_control_message_key()
    # it is not designed for deserialisation. ( due to making sorted hashkeys turn into an array )

    my $valid = sub {
        my ( $act ) = @_;

        # TODO. minor bug here, STATUS should only validate in the scalar context.
        # i.e. no arrays or hashes are allowed to have status.

        return "IS-STATE" if is_state($act) || $act eq STATUS;

        return "NUMBER" if ( looks_like_number($act) );

        my $errmsg ="ERROR. The action '$act' can only be a valid-state, 'status' or a numeric\n";
        $errmsg .= "In the structure :\n".Dumper($action)
            if (ref $action eq 'ARRAY' or ref $action eq 'HASH' );
        confess $errmsg;
    };

    my $check_types_same = sub {
        my ($ar) = @_;
        confess "ERROR. The action has different types ( numerics mixed with ON, OFF,STATUS )\n"
            ."In the structure :\n".Dumper($action)
               if ! all {$ar->[0] eq $_} @$ar;
    };

    if ( ref $action eq 'HASH' ){
        confess "The action 'hash' is empty"
            if ! scalar keys %$action;

        $check_types_same->([ map { $valid->($action->{$_}) } keys %$action ]);
        return $JSON->encode([
            map {$_ => $action->{$_}} sort keys %$action
        ]);
    }

    if ( ref $action eq 'ARRAY' ){
        confess "The action 'array' is empty"
            if ! scalar @$action;

        $check_types_same->([ map { $valid->($_) } @$action ]);
        return $JSON->encode($action);
    }

    $valid->($action);
    return $action;
}

sub get_one_wire_therm_desired_range {
    my ($ow_control_name, $db_rows) = @_;
    # This is only going to be used by a DBH::Controls call,
    # that would've queried the DB.
    # hence db_rows to get the latest values off any
    # $WEBUI_VAR_FLOAT_CONTROLs
    #
    # returns ( lower, higher ) or ( undef, undef )

    my $ow_control = get_control_config($ow_control_name);

    return (undef, undef) if
        get_hashval($ow_control,'type') ne $ONEWIRE_THERM_CONTROL_TYPE
        || ! $ow_control->{desired_temp_float_control};

    my $dtfc_control_name = $ow_control->{desired_temp_float_control};
    my $dtfc_control      = get_control_config($dtfc_control_name);
    my $desired_value =
        _find_control_field_in_rows($dtfc_control_name, 'current_state', $db_rows);

    return ( undef, undef ) if ! $desired_value;

    my $desired_range;

    if ( exists $ow_control->{desired_temp_range_float_control} ){
        my $rng_control_name = $ow_control->{desired_temp_range_float_control};
        $desired_range =
            _find_control_field_in_rows($rng_control_name, 'current_state', $db_rows);
    }

    $desired_range = gc_TEMP_RANGE_DEG_C() if ! $desired_range;

    my $lower  = $desired_value - ( abs($desired_range) / 2 );
    my $higher = $desired_value + ( abs($desired_range) / 2 );

    return ($lower, $higher);
}

sub _find_control_field_in_rows {
    my ($control_name, $field, $db_rows ) = @_;

    return if ! $db_rows || ref $db_rows ne 'ARRAY';

    for my $rec (@$db_rows) {
        if ( get_hashval($rec,'control_name') eq $control_name ){
            return get_hashval($rec,$field,true);
        }
    }

    return;
}

1;
