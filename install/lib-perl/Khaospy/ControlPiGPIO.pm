package Khaospy::ControlPiGPIO;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;
use Time::HiRes qw/usleep time/;

use Khaospy::Conf::Controls qw(
    get_controls_conf_for_host
);

use Khaospy::Constants qw(
    $PI_GPIO_CMD
    true false
    ON OFF STATUS
    AUTO MANUAL
    IN $IN OUT $OUT
);

use Khaospy::ControlPiUtils qw(
    trans_true_to_ON
    trans_ON_to_true
    invert_state
);

use Khaospy::Exception qw(
    KhaospyExcept::ControlsConfigInvalidType
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

our @EXPORT_OK = qw(
    poll_pi_gpio_controls
    init_pi_gpio_controls
    operate_pi_gpio_switch
    operate_pi_gpio_relay
    operate_pi_gpio_relay_manual
);

my $pi_controls_state = {};

my $init_dispatch = {
    'pi-gpio-relay'        => \&init_pi_gpio_relay,
    'pi-gpio-switch'       => \&init_pi_gpio_switch,
    'pi-gpio-relay-manual' => \&init_pi_gpio_relay_manual,
};

my $poll_dispatch = {
    'pi-gpio-relay'        => undef,
    'pi-gpio-switch'       => \&poll_pi_gpio_switch,
    'pi-gpio-relay-manual' => \&poll_pi_gpio_relay_manual,
};

my $controls_for_host;

sub init_pi_gpio_controls {
    kloginfo "Initialise PiGPIO controls";
    $controls_for_host = get_controls_conf_for_host();
    _dispatch($init_dispatch, "Initialise");
}

sub poll_pi_gpio_controls {
    my ($callback) = @_;
    klogdebug "Poll Pi GPIO controls";
    _dispatch($poll_dispatch, "Poll", $callback);
}

sub _dispatch {
    my ($dispatch,$dispatch_name, $callback) = @_;
    for my $control_name ( keys %$controls_for_host ){

        my $control = $controls_for_host->{$control_name};
        my $type = $control->{type};

        if ( exists $dispatch->{$type} ){
            next if ! defined $dispatch->{$type};
            klogdebug "$dispatch_name control $control_name";
            $dispatch->{$type}->(
                $control_name,
                $control,
                $callback
            );
            next;
        }

        KhaospyExcept::ControlsConfigInvalidType->throw(
            error => "Can't $dispatch_name unknown control type ($type)"
        );
    }
}

# pi_control_state for "relay" or "switch" = {
#     control_name => {
#         last_change_state        ( ON/OFF )
#         last_change_state_time   ( timestamp )
#     }
# }

sub _get_and_set_switch_or_relay_state {
    # NOT for relay-manual .only "relay" or "switch" controls.
    # ( where invert_state is simpler, and no "ex_or_for_state". )
    my ($control_name,$control, $gpio_num) = @_;

    my $current_state = trans_true_to_ON(
        invert_state($control,read_pi_gpio($gpio_num))
    );

    $pi_controls_state->{$control_name} = {}
        if ! exists $pi_controls_state->{$control_name};

    my $pi_c_state = $pi_controls_state->{$control_name};

    if ( ! exists $pi_c_state->{last_change_state}
         || $pi_c_state->{last_change_state} ne $current_state
    ){
        $pi_c_state->{last_change_state} = $current_state;
        $pi_c_state->{last_change_state_time} = time;
    }

    return {
        current_state => $current_state,
        %{$pi_c_state},
    };
}

sub init_pi_gpio_switch {
    my ($control_name,$control) = @_;
    my $gpio_num = $control->{gpio_switch};
    init_pi_gpio($gpio_num, IN);
    _get_and_set_switch_or_relay_state(
        $control_name,
        $control,
        $gpio_num,
    );
}

sub poll_pi_gpio_switch {
    my ($control_name,$control,$callback) = @_;

    my $pi_c_state = $pi_controls_state->{$control_name};

    my $current_state = trans_true_to_ON(
        invert_state($control,read_pi_gpio($control->{gpio_switch}))
    );

    if ( $pi_c_state->{last_change_state} ne $current_state ){
        $pi_c_state->{last_change_state} = $current_state;
        $pi_c_state->{last_change_state_time} = time;
        kloginfo "Control $control_name has changed to $current_state";

        $callback->({
            control_name  => $control_name,
            control_host  => $control->{host},
            current_state => $current_state,
            %{$pi_c_state},
        }) if defined $callback;
    }
}

sub operate_pi_gpio_switch {
    my ($control_name,$control, $action) = @_;

    kloginfo "OPERATE  $control_name ( Pi GPIO Switch ) with $action";

    klogerror "Can only operate a switch with 'status'. ( not '$action' )"
        if $action ne STATUS;

    my $gpio_num = $control->{gpio_switch};

    return _get_and_set_switch_or_relay_state(
        $control_name,
        $control,
        $gpio_num,
    );
}

###################
# pi gpio relay

sub init_pi_gpio_relay {
    my ($control_name,$control) = @_;
    my $gpio_num = $control->{gpio_relay};
    init_pi_gpio($gpio_num, OUT);
    _get_and_set_switch_or_relay_state(
        $control_name,
        $control,
        $gpio_num,
    );
}

sub operate_pi_gpio_relay {
    my ($control_name,$control, $action) = @_;

    kloginfo "OPERATE $control_name ( Pi Relay ) with $action";

    my $gpio_num = $control->{gpio_relay};

    write_pi_gpio($gpio_num, trans_ON_to_true(invert_state($control,$action)))
        if $action ne STATUS;

    return _get_and_set_switch_or_relay_state(
        $control_name,
        $control,
        $gpio_num,
    );
}

#############################
# relay-manual
#
# Khaospy is going to need to detect that the control has been manually operated.
# This is useful for the "rules" part.
# i.e a rule will know the last-manual-operation time.
# So the following state information will be returned
# with any ON OFF or STATUS action.
#
# pi_control_state for "relay-manual" = {
#     control_name => {
#         last_change_state_time              ( on/off )
#         last_change_state_by                ( auto/manual )
#         last_manual_gpio_detect_change      ( true / false )
#         last_manual_gpio_detect_change_time ( time )
#         last_auto_gpio_relay_change         ( true / false )
#         last_auto_gpio_relay_change_time    ( time )
#     }
# }

sub init_pi_gpio_relay_manual {
    my ($control_name,$control) = @_;

    my $gpio_relay_num = $control->{gpio_relay};
    init_pi_gpio($gpio_relay_num, OUT);

    my $gpio_detect_num = $control->{gpio_detect};
    init_pi_gpio($gpio_detect_num, IN);

    $pi_controls_state->{$control_name} = {};

    my $pi_c_state = $pi_controls_state->{$control_name};

    $pi_c_state->{last_auto_gpio_relay_change_time} = time;
    $pi_c_state->{last_auto_gpio_relay_change} =
        read_pi_gpio($gpio_relay_num);

    $pi_c_state->{last_manual_gpio_detect_change_time} = 0;
    $pi_c_state->{last_manual_gpio_detect_change} =
        read_pi_gpio($gpio_detect_num);

    $pi_c_state->{last_change_state_time} = time;
    $pi_c_state->{last_change_state_by} = AUTO;
}

sub _calc_current_relay_manual_circuit_state {
    # returns ON or OFF
    my ($control_name,$control) = @_;

    my $relay_state  = read_pi_gpio($control->{gpio_relay});
    my $detect_state = read_pi_gpio($control->{gpio_detect});

    return trans_true_to_ON(
            invert_state($control, ( $relay_state xor $detect_state) )
        ) if ( $control->{ex_or_for_state} );

    return trans_true_to_ON(
            invert_state($control, $detect_state)
        );
}

# pi_control_state for "relay-manual" = {
#     control_name => {
#         last_change_state_time              ( on/off )
#         last_change_state_by                ( auto/manual )
#         last_manual_gpio_detect_change      ( true / false )
#         last_manual_gpio_detect_change_time ( time )
#         last_auto_gpio_relay_change         ( true / false )
#         last_auto_gpio_relay_change_time    ( time )
#     }
# }

sub poll_pi_gpio_relay_manual {
    my ($control_name,$control,$callback) = @_;

    my $pi_c_state = $pi_controls_state->{$control_name};

    my $gpio_detect_num = $control->{gpio_detect};
    my $gpio_detect_value = read_pi_gpio($gpio_detect_num);

    if ( $gpio_detect_value != $pi_c_state->{last_manual_gpio_detect_change} ){
        kloginfo "Control $control_name has been manually operated";
        $pi_c_state->{last_change_state_time} = time;
        $pi_c_state->{last_change_state_by}   = MANUAL;
        $pi_c_state->{last_manual_gpio_detect_change_time} = time;
        $pi_c_state->{last_manual_gpio_detect_change}      = $gpio_detect_value;

        $callback->({
            control_name  => $control_name,
            control_host  => $control->{host},
            current_state => _calc_current_relay_manual_circuit_state (
                $control_name, $control
            ),
            %{$pi_c_state},
        }) if defined $callback;
    }
}

sub operate_pi_gpio_relay_manual {
    my ($control_name,$control, $action) = @_;

    my $pi_c_state = $pi_controls_state->{$control_name};

    my $gpio_relay_num  = $control->{gpio_relay};
    my $gpio_detect_num = $control->{gpio_detect};

    my $current_state =
        _calc_current_relay_manual_circuit_state (
            $control_name, $control
        );

    kloginfo "OPERATE $control_name ( Pi Relay Manual ) with $action ( current state = $current_state )";

    poll_pi_gpio_relay_manual($control_name,$control);

    if ( $action eq STATUS
        ||  ( exists $control->{manual_auto_timeout}
                && $pi_c_state->{last_manual_gpio_detect_change_time}
                     + $control->{manual_auto_timeout} > time
            )
    ){

        if ( $action ne STATUS ){
            my $timeout_left = (
                $pi_c_state->{last_manual_gpio_detect_change_time}
                    + $control->{manual_auto_timeout} - time
            );

            kloginfo sprintf(
                "Control %s cannot be automatically operated for "
                ."another %.2f seconds ( manual_auto_timeout )",
                $control_name,
                $timeout_left
            );
        }

        return {
            current_state => $current_state,
            %{$pi_c_state},
        };
    } elsif ( $current_state eq $action ){
        kloginfo "Control $control_name doesn't need to be changed";

        return {
            current_state => $current_state,
            %{$pi_c_state},
        };
    }

    # The "auto" gpio_relay needs its state inverting/toggling
    # There are potential race-conditions here if someone operates
    # the manual switch at this point in the code.

    write_pi_gpio(
        $gpio_relay_num,
        read_pi_gpio($gpio_relay_num) ? false : true,
    );

    $current_state = _calc_current_relay_manual_circuit_state(
        $control_name, $control
    );

    $pi_c_state->{last_change_state_time} = time;
    $pi_c_state->{last_change_state_by}   = AUTO;

    $pi_c_state->{last_auto_gpio_relay_change_time} = time;
    $pi_c_state->{last_auto_gpio_relay_change}
        = read_pi_gpio($gpio_relay_num);

    # Update the last_manual_gpio_detect_change[_time] states
    my $gpio_detect_value = read_pi_gpio($gpio_detect_num);
    if ( $control->{ex_or_for_state} ) {
        # The auto operation should NOT have changed the voltage input on gpio_detect.
        if ( $gpio_detect_value != $pi_c_state->{last_manual_gpio_detect_change} ){
            $pi_c_state->{last_manual_gpio_detect_change_time} = time;
            $pi_c_state->{last_manual_gpio_detect_change}      = $gpio_detect_value;
            klogwarn "Control $control_name (exor = true) had its manual unexpectedly gpio_detect change. Could be a problem, could be someone changing the control mid auto-operation"
        }
    } else {
        # The auto operation should have changed the voltage input on the gpio_detect
        if ( $gpio_detect_value == $pi_c_state->{last_manual_gpio_detect_change} ){
            # Race condition ? Has the manual control been changed ?
            klogwarn "Control $control_name (exor = false) had its manual unexpectedly gpio_detect change. Could be a problem, could be someone changing the control mid auto-operation";
            $pi_c_state->{last_manual_gpio_detect_change_time} = time;
        }
        # Either way this needs updating :
        $pi_c_state->{last_manual_gpio_detect_change}      = $gpio_detect_value;
    }

    kloginfo "Control $control_name has been automatically operated";

    return {
        current_state => $current_state,
        %{$pi_c_state},
    };
}

########################################
# general gpio read, write and init subs
#
# For the initialisation, reading and writing of Pi GPIO pins.
# I should possibly use https://github.com/WiringPi/WiringPi-Perl
# but that needs compiling etc. No CPAN module. hmmm.
# From the CLI the init, read and write are done like so :
#  /usr/bin/gpio mode  4 out
#  /usr/bin/gpio write 4 0
#  /usr/bin/gpio write 4 1
#  /usr/bin/gpio read  4

sub init_pi_gpio {
    my ($gpio_num, $IN_OUT) = @_;
    $IN_OUT = lc( $IN_OUT );
    klogfatal "Can only set a Pi GPIO mode ($IN_OUT) to 'in' or 'out'"
        if $IN_OUT ne IN and $IN_OUT ne OUT;

    system("$PI_GPIO_CMD mode $gpio_num $IN_OUT");
}

sub read_pi_gpio {
    my ($gpio_num) = @_;
    my $r = qx( $PI_GPIO_CMD read $gpio_num );
    chomp $r;
    return $r;
}

sub write_pi_gpio {
    my ($gpio_num, $val) = @_;
    system("$PI_GPIO_CMD write $gpio_num $val");
    return;
}

1;
