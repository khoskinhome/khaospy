package Khaospy::WebUI::SendMessage;
use strict; use warnings;

use Exporter qw/import/;
use Try::Tiny;
use Time::HiRes qw/usleep time/;
use Data::Dumper;
use DateTime;
use Khaospy::Utils qw(
    trim
    get_hashval
);

use Khaospy::Constants qw(
    true false
);

use Khaospy::QueueCommand qw/ queue_command /;

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    $WEBUI_SEND_PORT

    $WEBUI_ALL_CONTROL_TYPES
);

use Khaospy::Conf::Controls qw(
    get_control_config
);

use ZMQ::LibZMQ3;
use ZMQ::Constants qw( ZMQ_PUB );

use zhelpers;

our @EXPORT_OK = qw(
    webui_send_message
);

my $zmq_publisher;

sub _get_pub {

    if ( $zmq_publisher ) {
        zmq_close( $zmq_publisher );
    };
    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$WEBUI_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );
}

sub webui_send_message {
    my ( $control_name, $action_value ) = @_;

    # TODO validate the value against the control config.
    my $control = get_control_config($control_name);
    my $control_type = get_hashval($control,'type') ;

    if ( exists $WEBUI_ALL_CONTROL_TYPES->{$control_type} ){

        _get_pub();
        my $send_msg = {
            control_name => $control_name,
            request_epoch_time => time,
            current_value => $action_value,
        };

        my $json_msg = $JSON->encode($send_msg);
        for ( 1..10 ){
            zmq_sendmsg( $zmq_publisher, "$json_msg" );
        }
    } else {
        return { msg => queue_command($control_name, $action_value) };
    }
}


1;
