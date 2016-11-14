package Khaospy::WebUI::UserLogin;
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
    get_iso8601_utc_from_epoch
    password_meets_restrictions
);

use Khaospy::DBH::Users qw(
    get_user
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

get '/' => needs login => sub {
    my $error_msg = pop_error_msg();

    return template index => {
        user      => session->read('user'),
        error_msg => $error_msg,
    };
};

get '/logout' => sub {
    session 'user'          => undef;
    session 'user_is_admin' => undef;
    session 'user_id'       => undef;
    redirect '/';
};

get '/login' => sub {

    redirect '/' if session('user');
    return template 'login' => {
        error_msg  => pop_error_msg(),
        return_url => params->{return_url},
        user       => params->{user},
    };
};

post '/login' => sub {

    my $user      = param('user');
    my $password  = param('password');
    my $redir_url = param('redirect_url') || '/login';

    if (defined param('reset_password')){
        redirect uri_for('/reset_password', { user => $user });
        return;
    }

    my $user_record = get_user_password($user,$password);
    if ( ! $user_record ){
        session 'error_msg' => 'Incorrect user / password';
        redirect uri_for('/login', {
            user => $user,
            redirect_url =>$redir_url,
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

    my $must_change
        = get_hashval($user_record,'passhash_must_change',true) || false;

    if ( $must_change ){
        session 'error_msg' => 'You have to change your password';
        redirect uri_for('/user/change_password', {
            user => $user,
            redirect_url =>$redir_url,
        });
        return;
    }

    my $is_passhash_expired
        = get_hashval($user_record,'is_passhash_expired', true) ;

    if ( $is_passhash_expired ) {
        session 'error_msg' => 'Your password has expired, you have to change it';
        redirect uri_for('/user/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    session 'user'          => $user;
    session 'user_id'       => get_hashval($user_record,'id');
    session 'user_is_admin' => get_hashval($user_record,'is_admin');

    redirect $redir_url;
};

get '/reset_password' => sub { # don't need login for this root.

    return template 'reset_password'
        => {
            user       => params->{user} || session->read('user'),
            return_url => params->{return_url},
            error_msg  => pop_error_msg(),
        };
};

post '/reset_password' => sub { # don't need login for this root.
    my $user        = param('user') ;
    my $email       = param('email');
    my $redir_url   = param('redir_url');
    my $user_record = get_user($user);

    if ( ! defined $user_record
        || get_hashval($user_record,'email') ne $email){

        session 'error_msg'
            => "username and email combination don't match any known users";

        redirect uri_for('/reset_password', {
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

    # reset the password, and email it .
    my $new_password = rand_password();

    my $exp_mins = $PASSWORD_RESET_TIMEOUT / 60 ;

    my $body = <<"EOBODY";
Your password has been reset.

This reset password will expire in $exp_mins minutes.

When you login, you will be required to change the password.

Password is:

$new_password

EOBODY


    eval {
        update_user_password(
            $user,
            $new_password,
            true,
            get_iso8601_utc_from_epoch(time+$PASSWORD_RESET_TIMEOUT),
        );
    };
    if( $@ ){
        warn "Issue reseting password for $user. $@";
        session 'error_msg' => "Error reseting password. Admin needs to look at logs";
        redirect uri_for('/reset_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    send_email({
        to      => get_hashval($user_record,'email'),
        subject => "Khaospy. Reset Password",
        body    => $body,
    });

    redirect uri_for('/login', {
        user         => $user,
        redirect_url => $redir_url,
    });
};

sub rand_password {
    my @alphanum = qw(
        a b c d e f g h i j k m n p r s t u v w x y z
        A B C D E F G H J K L M N P R S T U V W X Y Z
        0 1 2 3 4 5 6 7 8 9);
    return join( "", map { $alphanum[rand(int(@alphanum))] } 1 .. 10 );
}


1;
