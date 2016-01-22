package Khaospy::PiControllerDaemon;
use strict;
use warnings;

=pod

A daemon that runs commands on a PiController and :

    subscribes to all hosts tcp://all-hosts:5061 for commands.
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT = 5061

    publishes to tcp://*:5062 what the command did.
    $PI_CONTROLLER_DAEMON_SEND_PORT = 5062

=cut

use Time::HiRes qw/usleep time/;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use Sys::Hostname;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_PUB
    ZMQ_SUB
);

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;
use zhelpers;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON
    true false
    ON OFF STATUS
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT
);

use Khaospy::Conf qw(
    get_pi_controller_conf
    get_control_config
    validate_control_msg_fields
);

use Khaospy::Utils qw( timestamp );
use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

our @EXPORT_OK = qw( run_controller_daemon );

our $PUBLISH_STATUS_EVERY_SECS = 5;

my $zmq_publisher;
my $pi_controller_conf;

#######
# subs

sub run_controller_daemon {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;

    klogstart "Controller Daemon START";

    $pi_controller_conf = get_pi_controller_conf();
    kloginfo "Dumper of pi controller conf", $pi_controller_conf;

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$PI_CONTROLLER_DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );

    my @w;

    for my $sub_host ( @{$pi_controller_conf->{pull_from_hosts}} ){
         # ^^^ pull_from_host BAD NAME!
        push @w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT,
            msg_handler       => \&controller_message,
            klog              => true,
        });
    }

    push @w, AnyEvent->timer(
        after    => 0.1,
        interval => $PUBLISH_STATUS_EVERY_SECS,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;

}

sub timer_cb {
    klogdebug "in timer ";
}

sub controller_message {
    my ($zmq_sock, $msg, $param ) = @_;

    #zmq_sendmsg ( $zmq_publisher, "the status of whatever the control did" );

    my $msg_decoded;
    eval{$msg_decoded = $JSON->decode( $msg );};

    if ($@) {
        klogerror "ERROR. JSON decode of message failed. $@";
        return;
    }

    my $request_epoch_time = $msg_decoded->{request_epoch_time};
    my $control_name       = $msg_decoded->{control_name};
    my $control_host       = $msg_decoded->{control_host};
    my $action             = $msg_decoded->{action};
    my $request_host       = $msg_decoded->{request_host};

    kloginfo  "Message received. '$control_name' '$action'";
    klogdebug "Message Dump", ($msg_decoded);

    my $control = get_control_config($control_name);

    if ( $control->{host} ne hostname ) {
        kloginfo "control $control_name is not controlled by this host";
        return;
    }

    my $status ;

    if ( $control->{type} eq 'pi-gpio-relay'){
        $status = operate_pi_gpio_relay($control_name,$control, $action);
    } else {

        klogerror "Control $control_name with type $control->{type} could be invalid. Or maybe it hasn't been programmed yet. Some are still TODO\n";
        return;
    }

    my $msg = {
      request_epoch_time => $request_epoch_time,
      control_name       => $control_name,
      control_host       => $control_host,
      action             => $action,
      request_host       => $request_host,
      action_epoch_time  => time,
      status             => $status,
    };

    validate_control_msg_fields($msg);

    my $json_msg = $JSON->encode($msg);

    zhelpers::s_send( $zmq_publisher, "$json_msg" );

}

