package Khaospy::Message;
use strict;
use warnings;

use Carp qw/confess/;
use Data::Dumper;
use Exporter qw/import/;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    $MESSAGES_OVER_SECS_INVALID
);

use Khaospy::Conf qw(
    get_control_config
);

our @EXPORT_OK = qw(
    validate_action
    validate_control_msg_json
    validate_control_msg_fields
    get_control_message_key
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
    my $action             = $msg_rh->{action};
    my $request_host       = $msg_rh->{request_host};

    my $control = get_control_config($control_name);

    if ( ! $request_epoch_time ){
        confess "ERROR message has invalid request_epoch_time";
    }

    if ( $request_epoch_time < time - $MESSAGES_OVER_SECS_INVALID ){
        confess "ERROR message is over $MESSAGES_OVER_SECS_INVALID seconds old";
    }

    validate_action($action);

    # TODO check :
    #   control_host is a valid host in the config.
    #   request_host is a valid host in the config.
    #   action is valid

#    if ( $control->{type} eq 'pi-gpio-relay'){
#        return operate_pi_gpio_relay($control_name,$control, $action);
#    }
#
#    if ( $control->{host} ne hostname ) {
#        print timestamp."control $control_name is not controlled by this host\n";
#        return;
#    }

    # return "mkey" ( message-key ) :
    return get_control_message_key($msg_rh);
}

sub get_control_message_key {
    # "signature" could be a better term rather than "key" . hmmm.
    # Calcs the key for use in queues etc..
    my ($msg_rh) = @_ ;

    my $request_epoch_time = $msg_rh->{request_epoch_time};
    my $control_name       = $msg_rh->{control_name};
    my $control_host       = $msg_rh->{control_host};
    my $action             = $msg_rh->{action};
    my $request_host       = $msg_rh->{request_host};

    return "$control_name|$control_host|$action|$request_host|$request_epoch_time";
}

sub validate_action {
    my ($action) = @_;
    if ($action ne ON && $action ne OFF && $action ne STATUS ){
        confess "ERROR. The action '-a $action' can only be 'on', 'off' or 'status'\n";
    }
}

1;
