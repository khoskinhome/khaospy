package Khaospy::ControlPi;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Khaospy::Conf::Controls qw(
    get_controls_conf
);

use Khaospy::ControlPiGPIO qw(
    init_pi_gpio_controls
    operate_pi_gpio_relay
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

sub operate_control {
    my ($control_name, $control, $action ) = @_;

    if ( $control->{type} eq 'pi-gpio-relay' ){
        return operate_pi_gpio_relay($control_name,$control, $action);
    } else {

        klogerror "Control $control_name with type $control->{type} could be invalid. Or maybe it hasn't been programmed yet. Some are still TODO\n";
        return;
    }



}

1;
