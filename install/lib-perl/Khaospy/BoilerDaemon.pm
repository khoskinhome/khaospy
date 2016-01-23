package Khaospy::BoilerDaemon;
use warnings;

use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVMORE ZMQ_FD);
use Clone 'clone';
use JSON;
use POSIX qw(strftime);

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $HEATING_CONTROL_DAEMON_PUBLISH_PORT
    $KHAOSPY_BOILERS_CONF_FULLPATH
);

use Khaospy::OperateControls qw( signal_control );

use Khaospy::Conf qw( get_boiler_conf );

use Khaospy::Utils qw( timestamp );

our @EXPORT_OK = qw( run_boiler_daemon );

my $JSON = JSON->new->allow_nonref;

our $VERBOSE;

our $BOILER_STATUS;

our $BOILER_STATUS_LAST_REFRESH;
our $BOILER_STATUS_REFRESH_EVERY_SECS = 15; # TODO put back to 60.

#######
# subs

sub run_boiler_daemon {

    my ( $opts ) = @_;

    $opts = {} if ! $opts;

    $VERBOSE = $opts->{verbose} || false;

    print "#############\n";
    print timestamp."Boiler Daemon START\n";
    print timestamp."VERBOSE = ".( $VERBOSE ? "TRUE" : "FALSE" )."\n";

    init_BOILER_STATUS();

    my $quit_program = AnyEvent->condvar;

    my $subscriber = zmq_socket($ZMQ_CONTEXT, ZMQ_SUB);

    # TODO this needs to be worked out from looking at the daemon-runner conf.
    # working out the host that the heating-control is running on.
    # currently this hard coding means the boiler-daemon has to run on the same host as the heating-control-daemon.
    my $HEATING_CONTROL_HOST = 'localhost';

    my $connect_str = "tcp://$HEATING_CONTROL_HOST:$HEATING_CONTROL_DAEMON_PUBLISH_PORT";

    if ( my $zmq_state = zmq_connect($subscriber, $connect_str )){
        croak "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
    };

    # '' is because I can't work out how to get the "topic" filter sent by Khaospy::Boiler.
    zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, '' );

    my $fh = zmq_getsockopt( $subscriber, ZMQ_FD );

    my $w = anyevent_io( $fh, $subscriber );

    $quit_program->recv;

}

sub anyevent_io {
    my ( $fh, $subscriber ) = @_;
    return AnyEvent->io(
        fh   => $fh,
        poll => "r",
        cb   => sub {
            while ( my $recvmsg = zmq_recvmsg( $subscriber, ZMQ_RCVMORE ) ) {
                process_boiler_message ( zmq_msg_data($recvmsg) );
            }
        },
    );
}

sub process_boiler_message {
    my ($msg) = @_ ;

    #my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;
    # ^^^ can't get $topic working in perl yet. TODO

    my $msg_decoded = $JSON->decode( $msg );

    my $epoch_time
        = $msg_decoded->{EpochTime};
    my $control
        = $msg_decoded->{Control};
    my $home_auto_class
        = $msg_decoded->{HomeAutoClass}; # Why do I need HomeAutoClass ? TODO probably deprecate this.
    my $action
        = $msg_decoded->{Action};

    print "\n".timestamp."Message received. '$control' '$action' \n";
    print Dumper($msg_decoded)."\n" if $VERBOSE;

    refresh_boiler_status()
        if $BOILER_STATUS_LAST_REFRESH + $BOILER_STATUS_REFRESH_EVERY_SECS < time ;

    my $boiler_name = get_boiler_name_for_control($control);

    boiler_check_next_on_at();

    return if ! $boiler_name;

    operate_boiler($boiler_name, $control, $action);

}

