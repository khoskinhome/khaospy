package Khaospy::ControlPi;
use strict;
use warnings;
# By Karl Kount-Khaos Hoskin. 2015-2016

# Has the main logic for "relay" , "switch" and "relay-manual" controls
# and the dispatch to either ControlPiGPIO or ControlPiMCP23017
# for the setting of the gpio pins.

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

#our @EXPORT_OK = qw(
#    poll_controls
#    init_controls
#    operate_control
#);

sub check_host { true }

sub init_controls {
    get_controls_conf();
    init_all_controls();
    init_mcp23017();
}

sub poll_controls {
    my ($class, $callback) = @_;
    poll_pi_gpio_controls($callback);
}

my $operate_dispatch = {
    'pi-gpio-relay'             => operate_relay('Khaospy::ControlPiGPIO'),
    'pi-gpio-switch'            => operate_switch('Khaospy::ControlPiGPIO'),
    'pi-gpio-relay-manual'      => operate_relay_manual('Khaospy::ControlPiGPIO'),
    'pi-mcp23017-relay'         => operate_relay('Khaospy::ControlPiMCP23017'),
    'pi-mcp23017-switch'        => operate_switch('Khaospy::ControlPiMCP23017'),
    'pi-mcp23017-relay-manual'  => operate_relay_manual('Khaospy::ControlPiMCP23017'),
};

my $init_dispatch = {
    'pi-gpio-relay'             => init_relay('Khaospy::ControlPiGPIO'),
    'pi-gpio-switch'            => init_switch('Khaospy::ControlPiGPIO'),
    'pi-gpio-relay-manual'      => init_relay_manual('Khaospy::ControlPiGPIO'),
    'pi-mcp23017-relay'         => init_relay('Khaospy::ControlPiMCP23017'),
    'pi-mcp23017-switch'        => init_switch('Khaospy::ControlPiMCP23017'),
    'pi-mcp23017-relay-manual'  => init_relay_manual('Khaospy::ControlPiMCP23017'),
};

my $poll_dispatch = {
    'pi-gpio-relay'             => undef,
    'pi-gpio-switch'            => poll_switch('Khaospy::ControlPiGPIO'),
    'pi-gpio-relay-manual'      => poll_relay_manual('Khaospy::ControlPiGPIO'),
    'pi-mcp23017-relay'         => undef,
    'pi-mcp23017-switch'        => poll_switch('Khaospy::ControlPiMCP23017'),
    'pi-mcp23017-relay-manual'  => poll_relay_manual('Khaospy::ControlPiMCP23017'),
};

sub operate_control {
    my ($class, $control_name, $control, $action) = @_;

    my $type = $control->{type};

    return $operate_dispatch->{$type}->($control_name,$control, $action)
        if exists $operate_dispatch->{$type};

    KhaospyExcept::ControlsConfigInvalidType->throw(
        error => "Control $control_name, can't operate. Unknown control type ($type)"
    );
}

my $pi_controls_state = {};

my $controls_for_host;

