#!/usr/bin/perl
use strict; use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2;
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;
use Khaospy::Email qw(send_email);
use Khaospy::Utils qw(
    get_hashval
    get_iso8601_utc_from_epoch
);

use Khaospy::QueueCommand qw/ queue_command /;

use Khaospy::WebUI::DB qw(
    get_user
    get_user_password
    get_controls_from_db
    update_user_password

);

use Khaospy::WebUI::Constants qw(
    $PASSWORD_RESET_TIMEOUT
    $DANCER_BASE_URL
);

use Khaospy::Constants qw(
    true false
);

sub pop_error_msg {
    my $error_msg = session->read('error_msg') || "";
    session 'error_msg' => "";
    return $error_msg;
}

get '/' => needs login => sub {
    my $error_msg = pop_error_msg();

    return template index => {
        user      => session('user'),
        error_msg => $error_msg,
    };
};

get '/logout' => sub {
    session 'user' => undef;
    redirect '/';
};

get '/login' => sub {
    my $error_msg = pop_error_msg();

    redirect '/' if session('user');
    return template 'login' => {
        error_msg => $error_msg,
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
        redirect uri_for('/login', {
            user => $user,
            redirect_url =>$redir_url,
        });
        return;
    }

    my $must_change
        = get_hashval($user_record,'passhash_must_change',true) || false;

    if ( $must_change ){
        session 'error_msg' => 'You have to change your password';
        redirect uri_for('/change_password', {
            user => $user,
            redirect_url =>$redir_url,
        });
        return;
    }

    my $passhash_expire
        = get_hashval($user_record,'passhash_expire', true) ;

    if ( $passhash_expire ) {

        # TODO has password expired ? if so redirect to a change password page.
        # TODO check if password has expired, if it has redirect to change_password    # if there is a must change then redirect to reset_password and raise an error message saying saying the emailed password has expired.

    



    }

    session 'user' => $user;
    redirect $redir_url;
};

get '/reset_password' => sub { # don't need login for this root.

    my $error_msg = pop_error_msg();

    return template 'reset_password'
        => {
            user       => params->{user},
            return_url => params->{return_url},
            error_msg  => $error_msg,
        };
};

post '/reset_password' => sub { # don't need login for this root.
    my $user        = param('user');
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
    # reset the password, and email it .
    my $new_password = rand_password();

    my $exp_mins = $PASSWORD_RESET_TIMEOUT / 60 ;

    my $body = <<"EOBODY";
Your password has been reset.

This reset password will expire in $exp_mins minutes.

When you login, you will be required to change the password.

WORKING TODO RM THIS 

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

get '/change_password' => sub { # don't need login for this root.

    my $error_msg = pop_error_msg();

    return template 'change_password' => {
        user       => params->{user},
        return_url => params->{return_url},
        error_msg  => $error_msg,
    };
};

post '/change_password' => sub { # don't need login for this root.
    my $user          = param('user');
    my $old_password  = param('old_password');
    my $new_password  = param('new_password');
    my $new_password2 = param('new_password2');
    my $redir_url     = param('redir_url');

    my $user_record = get_user_password($user,$old_password);
    if ( ! $user_record ){
        session 'error_msg'
            => 'The username and old password do not match any users';

        redirect uri_for('/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    if ( $new_password ne $new_password2 ){
        session 'error_msg' => "The new passwords do not match";
        redirect uri_for('/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    if ( $new_password eq $old_password ){
        session 'error_msg' => "The old and new passwords must be different";
        redirect uri_for('/change_password', {
            user         => $user,
            redirect_url => $redir_url,
        });
        return;
    }

    # password complexity rules.
    # At least 8 chars long.
    # At least one lower case letter, one Upper case, one number.
    if(    $new_password !~ /[A-Z]/
         || $new_password !~ /[a-z]/
         || $new_password !~ /[0-9]/
         || length($new_password) < 8
    ){
        session 'error_msg' => "The new password needs to be at least 8 characters long,<br> contain one UPPER case and one lower case letter plus one number";
        redirect uri_for('/change_password', {
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
        redirect uri_for('/change_password', {
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

get '/user_update'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone
    # warning that giving an invalid email address will require an admin user to fix it. especially if they want to change their password.



};

post '/user_update'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone


};

get '/admin/user_update_create'  => needs login => sub {
    # for non-admin users to update details
    # username, name, email, mobile_phone is_api_user is_admin can_remote
    # password
    # needs to check the current logged in user is_admin=true


};

post '/admin/user_update_create'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone
    # needs to check the current logged in user is_admin=true


};

post '/api/v1/operate/:control/:action'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );


    my $control_name = params->{control};
    my $action       = params->{action};

    my $ret = {};

    try {
        # TODO this needs to have a timeout :
        $ret = { msg => queue_command($control_name,$action) };
    } catch {
        status 'bad_request';
        return "Couldn't operate $control_name with action '$action'";
    };

    return to_json $ret;
};

get '/api/v1/status/:control' => needs login => sub {
    my $stat = get_controls_from_db(params->{control});

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! scalar @$stat ){
        status 'not_found';
        return "Control doesn't exist";
    }

    if ( scalar @$stat > 1 ){
        status 'bad_request';
        return "More than one control";
    }

    return to_json $stat->[0];
};

get '/api/v1/statusall' => needs login => sub {
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    my $stat = get_controls_from_db();
    return to_json $stat;
};

get '/status'  => needs login => sub {
    return template 'status.tt', {
        page_title      => 'Status',
        user            => session('user'),
#        DANCER_BASE_URL => $DANCER_BASE_URL,
        entries         => get_controls_from_db(),
    };
};

get '/cctv'  => needs login => sub {
    return template 'cctv.tt', {
        page_title      => 'CCTV',
        user            => session('user'),
#        DANCER_BASE_URL => $DANCER_BASE_URL,
        entries         => get_controls_from_db(),
    };
};

dance;