sub operate_pi_gpio_relay {
    my ($control_name,$control, $action) = @_;

    # TODO this should go into Khaospy::PiGPIO module.

    kloginfo "OPERATE $control_name with $action";

    # this error checking should be in the Khaospy::Conf error checking.
    if (! exists $control->{gpio_wiringpi} ){
        klogerror "Control $control_name, type $control->{type}, doesn't have a key 'gpio_wiringpi'\n";
        return;
    }

    my $gpio_wiringpi = $control->{gpio_wiringpi};

    ##pi@pitest ~ $ gpio mode 1 out
    ##pi@pitest ~ $ gpio mode 4 out
    ##pi@pitest ~ $ gpio write 1 0
    ##pi@pitest ~ $ gpio write 1 1
    ##pi@pitest ~ $ gpio write 4 1
    #
    my $cmd_gpio = "/usr/bin/gpio";
    kloginfo `$cmd_gpio mode $gpio_wiringpi out`;


    if ($action eq STATUS){
        kloginfo "$control_name status is ".qx("$cmd_gpio read $gpio_wiringpi");
        # need to return the PROPER status
        return ON; # HACK FIX THIS
    }

    my $send_number = $action;

    if ($action eq ON){
        $send_number = true
    } elsif ($action eq OFF){
        $send_number = false
    }

    # should use proper "complement" here ... its late...
    # TODO need to use the invert_state on both the send_number and what "read" returns.

    if ( exists $control->{invert_state} && $control->{invert_state} ){
        if ( $send_number ) { $send_number = false }
        else { $send_number = true }
    }

    system("$cmd_gpio write $gpio_wiringpi $send_number");
    # TODO this needs to be published.
    kloginfo "$control_name status is ".qx("$cmd_gpio read $gpio_wiringpi");

    # need to return the PROPER status
    return OFF; # hack fix this

}

