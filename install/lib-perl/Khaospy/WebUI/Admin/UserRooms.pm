package Khaospy::WebUI::Admin::UserRooms;
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

use Khaospy::DBH::Users qw(get_users);
use Khaospy::DBH::Rooms qw(get_rooms);


use Khaospy::DBH::UserRooms qw(
    get_user_rooms
    insert_user_room
    update_user_room
    delete_user_room
);


use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

###############
# admin rooms :
get '/admin/list_user_rooms'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');


    my %select = ();
    $select{select_user_id} = params->{user_id} if params->{user_id};
    $select{select_room_id} = params->{room_id} if params->{room_id};

    return template 'admin_list_user_rooms' => {
        page_title      => 'Admin : List User Rooms',
        user            => session('user'),
        error_msg       => pop_error_msg(),

        list_users      => get_users({
            #    id=>$select{select_user_id}
            }),
        list_rooms      => get_rooms({
            #   id=>$select{select_room_id}
            }),
        %select,

        list_user_rooms => get_user_rooms({
            user_id => params->{user_id},
            room_id => params->{room_id},
        }),
    };
};

post '/admin/update_user_room'  => needs login => sub {
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $ur_id       = params->{user_room_id};
    my $can_operate = params->{can_operate};
    my $can_view    = params->{can_view};

    my $ret;
    try {
        update_user_room($ur_id,
            { can_operate  => $can_operate,
              can_view     => $can_view,
            }
        );
        $ret = {
            msg          => 'Success',
            ur_id        => $ur_id,
            can_operate  => $can_operate,
            can_view     => $can_view,
        };
    } catch {
        # TODO could get the Exception and give a better error message.
        warn "DB Error: update_user_room : $_";
        status 'bad_request';
        $ret = "Error updating DB. $_";
    };

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

post '/admin/add_user_room'  => needs login => sub {
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

    my $ret = "nothing added. could be all the user rooms already exist. could be something else...";
    for my $add ( @$add_array ) {
        my $room_id = $add->{room_id};
        my $user_id = $add->{user_id};

        try {
            insert_user_room($user_id, $room_id);
            $ret = {
                msg     => 'Success',
            };
            # if one of the inserts is successful, well just ignore the fails !
        } catch {
            # This is an array add. Just log errors to apache.
            warn "DB Error : $_";
        };
    }

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

post '/admin/delete_user_room'  => needs login => sub {
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $ur_id = trim(params->{user_room_id});

    my $ret;
    try {
        delete_user_room($ur_id);
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
