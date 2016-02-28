package Khaospy::ControlOther;
use strict;
use warnings;
# By Karl Kaiser-Kount-Khaos Hoskin. 2015-2016

# All the controls here are probably going to be conceptually like "relay-manual" controls.
# i.e. they can be control by Khaospy, but other things can operate them.
# In the case of Orvibo S20s they have a manual push switch on them.

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;
use Time::HiRes qw/time/;
use Sys::Hostname;

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

use Khaospy::ControlDispatch qw(
    init_dispatch
    dispatch_poll
    dispatch_operate
);

use Khaospy::Exception qw(
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

sub check_host_field { "poll_host" }

my $controls_state = {};

sub unhandled_type_cb {
    my ($control_name) = @_;

    KhaospyExcept::UnhandledControl->throw(
        error => "Control $control_name is not handled by this module"
    );
}

sub init_controls {
    # my ($class) = @_;
    kloginfo "Initialise Other controls";

    init_dispatch(
        {
            init    => {
                orviboS20 => \&poll_orvibo_s20,
            },
            poll    => {
                orviboS20 => \&poll_orvibo_s20,
            },
            operate => {
                orviboS20 => \&operate_orvibo_s20,
            },
        },
        \&unhandled_type_cb,
        get_controls_conf_for_host(undef,check_host_field()),
    );
}

sub poll_controls {
    my ($class, $poll_callback) = @_;
    klogdebug "Poll Other Controls";
    dispatch_poll($poll_callback);
}

sub operate_control {
    my ( $class, $control_name, $control, $action ) = @_;
    kloginfo "Operate Control '$control_name $action'";
    dispatch_operate( $control_name, $control, $action );
}

##############

sub operate_orvibo_s20 {
    my ( $control_name, $control, $action , $state_change_by  ) = @_;

    $state_change_by = AUTO if ! $state_change_by;

    my $current_state;

    eval { $current_state = Khaospy::OrviboS20::signal_control(
            $control->{host}, $control->{mac}, $action
        );
    };

    if ( $@ || ! $current_state ){
        klogerror $_;
        return {};
    }

    $controls_state->{$control_name} = {}
        if ! exists $controls_state->{$control_name};
    my $c_state = $controls_state->{$control_name};

    if ( ! exists $c_state->{last_change_state}
        || $c_state->{last_change_state} ne $current_state
    ){
        # so when this gets called by "init" , it defaults to AUTO. hmm.
        $c_state->{last_change_state}      = $current_state || "error";
        $c_state->{last_change_state_time} = time;
        $c_state->{last_change_state_by}   = $state_change_by;
    }

    return { %$c_state, current_state => $current_state, };
}

sub poll_orvibo_s20 {
    my ( $control_name, $control, $poll_callback ) = @_;

    $controls_state->{$control_name} = {}
        if ! exists $controls_state->{$control_name};
    my $c_state = $controls_state->{$control_name};

    # orvibo-s20 can have control setting "poll_timeout"
    $c_state->{last_poll_time} = 0 if ! defined $c_state->{last_poll_time};

    return if exists $control->{poll_timeout}
        && time + rand() < $c_state->{last_poll_time} + $control->{poll_timeout};

    $c_state->{last_poll_time} = time ;

    my $l_state = $c_state->{last_change_state} || "" ;
    my $ret = operate_orvibo_s20 ( $control_name, $control, STATUS, MANUAL );

    klogwarn "poll_orvibo_s20 : callback not defined ( this is okay during init )"
        if ! defined $poll_callback;

    klogdebug "Polled Control $control_name is '$ret->{current_state}'";

    $poll_callback->({
        control_name  => $control_name,
        control_host  => $control->{host},
        poll_host     => hostname,
        %$c_state,
    }) if $ret->{last_change_state} ne $l_state and defined $poll_callback;

    return;
}

1;
