package Khaospy::WebUI::Admin;
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

use Khaospy::DBH::Users qw(
    get_users
    get_user_by_id
    update_field_by_user_id
    update_user_id_password
    insert_user

    password_valid
    password_desc

    email_address_valid
    email_address_desc

    mobile_phone_valid
    mobile_phone_desc

    users_field_valid
    users_field_desc

);

use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

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

    if ( $user_id == session->read('user_id') &&
        ( $field eq 'is_admin' || $field eq 'is_enabled' || $field eq 'username' )
    ){
        status 'bad_request';
        return "current admin user is not allowed to disable themself or change their username";
    }

    my $ret = {};

    my $user_record = get_user_by_id($user_id);
    if ( ! $user_record ){
        status 'bad_request';
        return "can't get the user record";
    }

    if ( ! users_field_valid($field,$value) ){
        status 'bad_request';
        return users_field_desc($field);
    }

    my $email_body ;
    if ( $field eq 'is_enabled' ) {
        my $disabled_enabled = lc($value) eq 'true' ? "enabled" : "disabled";
        $email_body = "The administrator has $disabled_enabled your account";
    }

    if ( $field eq 'email' || $field eq 'mobile_phone' ){
        my $disabled_enabled = $value ? "enabled" : "disabled";
        $email_body = "The administrator has changed your $field to $value";
    }

    send_email({
        to      => get_hashval($user_record,'email'),
        subject => "Khaospy. Adminstrator has changed your account",
        body    => $email_body,
    }) if $email_body;

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
        $ret = "Error updating DB";
    };

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

post '/api/v1/admin/list_user/update_password/:user_id'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $user_id      = params->{user_id};
    my $new_password = params->{password};

    if( ! password_valid($new_password)){
        status 'bad_request';
        return password_desc;
    }

    my $user_record = get_user_by_id($user_id);
    if ( ! $user_record ){
        status 'bad_request';
        return "can't get the user record";
    }

    send_email({
        to      => get_hashval($user_record,'email'),
        subject => "Khaospy. Adminstrator has changed your password",
        body    => "The administrator has changed your password",
    });

    my $ret = {};
    try {
        update_user_id_password($user_id,$new_password);
        $ret = {
            msg     => 'Success',
            user_id => $user_id,
        };
    } catch {
        # TODO could get the Exception and give a better error message.
        status 'bad_request';
        $ret = "error updating DB";
    };

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

post '/api/v1/admin/delete_user/:user_id'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $user_id      = params->{user_id};

    # for admin users to delete
    # TODO

};

get '/admin/add_user'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_add_user' => {
        page_title  => 'Admin : Add User',
        add         => {is_enabled => true },
        user        => session('user'),
        error_msg   => pop_error_msg(),
    };

};

post '/admin/add_user'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    my $add = {};
    my $error ={};
    my $error_msg = '';

    for my $fld (qw(
        username name password email mobile_phone
        is_enabled is_api_user is_admin can_remote
    )){
        my $val = trim(param($fld));
        next if ! defined $val;

        $add->{$fld} = $val;
        if ( ! users_field_valid($fld, $add->{$fld}) ){
            $error->{$fld} = users_field_desc($fld);
            $error_msg     = "field errors";
        }
    };

    if ( $error_msg ){
        session 'error_msg' => $error_msg;
        return template 'admin_add_user' => {
            page_title  => 'Admin : Add User',
            user        => session('user'),
            error_msg   => pop_error_msg(),
            add         => $add,
            error       => $error,
        };
    }

    try {
        insert_user($add);
    } catch {
        $error_msg = "Error inserting into DB. $_";
    };

    return template 'admin_add_user' => {
        page_title  => 'Admin : Add User',
        user        => session('user'),
        error_msg   => $error_msg,
        add         => $add,
    } if $error_msg;

    session 'error_msg' => "user '$add->{username}' added";
    redirect uri_for('/admin/add_user', {});
    return;
};

1;
