package Khaospy::BoilerDaemon;
use warnings;
use strict;

use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVMORE ZMQ_FD);
use Clone 'clone';
use POSIX qw(strftime);

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS

    $BOILERS_CONF_FULLPATH
    $BOILER_DAEMON_TIMER
    $BOILER_STATUS_REFRESH_EVERY_SECS
    $BOILER_DAEMON_DELAY_START
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror klogwarn  kloginfo  klogdebug
);

use Khaospy::Message      qw( validate_control_msg_json );
use Khaospy::QueueCommand qw( queue_command );
use Khaospy::Conf         qw( get_boiler_conf );
use Khaospy::Utils        qw( timestamp get_hashval );
use Khaospy::ZMQAnyEvent  qw( subscribe_to_controller_daemons );

use Khaospy::Conf::Controls qw(
    is_on_state
    is_off_state
);

our @EXPORT_OK = qw( run_boiler_daemon );

my $BOILER_STATUS;
my $BOILER_DAEMON_START_TIME;

my $boiler_conf;

sub run_boiler_daemon {

    klogstart "Boiler Daemon START";
    $BOILER_DAEMON_START_TIME = time;
    $boiler_conf = get_boiler_conf();
    init_BOILER_STATUS();
    my $quit_program = AnyEvent->condvar;

    my @w;

    # TODO only need to subscribe to the controllers that are
    # running rad-controllers. This is currently subscribing to EVERYTHING.
    subscribe_to_controller_daemons(
        \@w,
        {
            msg_handler       => \&process_boiler_message,
            msg_handler_param => "",
            klog              => true,
        }
    );

    push @w, AnyEvent->timer(
        after    => 0.1,
        interval => $BOILER_DAEMON_TIMER,
        cb       => \&timer_cb
    );

    $quit_program->recv;
}

sub timer_cb {

    check_boiler_next_on_at();

    # refresh the boiler-control and rad-control statuses :
    for my $boiler_name ( keys %$BOILER_STATUS ){
        my $boiler_state = $BOILER_STATUS->{$boiler_name};

        if ( ! defined $boiler_state->{current_status}
            || $boiler_state->{last_update} + $BOILER_STATUS_REFRESH_EVERY_SECS < time
        ){
            kloginfo "Get status of boiler control '$boiler_name'";
            queue_command ($boiler_name, STATUS);
        }

        my $boiler_controls = get_hashval($boiler_state, 'controls');
        for my $control_name ( keys %{$boiler_controls}){

            if ( ! defined $boiler_controls->{$control_name}
                || get_hashval( $boiler_state, 'controls_last_update')->{$control_name}
                        + $BOILER_STATUS_REFRESH_EVERY_SECS < time

            ){
                kloginfo "Get status of control '$control_name' ( for boiler '$boiler_name' )";
                queue_command ($control_name, STATUS);
            }
        }
    }
}

sub process_boiler_message {
    my ($zmq_sock, $msg, $param ) = @_;

    klogdebug "$param FROM CONTROLLER : $msg";
    my $msg_p  = validate_control_msg_json($msg);
    my $msg_rh = get_hashval( $msg_p, 'hashref' );

    my $control_name = get_hashval($msg_rh, 'control_name');

    my $c_state =
        get_hashval($msg_rh, 'current_state', true,'','')
        || get_hashval($msg_rh, 'last_change_state', true,'','');

    return if ! $c_state;

    klogdebug "Control $control_name is $c_state ";

    if ( grep { $_ eq $control_name  } keys %$BOILER_STATUS ) {
        # its a boiler-control ( not a rad-control ) hence :
        my $boiler_state = get_hashval($BOILER_STATUS, $control_name);

        if ( ! defined  $boiler_state->{current_status}
            || $boiler_state->{current_status} ne $c_state
        ){
            $boiler_state->{current_status} = $c_state;
            $boiler_state->{last_time_on}  = time if is_on_state($c_state);
            $boiler_state->{last_time_off} = time if is_off_state($c_state);
        }
        kloginfo "Boiler control '$control_name' is $c_state";
        $boiler_state->{last_update} = time;
        return;
    }

    my $boiler_name = get_boiler_name_for_control($control_name);
    return if ! $boiler_name;

    kloginfo "Control $control_name is $c_state. ( boiler-control '$boiler_name' )";
    $BOILER_STATUS->{$boiler_name}{controls}{$control_name} = $c_state;
    $BOILER_STATUS->{$boiler_name}{controls_last_update}{$control_name} = time;

    return if $BOILER_DAEMON_START_TIME + $BOILER_DAEMON_DELAY_START > time;

    operate_boiler( $boiler_name );
}

