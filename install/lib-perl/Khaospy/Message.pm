package Khaospy::Message;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin 2015-2017

use Try::Tiny;
use Carp qw/confess/;
use Data::Dumper;
use Exporter qw/import/;
use Scalar::Util qw(looks_like_number);
use List::Util qw(all);

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    $MESSAGES_OVER_SECS_INVALID
);

use Khaospy::Conf::Controls qw(
    get_control_config
    validate_control_state_action
);

our @EXPORT_OK = qw(
    validate_control_msg_json
    validate_control_msg_fields
);

sub validate_control_msg_json {
    my ($msg) = @_;
    # Returns the "mkey" ( message-key ) , perl-hashref and original json .

    my $msg_rh;
    eval{$msg_rh = $JSON->decode( $msg );};
    if ($@) {
        confess "JSON decode of message failed. $@";
    }

    my $msg_key;
    eval{$msg_key = validate_control_msg_fields($msg_rh)};
    if ($@){
        confess "Problem with message format. $@";
    }

    return {
        mkey => $msg_key,
        hashref => $msg_rh,
        json => $msg,
    };
}

sub validate_control_msg_fields {
    # and return the "message-key" ( for queues etc and id-ing )

    my ( $msg_rh ) = @_;

    my $request_epoch_time = $msg_rh->{request_epoch_time};
    my $control_name       = $msg_rh->{control_name};
    my $control_host       = $msg_rh->{control_host};
    my $action             = $msg_rh->{action} || $msg_rh->{current_state};
    my $request_host       = $msg_rh->{request_host};

    if ( ! $request_epoch_time ){
        confess "ERROR message has invalid request_epoch_time";
    }

    if ( $request_epoch_time < time - $MESSAGES_OVER_SECS_INVALID ){
        confess "ERROR message is over $MESSAGES_OVER_SECS_INVALID seconds old";
    }

    validate_control_state_action($control_name, $action);

    # TODO check :
    #   maybe request_host is a valid host in the pi-host config.

    return _get_control_message_key($msg_rh);
}

sub _get_control_message_key {
    # Calcs the key for use in queues etc..
    my ($msg_rh) = @_ ;

    my $request_epoch_time = $msg_rh->{request_epoch_time};
    my $control_name       = $msg_rh->{control_name};
    my $action             = $msg_rh->{action} || $msg_rh->{current_state};
    my $request_host       = $msg_rh->{request_host} || "";

    return "$control_name|$action|$request_host|$request_epoch_time";
}

1;
