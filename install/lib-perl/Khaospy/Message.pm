package Khaospy::Message;
use strict;
use warnings;


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
);

our @EXPORT_OK = qw(
    validate_control_msg_json
    validate_control_msg_fields
);
    # _validate_action
    # _get_control_message_key

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
    my $action             = $msg_rh->{action};
    my $request_host       = $msg_rh->{request_host};

#    try {
#        my $control = get_control_config($control_name);
#    } catch {
#
#
#    }

    if ( ! $request_epoch_time ){
        confess "ERROR message has invalid request_epoch_time";
    }

    if ( $request_epoch_time < time - $MESSAGES_OVER_SECS_INVALID ){
        confess "ERROR message is over $MESSAGES_OVER_SECS_INVALID seconds old";
    }

    _validate_action($action);

    # TODO check :
    #   request_host is a valid host in the config.

    return _get_control_message_key($msg_rh);
}

sub _get_control_message_key {
    # "signature" could be a better term rather than "key" . hmmm.
    # Calcs the key for use in queues etc..
    my ($msg_rh) = @_ ;

    my $request_epoch_time = $msg_rh->{request_epoch_time};
    my $control_name       = $msg_rh->{control_name};
    my $action             = $msg_rh->{action};
    my $request_host       = $msg_rh->{request_host} || "";

    # TODO. Sometimes there isn't an "action", its just an update with
    # a current_value. So when action is not available then
    # maybe current_value should be used for the signature-key.

    return "$control_name|$action|$request_host|$request_epoch_time";
}

sub _validate_action {
    my ($action) = @_;

    confess "The action is not defined" if ! defined $action;

    # $action can be :
    #  ON or OFF
    #  a numeric value
    #  an array-ref or hash-ref of :
    #       ON or OFF strings
    #       numeric values
    #  Also an array or hash ref all have to be of the same type.
    #  That is they either have to all be ( ON, OFF or STATUS)
    #   OR they can all be numerics.

    # this sub serialises the arrays so that they can be used in _get_control_message_key()
    # it is not designed for deserialisation. ( due to making sorted hashkeys turn into an array )

    my $valid = sub {
        my ( $act ) = @_;

        return ON.OFF.STATUS if ( $act eq ON || $act eq OFF || $act eq STATUS);

        return "NUMBER" if ( looks_like_number($act) ) ;

        my $errmsg ="ERROR. The action '$act' can only be 'on', 'off', 'status' or a valid numeric\n";
        $errmsg .= "In the structure :\n".Dumper($action)
            if (ref $action eq 'ARRAY' or ref $action eq 'HASH' );
        confess $errmsg;
    };

    my $check_types_same = sub {
        my ($ar) = @_;
        confess "ERROR. The action has different types ( numerics mixed with ON, OFF,STATUS )\n"
            ."In the structure :\n".Dumper($action)
               if ! all {$ar->[0] eq $_} @$ar;
    };

    if ( ref $action eq 'HASH' ){
        confess "The action 'hash' is empty"
            if ! scalar keys %$action;

        $check_types_same->([ map { $valid->($action->{$_}) } keys %$action ]);
        return $JSON->encode([
            map {$_ => $action->{$_}} sort keys %$action
        ]);
    }

    if ( ref $action eq 'ARRAY' ){
        confess "The action 'array' is empty"
            if ! scalar @$action;

        $check_types_same->([ map { $valid->($_) } @$action ]);
        return $JSON->encode($action);
    }

    $valid->($action);
    return $action;
}

1;
