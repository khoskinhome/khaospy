package Khaospy::WebUI::Admin::Rooms;
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

use Khaospy::DBH::Rooms qw(
    get_rooms
    insert_room
    update_room
    delete_room

    room_name_valid
    room_name_desc

    room_tag_valid
    room_tag_desc

    rooms_field_valid
    rooms_field_desc
);

use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

###############
# admin rooms :
get '/admin/list_rooms'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_list_rooms' => {
        page_title      => 'Admin : List Rooms',
        user            => session('user'),
        list_rooms      => get_rooms(),
        error_msg       => pop_error_msg(),
    };
};

get '/admin/add_room'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_add_room' => {
        page_title  => 'Admin : Add Room',
        user        => session('user'),
        error_msg   => pop_error_msg(),
    };

};

post '/admin/add_room'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    my $add = {};
    my $error ={};
    my $error_msg = '';

    for my $fld (qw( name tag )){
        my $val = trim(param($fld));
        next if ! defined $val;

        $add->{$fld} = $val;
        if ( ! rooms_field_valid($fld, $add->{$fld}) ){
            $error->{$fld} = rooms_field_desc($fld);
            $error_msg     = "field errors";
        }
    };

    if ( ! $error_msg ){
        try {
            insert_room($add);
        } catch {
            $error_msg = "Error inserting into DB. $_";
        };
    }

    return template 'admin_add_room' => {
        page_title  => 'Admin : Add Room',
        user        => session('user'),
        error_msg   => $error_msg,
        add         => $add,
        error       => $error,
    } if $error_msg;

    session 'error_msg' => "room '$add->{name}' added";
    redirect uri_for('/admin/add_room', {});
    return;
};

1;
