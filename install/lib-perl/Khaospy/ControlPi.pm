package Khaospy::ControlPi;
use strict;
use warnings;
# By Karl Kount-Khaos Hoskin. 2015-2016

# Does the dispatch to either ControlPiGPIO or ControlPiMCP23017

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Khaospy::Conf::Controls qw(
    get_controls_conf
);

use Khaospy::Constants qw(
    IN $IN OUT $OUT
);

use Khaospy::ControlPiGPIO qw(
    init_pi_gpio_controls
    operate_pi_gpio_relay
    operate_pi_gpio_relay_manual
    operate_pi_gpio_switch
);

use Khaospy::ControlPiMCP23017 qw(
    init_pi_mcp23017_controls
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

our @EXPORT_OK = qw(
    init_pi_controls
    operate_control
);

sub init_pi_controls {
    get_controls_conf
    init_pi_gpio_controls();
    init_pi_mcp23017_controls();
}

my $dispatch = {
    'pi-gpio-relay'        => \&operate_pi_gpio_relay,
    'pi-gpio-switch'       => \&operate_pi_gpio_switch,
    'pi-gpio-relay-manual' => \&operate_pi_gpio_relay_manual,
};

sub operate_control {
    my ($control_name, $control, $action ) = @_;

    my $type = $control->{type};

    return $dispatch->{$type}->($control_name,$control, $action)
        if exists $dispatch->{$type};

    # TODO change this to a fatal / exception once MCP23017 controls are implemented.
    klogerror "Control $control_name with type $control->{type} could be invalid. Or maybe it hasn't been programmed yet. Some are still TODO\n";
    return {};
}


1;
