package Khaospy::WebUI::Rooms;
use strict; use warnings;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

use Khaospy::WebUI::SendMessage qw/ webui_send_message /;

use Khaospy::DBH::Controls qw(
    get_controls_in_room_for_user
    get_controls_from_db

    user_can_operate_control
);

use Khaospy::DBH::Rooms qw(
    get_rooms_user_can_view
);

use Khaospy::WebUI::Constants qw(
    $DANCER_BASE_URL
);

use Khaospy::Constants qw(
    true false
     INC_VALUE_ONE  DEC_VALUE_ONE
    $INC_VALUE_ONE $DEC_VALUE_ONE


);

use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

get '/rooms'  => needs login => sub {

    my $user_id = session('user_id') ;
    my $list_rooms = get_rooms_user_can_view($user_id);

    my $room_id = params->{room_id};
    $room_id = $list_rooms->[0]{id} if ! $room_id && scalar @$list_rooms;

    return template 'rooms.tt', {
        page_title      => 'Rooms',
        user            => session('user'),
        list_rooms      => $list_rooms,
        select_room_id  => $room_id,
        entries         => get_controls_in_room_for_user($user_id, $room_id),
        error_msg       => pop_error_msg(),
        is_admin        => session('user_is_admin'),
    };
};

post '/api/v1/operate/:control/:action'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    # TODO check permissions that the user can operate the control
    # via users -> rooms -> controls.
    # admin users can operate everything, even if they don't have explicit permissions.

    my $user_id = session('user_id') ;
    my $control_name = params->{control};

    if ( ! user_can_operate_control({
            control_name => $control_name,
            user_id      => $user_id,
       })
    ){
        status 'forbidden'; # 403
        return "permission denied";
    }

    my $action = params->{action};

    my $ret = {};

    try {
        # TODO this needs to have a timeout :
        $ret = { msg => webui_send_message($control_name,$action) };
    } catch {
        warn "ERROR in /api/v1/operate/:control/:action $_";
        status 'bad_request';
        $ret = "Couldn't operate $control_name with action '$action'";
    };

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

get '/api/v1/status/:control' => needs login => sub {
    my $stat = get_controls_from_db(params->{control});

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! scalar @$stat ){
        status 'not_found';
        return "Control doesn't exist";
    }

    if ( scalar @$stat > 1 ){
        status 'bad_request';
        return "More than one control";
    }

    return to_json $stat->[0];
};

get '/api/v1/statusall' => needs login => sub {
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    # TODO needs to just get the controls for the room.

    my $stat = get_controls_from_db();
    return to_json $stat;
};

#get '/status'  => needs login => sub {
#    return template 'status.tt', {
#        page_title      => 'Status',
#        user            => session('user'),
##        DANCER_BASE_URL => $DANCER_BASE_URL,
#        entries         => get_controls_from_db(),
#        error_msg       => pop_error_msg(),
#    };
#};

get '/cctv'  => needs login => sub {
    return template 'cctv.tt', {
        page_title      => 'CCTV',
        user            => session('user'),
#        DANCER_BASE_URL => $DANCER_BASE_URL,
        error_msg       => pop_error_msg(),
    };
};

##TODO remove this path
#get '/hacktest'  => needs login => sub {
#    return template 'permission_denied.tt' => {
#        page_title      => 'Admin',
#        user            => session('user'),
#    } if ! session->read('user_is_admin');
#
#    webui_send_message ('var-karl-room-temp',20) ."\n\n  ".time;
#    webui_send_message ('var-alison-room-temp',20) ."\n\n  ".time;
#    webui_send_message ('var-amelia-room-temp',20) ."\n\n  ".time;
#    webui_send_message ('var-front-room-temp',20) ."\n\n  ".time;
#    return "sent hack text message " . webui_send_message ('var-dining-room-temp',20) ."\n\n  ".time;
#};

1;
