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
);

use Khaospy::DBH::Users qw(
    get_user
    get_user_password
    update_user_by_id

    password_valid

);

use Khaospy::Conf::Global qw(
);

use Khaospy::WebUI::Constants qw(
    $PASSWORD_RESET_TIMEOUT
    $DANCER_BASE_URL
);

use Khaospy::Constants qw(
    true false
);

use Khaospy::WebUI::Util;
sub user_template_flds { Khaospy::WebUI::Util::user_template_flds(@_) };

get '/' => needs login => sub {
    return template index => {
        user_template_flds('Home'),
    };
};

get '/logout' => sub {
    session 'user'          => undef;
    session 'user_id'       => undef;
    session 'user_is_admin' => undef;
    session 'user_fullname' => undef;
    redirect '/';
};

get '/login' => sub {
    redirect '/' if session('user');
    return template 'login' => {
        user_template_flds('Login'),
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
    session 'user_fullname' => get_hashval($user_record,'name');

    redirect $redir_url;
};

get '/reset_password' => sub { # don't need login for this root.

    return template 'reset_password' => {
        user_template_flds('Reset Password'),
    };
};

post '/reset_password' => sub { # don't need login for this root.
    my $user        = param('user') ;
    my $email       = param('email');
    my $redir_url   = param('redir_url');
    my $user_record = get_user($user);

    if (param('redir_login')){
        return redirect uri_for('/login', {
            user         => $user,
            redirect_url => $redir_url,
        });
    }

    if ( ! defined $user_record
        || get_hashval($user_record,'email') ne $email){

        session 'error_msg'
            => "Can't find a user with that email";

        redirect uri_for('/reset_password', {
            user         => $user,
            redirect_url => $redir_url,
        });

        return;
    }

    my $user_id = get_hashval($user_record,'id');

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
    my $new_password;

    my $new_pass_error_msg;
    try {
        $new_password = rand_password();
    } catch {
        $new_pass_error_msg = $_;
    };

    if ( $new_pass_error_msg ){
        session 'error_msg' => ( $new_pass_error_msg. ". You could try again." );

        redirect uri_for('/reset_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    my $exp_mins = $PASSWORD_RESET_TIMEOUT / 60 ;

    my $body = <<"EOBODY";
Your password has been reset.

This reset password will expire in $exp_mins minutes.

When you login, you will be required to change the password.

Password is:

$new_password

EOBODY


    eval {
        update_user_by_id($user_id,{
            password => $new_password,
            passhash_must_change => true,
            passhash_expire =>
                get_iso8601_utc_from_epoch(time+$PASSWORD_RESET_TIMEOUT),
        });
    };
    if( $@ ){
        warn "Issue reseting password for $user. $@";
        warn "Tried to reset with password '$new_password'";
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

    session 'error_msg' => 'Email with new password has been sent. This password will expire.<F9>';
    redirect uri_for('/login', {
        user         => $user,
        redirect_url => $redir_url,
    });
};

sub rand_password {
    my @alphanum = qw(
        a b c d e f g h i j k m n p r s t u v w x y z
        A B C D E F G H J K L M N P R S T U V W X Y Z
        0 1 2 3 4 5 6 7 8 9 _ - );

    my $rand_password ;

    for ( 1..20 ) {
        $rand_password = join( "", map { $alphanum[rand(int(@alphanum))] } 1 .. 16 );

        return $rand_password if password_valid($rand_password);
    }

    die "Cannot generate a password that satifises password restrictions";

}


1;