sub operate_boiler {
    my ($boiler_name, $control, $action) = @_;

    print timestamp."Operate boiler '$boiler_name'. set control '$control' to '$action'\n";

    my $boiler_state = $BOILER_STATUS->{$boiler_name};

    # update the boiler's controls with the latest control-action.
    $boiler_state->{controls}{$control}=$action;

    print "Controls are \n".Dumper($boiler_state->{controls}) if $VERBOSE;

    # Is at least one of the boiler's controls on ? :
    my @controls_now_on = grep { $boiler_state->{controls}{$_} eq ON }
        keys %{$boiler_state->{controls}};

    print timestamp."Boiler '$boiler_name' currently has the controls 'on' :".Dumper( \@controls_now_on );

    if ( @controls_now_on ){
        if ( $boiler_state->{current_status} eq OFF
        ){
            if ( ! exists $boiler_state->{boiler_next_on_at} ) {
                $boiler_state->{boiler_next_on_at}
                    = $boiler_state->{on_delay_secs} + time ;
            }
            print timestamp."Boiler '$boiler_name' is scheduled to go on at "
                .timestamp($boiler_state->{boiler_next_on_at})."\n";
        } else {
            print timestamp."Boiler '$boiler_name' is already on\n";
        }

        return;
    }

    print timestamp."TURN BOILER '$boiler_name' OFF\n";

    _sig_a_control ( $boiler_name, OFF, \$boiler_state->{current_status} );
    print timestamp."Boiler '$boiler_name' is now ".$boiler_state->{current_status}."\n";

    delete $boiler_state->{boiler_next_on_at};

    if ( $boiler_state->{current_status} eq OFF ) {
        $boiler_state->{last_time_off} = time;
    } else {
        print timestamp."ERROR. Boiler '$boiler_name' is not OFF\n";
    }
}

sub boiler_check_next_on_at {
    # checks all boilers and see if there is a "boiler_next_on_at" set that is now valid.
    print "boiler_check_next_on_at ..\n" if $VERBOSE;
    for my $boiler_name ( keys %$BOILER_STATUS ){
        my $boiler_state =  $BOILER_STATUS->{$boiler_name};

        if ( $boiler_state->{boiler_next_on_at}
            && $boiler_state->{boiler_next_on_at} < time
        ){
            print timestamp."TURN BOILER '$boiler_name' ON ( scheduled "
                .timestamp($boiler_state->{boiler_next_on_at}).")\n";

            _sig_a_control ( $boiler_name, ON, \$boiler_state->{current_status} );
            print timestamp."Boiler '$boiler_name' is now ".$boiler_state->{current_status}."\n";

            if ( $boiler_state->{current_status} eq ON ) {

                delete $boiler_state->{boiler_next_on_at};
                $boiler_state->{last_time_on} = time;

            } else {
                print timestamp."ERROR. Boiler '$boiler_name' is not ON\n";
            }
        }
    }
}

sub get_boiler_name_for_control {
    # goes through the $BOILER_STATUS and looks for a control.
    # returns either the boiler_name or undef.

    # will croak if 2 or more boilers have the same sub-control.

    my ($control) = @_;

    my @boiler_list;
    for my $boiler_name ( keys %$BOILER_STATUS ) {
        push @boiler_list, map { $boiler_name }
                grep { $control eq $_ }
                keys %{$BOILER_STATUS->{$boiler_name}{controls}}
        ;
    }

    croak "More than one boiler is configured to use control '$control'\n"
            .Dumper(\@boiler_list)
            ."please fix $KHAOSPY_BOILERS_CONF_FULLPATH\n"
        if  @boiler_list > 1;

    return $boiler_list[0] if $boiler_list[0];
    return;
}

sub init_BOILER_STATUS {
    # clones the boiler_conf into BOILER_STATUS,
    # Then munges the "controls" array-ref to be a hash-ref that holds the "controls" state.

    print "init boiler status\n" if $VERBOSE;

    my $boiler_conf = get_boiler_conf();

    print "Boiler-conf :\n".Dumper ( $boiler_conf ) if $VERBOSE ;

    $BOILER_STATUS = clone($boiler_conf);

    for my $boiler_name ( keys %$boiler_conf ){
        my $boiler_state =  $BOILER_STATUS->{$boiler_name};

        # munging controls array to be a hash
        $boiler_state->{controls}
             = { map { $_ => undef }
                @{$boiler_conf->{$boiler_name}{controls}} } ;

        $boiler_state->{last_time_on}  = 0; # Jan 1st 1970 WFM !!
        $boiler_state->{last_time_off} = 0;

        _sig_a_control ( $boiler_name, STATUS ,\$boiler_state->{current_status} );

        $boiler_state->{last_time_on}    = time
            if ( $boiler_state->{current_status} eq ON );

        $boiler_state->{last_time_off}   = time
            if ( $boiler_state->{current_status} eq OFF );
    };

    refresh_boiler_status();
}

