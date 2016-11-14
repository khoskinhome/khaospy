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
    get_hashval
    password_meets_restrictions
);

use Khaospy::DBH::Users qw(
    get_user_password
    update_user_password
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
    my $user          = param('user');
    my $old_password  = param('old_password');
    my $new_password  = param('new_password');
    my $new_password2 = param('new_password2');
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

    # password complexity rules.
    # At least 8 chars long.
    # At least one lower case letter, one Upper case, one number.
    if( ! password_meets_restrictions($new_password)){
        session 'error_msg' => "The new password needs to be at least 8 characters long,<br> contain one UPPER case and one lower case letter plus one number";
        redirect uri_for('/user/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }


    eval {
        update_user_password($user,$new_password,false);
    };
    if( $@ ){
        warn "Issue updating password for $user. $@";
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



};

post '/user/update'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone


};

1;
