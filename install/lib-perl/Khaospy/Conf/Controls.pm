package Khaospy::Conf::Controls;
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use List::Compare;

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
);

# ALL Control must have a key called "type".
# The $types below names the only keys allowed for each "type" of control
# along the callback to check it.

my $check_mac = check_regex(
    qr/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/
);

my $check_boolean = check_regex(qr/^[01]$/);
my $check_optional_boolean
    = check_optional_regex(qr/^[01]$/);

my $check_types = {
    "orvibos20" => {
        alias     => \&check_optional,
        rrd_graph => $check_optional_boolean,
        host      => \&check_host,
        mac       => $check_mac,
    },
    "onewire-thermometer" => {
        alias         => \&check_optional,
        rrd_graph     => $check_optional_boolean,
        onewire_addr  => check_regex(
            qr/^[0-9A-Fa-f]{2}-[0-9A-Fa-f]{12}$/
        ),
    },
    "pi-gpio-relay-manual" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        ex_or_for_state => $check_boolean,
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_gpio,
        gpio_detect     => \&check_pi_gpio,
    },
    "pi-gpio-relay" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_gpio,
    },
    "pi-gpio-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_gpio,
    },
    "pi-mcp23017-relay-manual" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        ex_or_for_state => $check_boolean,
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_mcp23017,
        gpio_detect     => \&check_pi_mcp23017,
    },
    "pi-mcp23017-relay" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_relay      => \&check_pi_mcp23017,
    },
    "pi-mcp23017-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        host            => \&check_host_runs_pi_controls,
        invert_state    => $check_boolean,
        gpio_switch     => \&check_pi_mcp23017,
    },
    "mac-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
        mac             => $check_mac,
    },
    "ping-switch" => {
        alias           => \&check_optional,
        rrd_graph       => $check_optional_boolean,
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

sub get_control_config {
    my ( $control_name, $force_reload ) = @_;

    get_controls_conf($force_reload);

    die "Control '$control_name' doesn't exist in $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
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
            $collate_errors .= "$_\n";
        }
    }

    croak "Errors checking the controls config".
        " $KHAOSPY_CONTROLS_CONF_FULLPATH\n\n".
        "$collate_errors\n"
            if $collate_errors;
}

sub check_config {
    my ($control_name) = @_;

    my $control = $controls_conf->{$control_name};

    die "Control '$control_name' doesn't have a 'type' key"
        if ! exists $control->{type};

    my $type_from_file = lc($control->{type});

    die "Control '$control_name' has an invalid 'type' of $type_from_file"
        if ! exists $check_types->{$type_from_file};


    my $collate_errors = '';

    my $chk_type = $check_types->{$type_from_file};
    $chk_type->{type} = ''; # to make the List::Compare work

    my $lc = List::Compare->new ( '-u', [ keys %$chk_type ], [ keys %$control ] );
    if ( ! $lc->is_LequivalentR && ! $lc->is_RsubsetL ){
        $collate_errors .= "Control '$control_name' has unknown keys in the config ( ".join ("," , $lc->get_Ronly)." )\n";
    } else {
        # No extra keys in $control. Good.
        delete $chk_type->{type}; # only needed for List::Compare.
        for my $chk ( keys %$chk_type ) {
            try {
                $chk_type->{$chk}->($control_name, $control, $chk);
            } catch {
                $collate_errors .= "$_\n";
            }
        }
    }
    die $collate_errors if $collate_errors;
}

sub check_exists {
    my ($control_name, $control, $chk, $extra ) = @_;
    $extra = "" if ! $extra;
    die "Control '$control_name' doesn't have a '$chk' configured. (non-existent-key). $extra"
        if ! exists $control->{$chk};
}

sub check_regex {
    my ($regex) = @_;
    return sub {
        my ($control_name, $control, $chk, $extra) = @_;
        $extra = "" if ! $extra;
        check_exists(@_);
        my $val = $control->{$chk};
        die "Control '$control_name' has an invalid '$chk' ($val) configured. $extra"
            if ( $val !~ $regex );
    }
}

sub check_optional_regex {
    my ($regex) = @_;
    return sub {
        my ($control_name, $control, $chk, $extra) = @_;
        return if ! exists $control->{$chk};

        $extra = "" if ! $extra;
        my $val = $control->{$chk};
        die "Control '$control_name' has an invalid '$chk' ($val) configured. $extra"
            if ( $val !~ $regex );
    }
}

sub check_host {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};
    _is_host_resolvable($val);
    # TODO could check if the host is resolvable.
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

    die "Pi-host '$host' doesn't have 'valid_gpios' configured.\n"
        ."The valid_gpios are defined in the pi-host config $KHAOSPY_PI_HOSTS_CONF_FULLPATH.\n"
        ."Control '$control_name' cannot be checked for the validity of '$chk'"
            if ! defined $valid_gpios;

    die "Control '$control_name' has an invalid gpio for '$chk' of '$val'\n"
        ."The valid_gpios defined for the pi-host '$host'"
        ." in $KHAOSPY_PI_HOSTS_CONF_FULLPATH are (".join(',', @$valid_gpios).")"
            if ! grep { $_ == $val } @$valid_gpios;

    my $uniq = "host=$control->{host}|gpio=$val";

    die "Control '$control_name' is using the same "
        ."pi_gpio as control '$pi_gpio_unique->{$uniq}'"
        .". unique-key = '$uniq'"
        if exists $pi_gpio_unique->{$uniq};

    $pi_gpio_unique->{$uniq} = $control_name;
}

sub check_pi_mcp23017 {
    my ($control_name, $control, $chk) = @_;
    check_exists(@_);
    my $val = $control->{$chk};

    die "Control '$control_name' has an invalid '$chk' ($val) configured. Should be a hashref"
        if ( ref $val ne 'HASH' );

    # need to check the sub keys.

    # first check i2c_bus sub-key against valid ones in pi-host config.
    my $host = $control->{host};

    my $i2c_bus = $val->{i2c_bus};

    my $valid_i2c_buses = get_pi_host_config($host)->{valid_i2c_buses};

    die "Pi-host '$host' doesn't have 'valid_i2c_buses' configured.\n"
        ."The valid_i2c_buses are defined in the pi-host config $KHAOSPY_PI_HOSTS_CONF_FULLPATH.\n"
        ."Control '$control_name' cannot be checked for the validity of '$chk' (i2c_bus)"
            if ! defined $valid_i2c_buses;

    die "Control '$control_name' has an invalid i2c_bus for '$chk' of '$val'\n"
        ."The valid_i2c_buses defined for the pi-host '$host'"
        ." in $KHAOSPY_PI_HOSTS_CONF_FULLPATH are (".join(',', @$valid_i2c_buses).")"
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
          ."|portname".lc($control->{$chk}{portname})
          ."|portnum".$control->{$chk}{portnum};

    die "Control '$control_name' is using the same "
        ."pi_mcp23017 gpio as control '$pi_mcp23017_unique->{$uniq}'"
        .". unique-key = '$uniq'"
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
    # will die / raise excepiton if host isn't resolvable.

    # die "$host is not resolvable";

    return;
}

1;