sub init_all_controls {
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
    my ($pin_class,$control_name,$control, $gpio_num) = @_;

    my $current_state = trans_true_to_ON(
        invert_state($control,read_gpio($pin_class,$gpio_num))
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

sub init_switch {
    my ($pin_class) = @_;
    return sub {
        my ($control_name,$control) = @_;
        my $gpio_num = $control->{gpio_switch};
        init_gpio($pin_class,$gpio_num, IN);
        _get_and_set_switch_or_relay_state(
            $pin_class,
            $control_name,
            $control,
            $gpio_num,
        );
    }
}

sub poll_switch {
    my ($pin_class) = @_;
    return sub {
        my ($control_name,$control,$callback) = @_;

        my $pi_c_state = $pi_controls_state->{$control_name};

        my $current_state = trans_true_to_ON(
            invert_state($control,read_gpio($pin_class,$control->{gpio_switch}))
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
    };
}

sub operate_switch {
    my ($pin_class) = @_;
    return sub {
        my ($control_name,$control, $action) = @_;

        kloginfo "OPERATE  $control_name ( Pi GPIO Switch ) with $action";

        klogerror "Can only operate a switch with 'status'. ( not '$action' )"
            if $action ne STATUS;

        my $gpio_num = $control->{gpio_switch};

        return _get_and_set_switch_or_relay_state(
            $pin_class,
            $control_name,
            $control,
            $gpio_num,
        );
    };
}

###################
# pi gpio relay

sub init_relay {
    my ($pin_class) = @_;
    return sub {
        my ($control_name,$control) = @_;
        my $gpio_num = $control->{gpio_relay};
        init_gpio($pin_class,$gpio_num, OUT);
        _get_and_set_switch_or_relay_state(
            $pin_class,
            $control_name,
            $control,
            $gpio_num,
        );
    };
}

sub operate_relay {
    my ($pin_class) = @_;
    return sub {
        my ($control_name,$control, $action) = @_;

        kloginfo "OPERATE $control_name ( Pi Relay ) with $action";

        my $gpio_num = $control->{gpio_relay};

        write_gpio(
            $pin_class,
            $gpio_num,
            trans_ON_to_true(invert_state($control,$action))
        )
            if $action ne STATUS;

        return _get_and_set_switch_or_relay_state(
            $pin_class,
            $control_name,
            $control,
            $gpio_num,
        );
    };
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

sub init_relay_manual {
    my ($pin_class) = @_;
    return sub {

        my ($control_name,$control) = @_;

        my $gpio_relay_num = $control->{gpio_relay};
        init_gpio($pin_class,$gpio_relay_num, OUT);

        my $gpio_detect_num = $control->{gpio_detect};
        init_gpio($pin_class,$gpio_detect_num, IN);

        $pi_controls_state->{$control_name} = {};

        my $pi_c_state = $pi_controls_state->{$control_name};

        $pi_c_state->{last_auto_gpio_relay_change_time} = time;
        $pi_c_state->{last_auto_gpio_relay_change} =
            read_gpio($pin_class,$gpio_relay_num);

        $pi_c_state->{last_manual_gpio_detect_change_time} = 0;
        $pi_c_state->{last_manual_gpio_detect_change} =
            read_gpio($pin_class,$gpio_detect_num);

        $pi_c_state->{last_change_state_time} = time;
        $pi_c_state->{last_change_state_by} = AUTO;
    };
}

sub _calc_current_relay_manual_circuit_state {
    # returns ON or OFF
    my ($pin_class, $control_name, $control) = @_;

    my $relay_state  = read_gpio($pin_class,$control->{gpio_relay});
    my $detect_state = read_gpio($pin_class,$control->{gpio_detect});

    return trans_true_to_ON(
            invert_state($control, ( $relay_state xor $detect_state) )
        ) if ( $control->{ex_or_for_state} );

    return trans_true_to_ON(
            invert_state($control, $detect_state)
        );
}

sub poll_relay_manual {
    my ($pin_class) = @_;
    return sub {
        my ($control_name,$control,$callback) = @_;

        my $pi_c_state = $pi_controls_state->{$control_name};

        my $gpio_detect_num = $control->{gpio_detect};
        my $gpio_detect_value = read_gpio($pin_class,$gpio_detect_num);

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
                    $pin_class, $control_name, $control
                ),
                %{$pi_c_state},
            }) if defined $callback;
        }
    };
}

