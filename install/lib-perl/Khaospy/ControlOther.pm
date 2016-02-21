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
    get_control_config
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
    KhaospyExcept::UnhandledControl
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

use Khaospy::OrviboS20;

our @EXPORT_OK = qw(
    poll_controls
    init_controls
    operate_control
);

sub check_host { false }

sub init_controls {
    get_controls_conf();
}

sub poll_controls {
    my ($class, $callback) = @_;
#    poll_pi_gpio_controls($callback);
}

sub operate_control {
    my ( $class, $control_name, $control, $action ) = @_;

    if ($control->{type} eq 'orviboS20'){
        return _orvibo_command( $control_name, $control, $action);
    }

    KhaospyExcept::UnhandledControl->throw(
        error => "Control $control_name is not handled by this module"
    );
}

sub _orvibo_command {
    my ( $control_name, $control, $action ) = @_;

    kloginfo "run orviboS20 command '$control_name $action'";

    my $current_state;

    eval { $current_state = Khaospy::OrviboS20::signal_control(
            $control->{host}, $control->{mac}, $action
        );
    };

    if ( $@ || ! $current_state ) {
        klogerror $_;
        return {};
    }

    return { current_state => $current_state, };
}


1;
