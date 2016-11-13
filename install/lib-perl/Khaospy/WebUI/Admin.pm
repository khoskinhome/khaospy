package Khaospy::WebUI::Admin;
use strict; use warnings;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;
use Khaospy::DBH::Users qw(
    get_users
    update_field_by_user_id
);

get '/admin' => needs login => sub {

    return template 'permission_denied.tt' => {
        page_title      => 'Admin',
        user            => session('user'),
    } if ! session->read('user_is_admin');

#    redirect '/' if session('user');
    return template 'admin' => {
        page_title      => 'Admin',
        user            => session('user'),
    };

};

get '/admin/list_users'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_list_users' => {
        page_title      => 'Admin : List Users',
        user            => session('user'),
        list_users      => get_users(),
    };
};

get '/admin/user_update_create'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    # for admin users to update details
    # username, name, email, mobile_phone is_api_user is_admin can_remote
    # password
    # needs to check the current logged in user is_admin=true


};

post '/admin/user_update_create'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    # for admin users to update details
    # name, email, mobile_phone
    # needs to check the current logged in user is_admin=true


};

post '/api/v1/admin/list_user/update/:user_id/:field'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $user_id = params->{user_id};
    my $field   = params->{field};
    my $value   = params->{value};

    my $ret = {};

    try {
        update_field_by_user_id($user_id, $field,$value);
        $ret = {
            msg     => 'Success',
            user_id => $user_id,
            field   => $field,
            value   => $value
        };
    } catch {
        # TODO could get the Exception and give a better error message.
        status 'bad_request';
        $ret = "error updating DB";
    };

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

1;
