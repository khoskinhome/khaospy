package Khaospy::WebUI::User;
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
    get_user
    get_user_password
    update_user_password
    update_user_name_email_phone

    password_valid
    password_desc

    email_address_valid
    email_address_desc

    mobile_phone_valid
    mobile_phone_desc

);

use Khaospy::WebUI::Constants qw(
    $PASSWORD_RESET_TIMEOUT
    $DANCER_BASE_URL
);

use Khaospy::Constants qw(
    true false
);

use Khaospy::WebUI::Util qw(
    pop_error_msg
);

# for some reason the use statement doesn't seem to import pop_error_msg ...
sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

get '/user' => needs login => sub {

#    redirect '/' if session('user');
    return template 'user' => {
        page_title      => 'User',
        user            => session('user'),
    };
};

get '/user/change_password' => sub { # don't need login for this root.

    return template 'change_password' => {
        page_title  => 'User : Change Password',
        user        => session->read('user'),
        change_user => session->read('user') || params->{user} ,
        return_url  => params->{return_url},
        error_msg   => pop_error_msg(),
    };
};

post '/user/change_password' => sub { # don't need login for this root.
    my $user          = trim(param('user'));
    my $old_password  = trim(param('old_password'));
    my $new_password  = trim(param('new_password'));
    my $new_password2 = trim(param('new_password2'));
    my $redir_url     = param('redir_url');

    my $user_record = get_user_password($user,$old_password);
    if ( ! $user_record ){
        session 'error_msg'
            => 'The username and old password do not match any users';

        redirect uri_for('/user/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    if ( ! get_hashval($user_record,'is_enabled') ){

        session 'error_msg'
            => "user is disabled. Please contact the admin";

        redirect uri_for('/login', {
            user         => $user,
            redirect_url => $redir_url,
        });

        return;
    }

    if ( $new_password ne $new_password2 ){
        session 'error_msg' => "The new passwords do not match";
        redirect uri_for('/user/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    if ( $new_password eq $old_password ){
        session 'error_msg' => "The old and new passwords must be different";
        redirect uri_for('/user/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    if( ! password_valid($new_password)){
        session 'error_msg' => password_desc;
        redirect uri_for('/user/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    my $error_msg;
    try {
        update_user_password($user,$new_password,false);
    } catch {
        $error_msg = $_;
    };

    if( $error_msg ){
        warn "Issue updating password for $user. $error_msg";
        session 'error_msg' => "Error updating password. Admin needs to look at logs";
        redirect uri_for('/user/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    my $body = <<"EOBODY";
Your password has been changed by the web interface.

If you weren't expecting this then please check out why this could have happened

EOBODY

    send_email({
        to      => get_hashval($user_record,'email'),
        subject => "Khaospy. Password changed via web interface",
        body    => $body,
    });

    session 'user' => undef;
    session 'error_msg' => "You need to login with the new password";
    redirect uri_for('/login', {
        user         => $user,
        redirect_url => $redir_url,
    });
};

get '/user/update'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone
    # warning that giving an invalid email address will require an admin user to fix it. especially if they want to change their password.

    my $user = session->read('user');

    my $user_record = get_user($user);

    return template 'user_update' => {
        page_title   => 'User : Update',
        user         => $user,
        name         => get_hashval($user_record,'name'),
        email        => get_hashval($user_record,'email'),
        mobile_phone => get_hashval($user_record,'mobile_phone'),
#        return_url  => params->{return_url},
        error_msg   => pop_error_msg(),
    };
};

post '/user/update'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone

    my $user         = session->read('user');
    my $name         = trim(param('name'));
    my $email        = trim(param('email'));
    my $mobile_phone = trim(param('mobile_phone'));
    my $error_msg;

    # TODO filter name, email for xss things ?

    $error_msg .= email_address_desc()
        if ! email_address_valid($email);

    $error_msg .= mobile_phone_desc()
        if ! mobile_phone_valid($mobile_phone);

    if ( $error_msg ){
        session 'error_msg' => $error_msg;
    } else {
        try {
            update_user_name_email_phone(
                $user,
                $name,
                $email,
                $mobile_phone,
            );
        } catch {
            $error_msg = $_;
        };
        session 'error_msg' => $error_msg || 'Updated';
    }

    redirect uri_for('/user/update', { });
};

1;
