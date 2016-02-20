package Khaospy::ControlOther;
use strict;
use warnings;
# By Karl Kount-Khaos Hoskin. 2015-2016

# All the controls here are probably going to be conceptually like "relay-manual" controls.
# i.e. they can be control by Khaospy, but other things can operate them.
# 

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Khaospy::Conf::Controls qw(
    get_controls_conf
    get_controls_conf_for_host
);

use Khaospy::Constants qw(
    true false
    ON OFF STATUS
    AUTO MANUAL
    IN $IN OUT $OUT
);

use Khaospy::ControlPiGPIO;
use Khaospy::ControlPiMCP23017 qw (
    init_mcp23017
);

use Khaospy::Exception qw(
    KhaospyExcept::ControlsConfigInvalidType
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

our @EXPORT_OK = qw(
    poll_controls
    init_controls
    operate_control
);

sub init_controls {
#    get_controls_conf();
#    init_controls();
#    init_mcp23017();
}

sub poll_controls {
    my ($class, $callback) = @_;
#    poll_pi_gpio_controls($callback);
}

sub operate_control {



}


1;