#sub operate_boiler {
#    my ($boiler_name, $control, $action) = @_;
#
#    print timestamp."Operate boiler '$boiler_name'. set control '$control' to '$action'\n";
#
#    my $boiler_state = $BOILER_STATUS->{$boiler_name};
#
#    # update the boiler's controls with the latest control-action.
#    $boiler_state->{controls}{$control}=$action;
#
#    print "Controls are \n".Dumper($boiler_state->{controls}) if $VERBOSE;
#
#    # Is at least one of the boiler's controls on ? :
#    my @controls_now_on = grep { $boiler_state->{controls}{$_} eq ON }
#        keys %{$boiler_state->{controls}};
#
#    print timestamp."Boiler '$boiler_name' currently has the controls 'on' :".Dumper( \@controls_now_on );
#
#    if ( @controls_now_on ){
#        if ( $boiler_state->{current_status} eq OFF
#        ){
#            if ( ! exists $boiler_state->{boiler_next_on_at} ) {
#                $boiler_state->{boiler_next_on_at}
#                    = $boiler_state->{on_delay_secs} + time ;
#            }
#            print timestamp."Boiler '$boiler_name' is scheduled to go on at "
#                .timestamp($boiler_state->{boiler_next_on_at})."\n";
#        } else {
#            print timestamp."Boiler '$boiler_name' is already on\n";
#        }
#
#        return;
#    }
#
#    print timestamp."TURN BOILER '$boiler_name' OFF\n";
#
#    _sig_a_control ( $boiler_name, OFF, \$boiler_state->{current_status} );
#    print timestamp."Boiler '$boiler_name' is now ".$boiler_state->{current_status}."\n";
#
#    delete $boiler_state->{boiler_next_on_at};
#
#    if ( $boiler_state->{current_status} eq OFF ) {
#        $boiler_state->{last_time_off} = time;
#    } else {
#        print timestamp."ERROR. Boiler '$boiler_name' is not OFF\n";
#    }
#}
#
#sub boiler_check_next_on_at {
#    # checks all boilers and see if there is a "boiler_next_on_at" set that is now valid.
#    print "boiler_check_next_on_at ..\n" if $VERBOSE;
#    for my $boiler_name ( keys %$BOILER_STATUS ){
#        my $boiler_state =  $BOILER_STATUS->{$boiler_name};
#
#        if ( $boiler_state->{boiler_next_on_at}
#            && $boiler_state->{boiler_next_on_at} < time
#        ){
#            print timestamp."TURN BOILER '$boiler_name' ON ( scheduled "
#                .timestamp($boiler_state->{boiler_next_on_at}).")\n";
#
#            _sig_a_control ( $boiler_name, ON, \$boiler_state->{current_status} );
#            print timestamp."Boiler '$boiler_name' is now ".$boiler_state->{current_status}."\n";
#
#            if ( $boiler_state->{current_status} eq ON ) {
#
#                delete $boiler_state->{boiler_next_on_at};
#                $boiler_state->{last_time_on} = time;
#
#            } else {
#                print timestamp."ERROR. Boiler '$boiler_name' is not ON\n";
#            }
#        }
#    }
#}
#
#sub get_boiler_name_for_control {
#    # goes through the $BOILER_STATUS and looks for a control.
#    # returns either the boiler_name or undef.
#
#    # will croak if 2 or more boilers have the same sub-control.
#
#    my ($control) = @_;
#
#    my @boiler_list;
#    for my $boiler_name ( keys %$BOILER_STATUS ) {
#        push @boiler_list, map { $boiler_name }
#                grep { $control eq $_ }
#                keys %{$BOILER_STATUS->{$boiler_name}{controls}}
#        ;
#    }
#
#    croak "More than one boiler is configured to use control '$control'\n"
#            .Dumper(\@boiler_list)
#            ."please fix $KHAOSPY_BOILERS_CONF_FULLPATH\n"
#        if  @boiler_list > 1;
#
#    return $boiler_list[0] if $boiler_list[0];
#    return;
#}
#
#sub init_BOILER_STATUS {
#    # clones the boiler_conf into BOILER_STATUS,
#    # Then munges the "controls" array-ref to be a hash-ref that holds the "controls" state.
#
#    print "init boiler status\n" if $VERBOSE;
#
#    my $boiler_conf = get_boiler_conf();
#
#    print "Boiler-conf :\n".Dumper ( $boiler_conf ) if $VERBOSE ;
#
#    $BOILER_STATUS = clone($boiler_conf);
#
#    for my $boiler_name ( keys %$boiler_conf ){
#        my $boiler_state =  $BOILER_STATUS->{$boiler_name};
#
#        # munging controls array to be a hash
#        $boiler_state->{controls}
#             = { map { $_ => undef }
#                @{$boiler_conf->{$boiler_name}{controls}} } ;
#
#        $boiler_state->{last_time_on}  = 0; # Jan 1st 1970 WFM !!
#        $boiler_state->{last_time_off} = 0;
#
#        _sig_a_control ( $boiler_name, STATUS ,\$boiler_state->{current_status} );
#
#        $boiler_state->{last_time_on}    = time
#            if ( $boiler_state->{current_status} eq ON );
#
#        $boiler_state->{last_time_off}   = time
#            if ( $boiler_state->{current_status} eq OFF );
#    };
#
#    refresh_boiler_status();
#}
#
#sub refresh_boiler_status {
#    # refresh the controls from directly signalling the control
#
#    print timestamp."Refresh BOILER_STATUS\n";
#
#    for my $boiler_name ( keys %$BOILER_STATUS){
#
#        my $boiler_state =  $BOILER_STATUS->{$boiler_name};
#
#        _sig_a_control ( $boiler_name, STATUS ,\$boiler_state->{current_status} );
#
#        for my $control ( keys %{$boiler_state->{controls}} ) {
#            _sig_a_control ( $control, STATUS, \$boiler_state->{controls}{$control} );
#        }
#    };
#
#    print "boiler-status = ".Dumper($BOILER_STATUS) if $VERBOSE;
#
#    $BOILER_STATUS_LAST_REFRESH = time;
#}
#
#sub _sig_a_control {
#    my ( $control, $action, $update_scalar_ref ) = @_;
#
#    my $ret;
#    eval { $ret = signal_control( $control, $action ); };
#
#    if ( $@ ) {
#        print timestamp."Error signalling control '$control' with '$action'. $@\n";
#        ${$update_scalar_ref} = undef ; # should this be OFF ?
#    } else {
#        ${$update_scalar_ref} = $ret;
#    }
#}


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
