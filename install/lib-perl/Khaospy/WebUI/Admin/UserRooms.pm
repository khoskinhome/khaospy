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

    userrooms_field_valid
    userrooms_field_desc
);


use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

###############
# admin rooms :
get '/admin/list_user_rooms'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_list_user_rooms' => {
        page_title      => 'Admin : List User Rooms',
        user            => session('user'),
        error_msg       => pop_error_msg(),

        list_users      => get_users(),
        select_user_id  => params->{user_id},

        list_rooms      => get_rooms(),
        select_room_id  => params->{room_id},

        list_user_rooms => get_user_rooms({
            user_id => params->{user_id},
            room_id => params->{room_id},
        }),
    };
};

post '/admin/add_user_room/:user_id/:room_id'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

};

get '/admin/add_user_room'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'not_implemented' => {
        page_title      => 'Admin : Add User',
        user            => session('user'),
        error_msg       => pop_error_msg(),
    };

#    return template 'admin_add_user_room' => {
#        page_title  => 'Admin : Add User Room',
#        user        => session('user'),
#        error_msg   => pop_error_msg(),
#    };

};


1;
