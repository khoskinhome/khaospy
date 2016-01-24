package Khaospy::Conf::Controls;
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
    $KHAOSPY_CONTROLS_CONF_FULLPATH
);

use Khaospy::Utils;

our @EXPORT_OK = qw(
    get_controls_conf
    get_control_config
);

# ALL Control must have a key called "type".
# The $types below names the only keys allowed for each "type" of control
# along the callback to check it.

my $check_mac = check_regex(
    qr/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/
);

my $check_boolean = check_regex(qr/^[01]$/);

#################################
# Checking the values of Pi GPIOs
#################################
# This isn't valid for all Pi-s some have more
# Also different configurations change the amount of GPIOs available.

# I would need someway for the code when running on the specific Pi
# to try and work out its model and revision.
# This would then need to work out when GPIOs are used for other functions. SPI/I2C etc.
#
# The first 8 gpios are generally available on all Pi-s. ( 0-7 )
# I guess one easy way for me to code this is to allow an override in the config, on a
# per-pi-host basis. TODO , what I've just said.

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

my $pi_mcp23017_unique;
my $pi_gpio_unique;

sub _validate_controls_conf {
    $pi_mcp23017_unique = {};
    $pi_gpio_unique     = {};
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
    my ($control_name, $control, $chk, $extra ) = @_;
    croak "ERROR control $control_name doesn't have a $chk configured. $extra"
        ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
        if ! exists $control->{$chk};
}

sub check_regex {
    my ($regex) = @_;
    return sub {
        my ($control_name, $control, $chk, $extra) = @_;
        check_exists(@_);
        my $val = $control->{$chk};
        croak "ERROR control $control_name has an invalid $chk ($val) configured. $extra"
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

    croak "ERROR control $control_name has an invalid $chk ($val) configured. Should be a hashref"
        ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
        if ( ref $val ne 'HASH' );

    # need to check the sub keys.
    check_regex(qr/^01$/)->(       $control_name , $val, "i2c_bus",  "(on $chk)");
    check_regex(qr/^0x2[0-7]$/)->( $control_name , $val, "i2c_addr", "(on $chk)");
    check_regex(qr/^[abAB]$/)->(   $control_name , $val, "portname", "(on $chk)");
    check_regex(qr/^[0-7]$/)->(    $control_name , $val, "portnum",  "(on $chk)");

    # Need to keep track of what mcp23017 gpios have been used on a host basis.
    # The unique key is :
    #   host | i2c_bus | i2c_addr | portname | portnum
    # A gpio can only be used for one control.

    my $uniq = "host=".$control->{host}
          ."|i2c_bus=".$control->{$chk}{i2c_bus}
          ."|i2c_addr=".$control->{$chk}{i2c_addr}
          ."|portname".lc($control->{$chk}{portname})
          ."|portnum".$control->{$chk}{portnum};

    croak "ERROR control $control_name is using the same "
        ."pi_mcp23017 gpio as control ".$pi_mcp23017_unique->{$uniq}
        .". unique-key = ".$uniq
        if exists $pi_mcp23017_unique->{$uniq};

    $pi_mcp23017_unique->{$uniq} = $control_name;
}

sub check_optional {
    # do absolutely "nuffin" !
}





1;
