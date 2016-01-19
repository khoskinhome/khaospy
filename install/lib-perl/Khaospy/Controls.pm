package Khaospy::Controls;
use strict;
use warnings;

# used for sending a signal to a control.

# NOT TO BE USED in Khaospy::PiControllerDaemon
use Sys::Hostname;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use JSON;

use Time::HiRes qw/usleep time/;

use ZMQ::LibZMQ3;
#    ZMQ_SUB
#    ZMQ_SUBSCRIBE
#    ZMQ_RCVMORE
#    ZMQ_FD

use ZMQ::Constants qw(
    ZMQ_REQ
);

my $json = JSON->new->allow_nonref;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use zhelpers;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $KHAOSPY_CONTROLS_CONF_FULLPATH
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF

    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT

);

use Khaospy::Conf qw(
    get_controls_conf
);

use Khaospy::OrviboS20  qw//;

our @EXPORT_OK = qw(
    signal_control
);

# TODO the hard coded control types that come from the control config
# should be in a control-types json config, or sumin' like that.
my $control_types = {
    'orvibos20'                => \&_orvibo_command,
    'pi-gpio-relay-manual'     => \&_picontroller_command,
    'pi-gpio-relay'            => \&_picontroller_command,
    'pi-gpio-switch'           => \&_picontroller_command,
    'pi-mcp23017-relay-manual' => \&_picontroller_command,
    'pi-mcp23017-relay'        => \&_picontroller_command,
    'pi-mcp23017-switch'       => \&_picontroller_command,
};

## ./install/lib-perl/Khaospy/PiControllerDaemon.pm:90:

my $zmq_context   = $ZMQ_CONTEXT;
my $zmq_req_sock = zmq_socket($zmq_context,ZMQ_REQ);
my $pub_to_port = "tcp://*:$PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT";
print "zmq PUSH bound $pub_to_port \n";
zmq_bind( $zmq_req_sock, $pub_to_port );


our $verbose = false;

my $controls = get_controls_conf;

sub signal_control {
    # sends an "action" to a "named" control.

    my ($control_name, $action) = @_;

    if ( $action ne ON && $action ne OFF && $action ne STATUS ){
        croak "ERROR. The action '-a $action' can only be 'on', 'off' or 'status'\n";
    }

    if ( ! exists $controls->{$control_name} ){
        croak "ERROR in config. Control '$control_name' "
            ."doesn't exist in $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
            ."(this could be a misconfig in $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF )\n";

        # TODO the heating daemon will get deprecated along with its conf.
        # the thermometers having the knowledge of their control is silly.
        # This is the reason for the non-intuitive error message above about a misconfig
        # in the one wire heating daemon conf.
        # i.e. their is a non-existent control in the heating daemon conf.
        # The heating daemon will be replaced by a rules based system where by if something = something then do something. Then thermometers will not need to know what control they're associated with.
    }

    my $control = $controls->{$control_name};

    if ( ! exists $control->{type} ){
        croak "ERROR in config. Control '$control_name' doesn't have a 'type' key\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    my $type = lc($control->{type});

    if ( ! exists $control_types->{$type} ){
        croak "ERROR in config. Control '$control_name' has an invalid 'type' of $type\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    if ( ! exists $control->{host} ){
        croak "ERROR in config. Control '$control_name' doesn't have a 'host' configured\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    return $control_types->{$type}($control, $control_name, $action);
}

sub _orvibo_command {
    my ( $control, $control_name, $action ) = @_;

    print "Khaospy::Controls run orviboS20 command '$control_name $action'\n" if $verbose;

    if ( ! exists $control->{mac} ){
        croak "ERROR in config. Control '$control_name' doesn't have a 'mac' configured\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    return Khaospy::OrviboS20::signal_control(
        $control->{host} , $control->{mac}, $action
    );
}

sub _picontroller_command {
    my ( $control, $control_name, $action ) = @_;

    print "Khaospy::Controls PRETEND RUN PICONTROLLER COMMAND $control_name $action\n";
    print "picontroller_command not yet implemented\n";

    # set up the listener to  :
    # $PI_CONTROLLER_DAEMON_SEND_PORT
    my $host = $control->{host};

    my $msg = $json->encode({
          epoch_time    => time,
          control       => $control_name,
          control_host  => $host,
          action        => $action,
          request_host  => hostname,
    });

    # TODO a timeout on the following send, say 5 seconds :
    # and log an error message.
    zhelpers::s_send( $zmq_req_sock, "$msg" );

    return "the status of the command returned ???? TODO";

}

1;
