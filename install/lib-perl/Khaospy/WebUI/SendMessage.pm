package Khaospy::WebUI::SendMessage;
# TODO should be called WebUI::Action.

use strict; use warnings;

use Exporter qw/import/;
use Try::Tiny;
use Time::HiRes qw/usleep time/;
use Data::Dumper;
use DateTime;
use Khaospy::Utils qw(
    trim
    get_hashval
    get_iso8601_utc_from_epoch
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

    WEBUI

    true false
     INC_VALUE_ONE  DEC_VALUE_ONE
    $INC_VALUE_ONE $DEC_VALUE_ONE
);

use Khaospy::DBH::Controls qw(
    control_status_insert
    get_controls

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

#my $zmq_publisher;
#
#sub _get_pub {
#
#    if ( $zmq_publisher ) {
#        zmq_close( $zmq_publisher );
#    };
#    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
#    my $pub_to_port = "tcp://*:$WEBUI_SEND_PORT";
#    zmq_bind( $zmq_publisher, $pub_to_port );
#}

sub webui_send_message { # TODO should be called webui_action
    my ( $control_name, $action_value ) = @_;

    # TODO validate the value against the control config.
    my $control = get_control_config($control_name);
    my $control_type = get_hashval($control,'type') ;

    if ( exists $WEBUI_ALL_CONTROL_TYPES->{$control_type} ){

#        _get_pub();
#        my $send_msg = {
#            control_name => $control_name,
#            request_epoch_time => time,
#            current_value => $action_value,
#        };
#
#        my $json_msg = $JSON->encode($send_msg);
#        for ( 1..10 ){
#            zmq_sendmsg( $zmq_publisher, "$json_msg" );
#        }

        if (   $action_value eq INC_VALUE_ONE
            or $action_value eq DEC_VALUE_ONE ){
            # TODO Need to check it is a value type of WEBUI_VAR_***

            my $control_record = get_controls({control_name => $control_name});

            # TODO could do with error checking that we've got a control_record.
            my $current_value  = $control_record->[0]{current_value};

            $current_value += 1 if $action_value eq INC_VALUE_ONE ;
            $current_value -= 1 if $action_value eq DEC_VALUE_ONE ;

            $current_value = $control->{upper_limit}
                if defined $control->{upper_limit}
                    and $current_value > $control->{upper_limit};

            $current_value = $control->{lower_limit}
                if defined $control->{lower_limit}
                    and $current_value < $control->{lower_limit};

            $action_value = $current_value;
        }

        # TODO check the data-type of action_value , against
        # the control specification ?

        control_status_insert({
            control_name  => $control_name,
            current_value => $action_value,
            last_change_state_time =>
                get_iso8601_utc_from_epoch(time),
            last_change_state_by => WEBUI,
            request_time =>
                get_iso8601_utc_from_epoch(time),
        });
    } else {
        return { msg => queue_command($control_name, $action_value) };
    }
}

1;