sub refresh_boiler_status {
    # refresh the controls from directly signalling the control

    print timestamp."Refresh BOILER_STATUS\n";

    for my $boiler_name ( keys %$BOILER_STATUS){

        my $boiler_state =  $BOILER_STATUS->{$boiler_name};

        _sig_a_control ( $boiler_name, STATUS ,\$boiler_state->{current_status} );

        for my $control ( keys %{$boiler_state->{controls}} ) {
            _sig_a_control ( $control, STATUS, \$boiler_state->{controls}{$control} );
        }
    };

    print "boiler-status = ".Dumper($BOILER_STATUS) if $VERBOSE;

    $BOILER_STATUS_LAST_REFRESH = time;
}

sub _sig_a_control {
    my ( $control, $action, $update_scalar_ref ) = @_;

    my $ret;
    eval { $ret = signal_control( $control, $action ); };

    if ( $@ ) {
        print timestamp."Error signalling control '$control' with '$action'. $@\n";
        ${$update_scalar_ref} = undef ; # should this be OFF ?
    } else {
        ${$update_scalar_ref} = $ret;
    }
}

=pod

The Boiler daemon has a conf of all the heating controls that are associated with the boilers.

$conf = {
            'boiler-central-heating' => {
                'on_delay_secs' => 120,
                'controls' => [
                    'alisonrad',
                    'karlrad',
                    'ameliarad',
                    'dinningroomrad'
                ]
            },
            'another-boiler-in-a-big-house' => {
                on_delay_secs => 120,
                'controls' => [
                    'huge-mansion-room-rad',
                ]
            }
        };


Thermometer-monitor-daemons
###########################

The the various thermometer monitor daemons publish to a zero-mq-port the current state of any thermometer that has an associated control to the boiler daemon.

The boiler-daemon listens to the zero-mq-ports of the various thermometer-monitor-daemons for json messages structured like :
    {
      EpochTime'     => '1451416995.77076',
      HomeAutoClass' => 'boilerControl',
      Control'       => 'a-control-name',
      Action         => 'on'
    };

The boiler-daemon, with its config, has the knowledge of which if any of controls published by the thermometer-monitor deamons are radiator-controls for which the boiler-daemon has to switch on the boilers it is configured to control.

The boiler-daemon ignores any messages for controls that it doesn't know about.

boiler ON or OFF.
################

When all of the rad-controls for a specific boiler are off then the boiler is immediately be switched off.

If the boiler is in the off state, and one or more of the controls switches on, then due to the radiator-actuators taking a couple of minutes to operate, the boiler-daemon will wait for on_delay_secs before it switches on.

You need to time the operation of a radiator-actuator-valve to get this time. The ones I have take about 2 minutes to fully open. You do not want the boiler pumping hot-water with all the valves off. ( Usually there is always at least one radiator that is fully open to stop the boiler pump trying to push water around a fully closed system )

If all the rads go into the off state , the boiler will be switched off immediately. ( pump-over-run might be in operation on the boiler )

Only 1 boiler-daemon will run . This is enforced by daemon-runner ( not yet implemented ).

The boiler daemon will work out the hosts of the thermometer-monitor-daemons it has to subscribe to from the daemon-runner conf. This is not yet implemented, and the boiler-daemon currently has to run on the same host as the thermometer-monitor-daemons.

=cut

#############################################################
# Zero-mq with AnyEvent code examples got from :
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html

1;
