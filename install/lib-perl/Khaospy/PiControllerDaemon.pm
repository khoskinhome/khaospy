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
    $PI_GPIO_CMD
    $ZMQ_CONTEXT
    $JSON
    true false
    ON OFF STATUS
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT
);

use Khaospy::Conf::Controls qw(
    get_control_config
);

use Khaospy::Message qw(
    validate_control_msg_fields
);

use Khaospy::Utils qw( timestamp );
use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

use Khaospy::PiHostPublishers qw(
    get_pi_controller_queue_daemon_hosts
);

our @EXPORT_OK = qw( run_controller_daemon );

our $PUBLISH_STATUS_EVERY_SECS = 5;

# TODO use this to log messages received and only action them once.
# my $msg_received = {};

my $zmq_publisher;

sub run_controller_daemon {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;

    klogstart "Controller Daemon START";

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$PI_CONTROLLER_DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );

    my @w;

    for my $sub_host ( @{get_pi_controller_queue_daemon_hosts()} ){

        push @w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT,
            msg_handler       => \&controller_message,
            klog              => true,
        });
    }

    push @w, AnyEvent->timer(
        after    => 0.1, # TODO. MAGIC NUMBER . should be in Constants.pm or a json-config. dunno. but not here.
        interval => $PUBLISH_STATUS_EVERY_SECS,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    klogdebug "in timer ";

    # TODO clean up $msg_received with messages over timeout.

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

# TODO check in msg_received has already been actioned. Is this necessary? 


    if ( $control->{type} eq 'pi-gpio-relay' ){
        $status = operate_pi_gpio_relay($control_name,$control, $action);
    } else {

        klogerror "Control $control_name with type $control->{type} could be invalid. Or maybe it hasn't been programmed yet. Some are still TODO\n";
        return;
    }

    my $return_msg = {
      request_epoch_time => $request_epoch_time,
      control_name       => $control_name,
      control_host       => $control_host,
      action             => $action,
      request_host       => $request_host,
      action_epoch_time  => time,
      status             => $status,
    };

# TODO log msg just actioned in :
#    $msg_received = {};

    validate_control_msg_fields($return_msg);

    my $json_msg = $JSON->encode($return_msg);

    zhelpers::s_send( $zmq_publisher, "$json_msg" );

}

# TODO the xxx_pi_gpio_xxx subs should go into Khaospy::PiGPIO module.
sub operate_pi_gpio_relay {
    my ($control_name,$control, $action) = @_;

    kloginfo "OPERATE $control_name with $action";

    my $gpio_num = $control->{gpio_relay};

    # Initialising port IN or OUT
    # should be done when PiControllerDaemon first starts :
    init_pi_gpio($gpio_num, "out");

    write_pi_gpio($gpio_num, trans_ON_to_true(invert_state($control,$action)))
        if $action ne STATUS;

    return
        trans_true_to_ON(
            invert_state($control,read_pi_gpio($gpio_num))
        );
}

# For the initialisation, reading and writing of Pi GPIO pins.
# I should possibly use https://github.com/WiringPi/WiringPi-Perl
# but that needs compiling etc. No CPAN module. hmmm.
# From the CLI this init, read and write are done like so :
#  /usr/bin/gpio mode  4 out
#  /usr/bin/gpio write 4 0
#  /usr/bin/gpio write 4 1
#  /usr/bin/gpio read  4

sub init_pi_gpio {
    my ($gpio_num, $IN_OUT) = @_;
    $IN_OUT = lc( $IN_OUT );
    fatal_invalid_pi_gpio($gpio_num);
    klogfatal "Can only set a Pi GPIO mode ($IN_OUT) to 'in' or 'out'"
        if $IN_OUT ne "in" and $IN_OUT ne "out";

    system("$PI_GPIO_CMD mode $gpio_num $IN_OUT");
}

sub read_pi_gpio {
    my ($gpio_num) = @_;
    fatal_invalid_pi_gpio($gpio_num);
    my $r = qx( $PI_GPIO_CMD read $gpio_num );
    chomp $r;
    return $r;
}

sub write_pi_gpio {
    my ($gpio_num, $val) = @_;
    fatal_invalid_pi_gpio($gpio_num);
    system("$PI_GPIO_CMD write $gpio_num $val");
    return;
}

sub fatal_invalid_pi_gpio {
    my ($gpio_num) = @_;
    klogfatal "gpio number can only be 0 to 7" if $gpio_num !~ /^[0-7]$/;
}

# these helper subs need to be in a Khaospy::OperateControls module,
# that is when the current Khaospy::OperateControls.pm is renamed to Khaospy::OperateControl.pm

# Stating possibly the "bleedin' obvious,
# ON eq "on" , and OFF eq "off"
# true == 1 , false == 0
# These subs translate both ways from ON to true and OFF to false.

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
    # if a control has "invert_state" option set then this
    # inverts both ON/OFF and true/false
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
