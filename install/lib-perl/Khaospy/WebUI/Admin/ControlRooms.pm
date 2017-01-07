package Khaospy::WebUI::Admin::ControlRooms;
use strict; use warnings;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

use Khaospy::Email qw(send_email);
use Khaospy::Constants qw($JSON);

use Khaospy::Utils qw(
    trim
    get_hashval
);

use Khaospy::DBH::Controls qw(get_controls);
use Khaospy::DBH::Rooms qw(get_rooms);

use Khaospy::DBH::ControlRooms qw(
    get_control_rooms
    insert_control_room
    delete_control_room
);

use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

###############
# admin rooms :
get '/admin/list_control_rooms'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    my %select = ();
    $select{select_control_id} = params->{control_id} if params->{control_id};
    $select{select_room_id}    = params->{room_id}    if params->{room_id};

    return template 'admin_list_control_rooms' => {
        page_title      => 'Admin : List Control Rooms',
        user            => session('user'),
#        userfullname    => session('userfullname'), # TODO
        error_msg       => pop_error_msg(),

        list_controls   => get_controls({
                id=>$select{select_control_id}
            }),
        list_rooms      => get_rooms({
               id=>$select{select_room_id}
            }),
        %select,

        list_control_rooms => get_control_rooms({
            control_id => params->{control_id},
            room_id => params->{room_id},
        }),
    };
};

post '/admin/add_control_room'  => needs login => sub {
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $add_array;
    my $error_msg;
    try {
        $add_array = $JSON->decode(params->{add_array});
    } catch {
        $error_msg = $_;
    };

    if ($error_msg){
        status 'bad_request';
        return "add_array is not valid JSON. $error_msg";
    }

#    warn "Dumper of the add_array ".Dumper($add_array);
#    warn "Dumper of the params ".Dumper(params);

    my $ret = "Nothing added. Could be all the control rooms already exist. could be something else...";
    for my $add ( @$add_array ) {
        my $room_id = $add->{room_id};
        my $control_id = $add->{control_id};

        try {
            insert_control_room($control_id, $room_id);
            $ret = {
                msg     => 'Success',
            };
            # if one of the inserts is successful, well just ignore the fails !
        } catch {
            # This is an array add. Just log errors to apache.
            # duplicate records will almost certainly trigger this ...
            warn "DB Error : $_";
        };
    }

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

post '/admin/delete_control_room'  => needs login => sub {
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $cr_id = trim(params->{control_room_id});

    my $ret;
    try {
        delete_control_room($cr_id);
        $ret = {
            msg     => 'Success',
        };
    } catch {
        # TODO could get the Exception and give a better error message.
        status 'bad_request';
        $ret = "DB Error: $_";
    };

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

1;
