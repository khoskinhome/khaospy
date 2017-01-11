package Khaospy::WebUI::Admin::Users;
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

    update_user_by_id

    insert_user
    delete_user

    password_valid
    password_desc

    users_field_valid
    users_field_desc

);

use Khaospy::WebUI::Util; # can't import.
sub user_template_flds { Khaospy::WebUI::Util::user_template_flds(@_) };

################
# admin users :
get '/admin/list_users'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_list_users' => {
        user_template_flds('Admin : List Users'),
        list_users  => get_users(),
    };
};

####################################
# The list-users form isn't doing direct user updating now.
# There is some stuff in here , like emailing that needs to go into the update_user root.
#
#post '/api/v1/admin/list_user/update/:user_id/:field'  => needs login => sub {
#
#    header( 'Content-Type'  => 'application/json' );
#    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );
#
#    if ( ! session->read('user_is_admin')){
#        status 'bad_request';
#        return "user is not an admin";
#    }
#
#    my $user_id = params->{user_id};
#    my $field   = params->{field};
#    my $value   = params->{value};
#
#    if ( $user_id == session->read('user_id') &&
#        ( $field eq 'is_admin' || $field eq 'is_enabled' || $field eq 'username' )
#    ){
#        status 'bad_request';
#        return "current admin user is not allowed to disable themself or change their username";
#    }
#
#    my $ret = {};
#
#    my $user_record = get_user_by_id($user_id);
#    if ( ! $user_record ){
#        status 'bad_request';
#        return "can't get the user record";
#    }
#
#    if ( ! users_field_valid($field,$value) ){
#        status 'bad_request';
#        return users_field_desc($field);
#    }
#
#    my $email_body ;
#    if ( $field eq 'is_enabled' ) {
#        my $disabled_enabled = lc($value) eq 'true' ? "enabled" : "disabled";
#        $email_body = "The administrator has $disabled_enabled your account";
#    }
#
#    if ( $field eq 'email' || $field eq 'mobile_phone' ){
#        my $disabled_enabled = $value ? "enabled" : "disabled";
#        $email_body = "The administrator has changed your $field to $value";
#    }
#
#    send_email({
#        to      => get_hashval($user_record,'email'),
#        subject => "Khaospy. Adminstrator has changed your account",
#        body    => $email_body,
#    }) if $email_body;
#
#    try {
#        update_user_by_id($user_id, { $field => $value });
#        $ret = {
#            msg     => 'Success',
#            user_id => $user_id,
#            field   => $field,
#            value   => $value
#        };
#    } catch {
#        # TODO could get the Exception and give a better error message.
#        status 'bad_request';
#        $ret = "Error updating DB";
#    };
#
#    return $ret if ref $ret ne 'HASH';
#    return to_json $ret;
#};

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
        update_user_by_id($user_id,{ password => $new_password });
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

post '/admin/delete_user'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! session->read('user_is_admin')){
        status 'bad_request';
        return "user is not an admin";
    }

    my $user_id = trim(params->{user_id});

    if ( $user_id == session->read('user_id') ){
        status 'bad_request';
        return "admin user cannot delete their own account";
    }

    my $error_msg;

    try {
        delete_user($user_id);
    } catch {
        $error_msg = "DB Error : $_";
    };

    if ($error_msg){
        status 'bad_request';
        return $error_msg;
    }

    status 'no_content';
    return;
};

get '/admin/add_user'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_add_user' => {
        user_template_flds('Admin : Add User'),
        add         => {is_enabled => true },
    };
};

post '/admin/add_user'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    my $add       = {};
    my $error     = {};
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

        $add->{$fld} = undef if ! $add->{$fld};

    };

    if ( $error_msg ){
        return template 'admin_add_user' => {
            page_title  => 'Admin : Add User',
            user        => session('user'),
            error_msg   => $error_msg,
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

get '/admin/update_user/:user_id'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    my $user_id     = params->{user_id};
    my $user_record = get_user_by_id($user_id);
    if ( ! $user_record ){
        status 'bad_request';
        session 'error_msg' => "can't get the user record $user_id";
        redirect uri_for('/admin/list_users', {});
    }

    return template 'admin_update_user' => {
        user_template_flds('Admin : Update User'),
        data        => $user_record,
    };
};

post '/admin/update_user'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');
    my $data      = {};
    my $error     = {};
    my $error_msg = '';

    my $user_id = trim(param('user_id'));
    $data->{id} = $user_id;

    my $user_record = get_user_by_id($user_id);
    if ( ! $user_record ){
        status  'bad_request';
        session 'error_msg' => "can't get the user record $user_id";
        redirect uri_for('/admin/list_users', {});
    }

    if ( $user_id == session->read('user_id') ){
        # this is the current admin user.
        # make sure they don't disable themself.

        for my $fld (qw(is_admin is_enabled)){
            my $val = trim(param($fld)) eq 'on' ? 1 : 0 ;

warn ( "update user : $fld new val == $val. old_val == $user_record->{$fld}\n");
            if ($val ne $user_record->{$fld}){
                $error->{$fld} = "current admin user can't disable their own user account";
                $error_msg     = "field errors";
            }
        }
    }

    for my $fld (qw(
        username name email mobile_phone
        is_enabled is_api_user is_admin can_remote
    )){
        my $val = trim(param($fld));
        next if ! defined $val;

        $data->{$fld} = $val;
        if ( ! users_field_valid($fld, $data->{$fld}) ){
            $error->{$fld} = users_field_desc($fld);
            $error_msg     = "field errors";
        }
    };

    if ( ! $error_msg ) {
        try {
            update_user_by_id($user_id, $data);
        } catch {
            $error_msg = "Error inserting into DB. $_";
        };
    }

    if ( $error_msg ){
        return template 'admin_update_user' => {
            page_title  => 'Admin : Update User',
            user        => session('user'),
            error_msg   => $error_msg,
            data        => $data,
            error       => $error,
        };
    }

    session 'error_msg' => "user '$data->{username}' update";
    redirect uri_for("/admin/list_users", {});
    return;
};


1;