sub get_boiler_name_for_control {
    # goes through the $BOILER_STATUS and looks for a control.
    # returns either the boiler_name or undef.
    # will croak if 2 or more boilers have the same sub-control.

    my ($control_name) = @_;

    my @boiler_list;
    for my $boiler_name ( keys %$BOILER_STATUS ) {
        push @boiler_list, map { $boiler_name }
            grep { $control_name eq $_ }
            keys %{$BOILER_STATUS->{$boiler_name}{controls}};
    }

    # TODO this should really be done in the config checking Khaospy::Conf.
    croak "More than one boiler is configured to use control '$control_name'\n"
            .Dumper(\@boiler_list)
            ."please fix $BOILERS_CONF_FULLPATH\n"
        if  @boiler_list > 1;

    return $boiler_list[0] if $boiler_list[0];
    return;
}

sub init_BOILER_STATUS {
    # clones the boiler_conf into BOILER_STATUS,
    # Then munges the "controls" array-ref to be a hash-ref that holds the "controls" state.

    kloginfo "init boiler status\n";
    klogdebug "Boiler-conf :", $boiler_conf ;

    $BOILER_STATUS = clone($boiler_conf);

    for my $boiler_name ( keys %$boiler_conf ){
        kloginfo "init-ing boiler conf for $boiler_name";

        my $boiler_state = $BOILER_STATUS->{$boiler_name};

        # munging controls array to be a hash
        $boiler_state->{controls}
             = { map { $_ => '' }
                @{$boiler_conf->{$boiler_name}{controls}} } ;

        $boiler_state->{controls_last_update}
             = { map { $_ => 0 }
                @{$boiler_conf->{$boiler_name}{controls}} } ;

        $boiler_state->{last_update}   = undef;
        $boiler_state->{last_time_on}  = 0; # Jan 1st 1970 WFM !!
        $boiler_state->{last_time_off} = 0;
        $boiler_state->{current_status} = undef ;
    };
    kloginfo "boiler status is ", $BOILER_STATUS;
}

sub operate_boiler {
    my ($boiler_name) = @_;

    my $boiler_state = $BOILER_STATUS->{$boiler_name};

    klogdebug "Controls for Boiler '$boiler_name' are ", $boiler_state->{controls};

    # Is at least one of the boiler's controls on ? :
    my @controls_now_on = grep { is_on_state($boiler_state->{controls}{$_}) }
        keys %{$boiler_state->{controls}};

    if ( @controls_now_on ){
        kloginfo "Controls ON are : ".join( ", ", @controls_now_on)." ";
        if ( is_off_state($boiler_state->{current_status})) {
            if ( ! exists $boiler_state->{boiler_next_on_at} ) {
                $boiler_state->{boiler_next_on_at}
                    = $boiler_state->{on_delay_secs} + time ;
            }
            kloginfo "Boiler '$boiler_name' is scheduled to go on at "
                .timestamp($boiler_state->{boiler_next_on_at});
        } else {
            kloginfo "Boiler '$boiler_name' is already on";
        }
        return;
    }

    kloginfo "TURN BOILER '$boiler_name' OFF";

    queue_command ( $boiler_name, OFF );
    $boiler_state->{current_status} = OFF ;
    delete $boiler_state->{boiler_next_on_at};
    $boiler_state->{last_time_off} = time;
}

sub check_boiler_next_on_at {
    klogdebug "check_boiler_next_on_at()";
    for my $boiler_name ( keys %$BOILER_STATUS ){
        my $boiler_state = $BOILER_STATUS->{$boiler_name};

        if ( $boiler_state->{boiler_next_on_at}
            && $boiler_state->{boiler_next_on_at} < time
        ){
            kloginfo "TURN BOILER '$boiler_name' ON ( scheduled "
                .timestamp($boiler_state->{boiler_next_on_at}).")";

            queue_command( $boiler_name, ON );
            $boiler_state->{current_status} = ON;
            delete $boiler_state->{boiler_next_on_at};
            $boiler_state->{last_time_on} = time;
        }
    }
}

1;