sub operate_relay_manual {
    my ($pin_class) = @_;
    return sub {
        my ($control_name,$control, $action) = @_;

        my $pi_c_state = $pi_controls_state->{$control_name};

        my $gpio_relay_num  = $control->{gpio_relay};
        my $gpio_detect_num = $control->{gpio_detect};

        my $current_state =
            _calc_current_relay_manual_circuit_state (
                $pin_class, $control_name, $control
            );

        kloginfo "OPERATE $control_name ( Pi Relay Manual ) with $action ( current state = $current_state )";

        poll_relay_manual($pin_class)->($control_name,$control);

        if ( $action eq STATUS
            ||  ( exists $control->{manual_auto_timeout}
                    && $pi_c_state->{last_manual_gpio_detect_change_time}
                         + $control->{manual_auto_timeout} > time
                )
        ){

            my %extra_msg = ();
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
                $extra_msg{manual_auto_timeout_left} = $timeout_left;
            }

            return {
                %extra_msg,
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

        write_gpio(
            $pin_class,
            $gpio_relay_num,
            read_gpio($pin_class,$gpio_relay_num) ? false : true,
        );

        $current_state = _calc_current_relay_manual_circuit_state(
            $pin_class, $control_name, $control
        );

        $pi_c_state->{last_change_state_time} = time;
        $pi_c_state->{last_change_state_by}   = AUTO;

        $pi_c_state->{last_auto_gpio_relay_change_time} = time;
        $pi_c_state->{last_auto_gpio_relay_change}
            = read_gpio($pin_class,$gpio_relay_num);

        # Update the last_manual_gpio_detect_change[_time] states
        my $gpio_detect_value = read_gpio($pin_class,$gpio_detect_num);
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
            $pi_c_state->{last_manual_gpio_detect_change} = $gpio_detect_value;
        }

        kloginfo "Control $control_name has been automatically operated";

        return {
            current_state => $current_state,
            %{$pi_c_state},
        };
    }
}

sub init_gpio{
    my ($pin_class, $gpio, $iodir) = @_;
    try {
        return $pin_class->init_gpio($gpio, $iodir);
    } catch {
        log_gpio_err( $pin_class, $gpio, $_ );
    }
}

sub read_gpio{
    my ($pin_class, $gpio) = @_;
    try {
        return $pin_class->read_gpio($gpio);
    } catch {
        log_gpio_err( $pin_class, $gpio, $_ );
    }
}

sub write_gpio{
    my ($pin_class, $gpio, $new_state ) = @_;
    try {
        return $pin_class->write_gpio( $gpio, $new_state );
    } catch {
        log_gpio_err( $pin_class, $gpio, $_ );
    }
}

sub log_gpio_err {
    my ( $pin_class, $gpio, $err ) = @_;
    my ( $first_line, $rest ) = $err =~ /\A(.*?)\n(.*)/ms;

    klogerror sprintf ("%s : %s : %s : gpio = { %s }",
        $pin_class, ref ($_), $first_line,
        join (",", map { "$_ => $gpio->{$_}" } sort keys %$gpio )
    );

    klogdebug "ABOVE error. $rest";
}

sub trans_true_to_ON { # and false to OFF
    my ($truefalse) = @_;
    return ON  if $truefalse == true;
    return OFF if $truefalse == false;
    klogfatal "Can't translate a non true or false value ($truefalse) to ON or OFF";
}

sub trans_ON_to_true { # and OFF to false
    my ($ONOFF) = @_;
    return true  if $ONOFF eq ON;
    return false if $ONOFF eq OFF;
    klogfatal "Can't translate a non ON or OFF value ($ONOFF) to true or false";

}

sub invert_state {
    # looks at a control's "invert_state" key, and inverts the value supplied
    # to this sub if invert_state == true.
    #
    # inverts both ON/OFF and true/false $val's
    my ( $control, $val ) = @_;

    return $val
        if ! exists $control->{invert_state}
            || $control->{invert_state} eq false ;

    if ( $val eq ON || $val eq OFF ){

        return ($val eq ON) ? OFF : ON ;

    } elsif ($val eq true or $val eq false) {

        return ( $val ) ? false : true ;

    }

    klogfatal "Unrecognised value ($val) passed to invert_state()";
}
1;
