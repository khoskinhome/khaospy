#!/usr/bin/perl
use strict; use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Try::Tiny;
use Data::Dumper;
use Dancer2;
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;
use Khaospy::DBH qw(dbh);
use Khaospy::Email qw(send_email);
use Khaospy::Conf::Controls qw(
    get_control_config
    get_status_alias
    can_operate
);

use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::QueueCommand qw/ queue_command /;

use Khaospy::Constants qw(
    $DANCER_BASE_URL
);

get '/' => needs login => sub {
    return template index => { user => session('user') };
};

get '/logout' => sub {
    session 'user' => undef;
    redirect '/';
};

get '/login' => sub {
    redirect '/' if session('user');
    return template 'login' => {
        return_url => params->{return_url},
        user       => session->read('reset_username'),
    };
};

post '/login' => sub {

    my $user      = param('user');
    my $password  = param('password');
    my $redir_url = param('redirect_url') || '/login';

    if (defined param('forgot_password')){
        warn "forgot password pressed for $user";
        redirect uri_for('/reset_password', { user => $user });
    }

    redirect uri_for('/login', {
        user => $user,
        redirect_url =>$redir_url,
    })
        if ! get_user_password($user,$password);

    # TODO has password expired ? if so redirect to a change password page.

    session 'user' => $user;
    redirect $redir_url;
};

get '/reset_password' => sub {

    my $error_msg = session->read('error_msg') || "";
    session 'error_msg' => "";

    return template 'reset_password'
        => {
            user       => params->{user} || session->read('reset_username'),
            return_url => params->{return_url},
            error_msg  => $error_msg,
        };
};

post '/reset_password' => sub {
    my $user        = param('user');
    my $email       = param('email');
    my $user_record = get_user($user);
    session 'reset_username' => $user;

    if ( ! defined $user_record
        || get_hashval($user_record,'email') ne $email){

        session 'error_msg' => "username and email combination don't match any known users";

        redirect '/reset_password';
    }
    # reset the password, and email it .
    my $new_password = rand_password();
    my $body = <<"EOBODY";
Your password has been reset.

This reset password will expire in 60 minutes.

When you login, you will be required to change the password

Password is:
$new_password

EOBODY

    # TODO update the DB.


    send_email({
        to      => get_hashval($user_record,'email'),
        subject => "Khaospy. Reset Password",
        body    => $body,
    });

    session 'reset_username' => $user;
    redirect '/login';
};

get '/change_password' => needs login => sub {
#
#    my $error_msg = session->read('error_msg') || "";
#    session 'error_msg' => "";
#
#    return template 'reset_password'
#        => {
#            user       => params->{user},
#            return_url => params->{return_url},
#            error_msg  => $error_msg,
#        };
};

post '/change_password' => needs login => sub {
#    my $user        = param('user');
#    my $email       = param('email');
#    my $user_record = get_user($user);
#
#    if ( ! defined $user_record
#        || get_hashval($user_record,'email') ne $email){
#
#        session 'error_msg' => "username and email combination don't match any known users";
#
#        redirect '/reset_password';
#    }
#    # reset the password, and email it .
#    my $new_password = rand_password();
#    my $body = <<"EOBODY";
#Your password has been reset.
#
#This reset password will expire in 60 minutes.
#
#When you login, you will be required to change the password
#
#Password is:
#$new_password
#
#EOBODY
#
#    # TODO update the DB.
#
#
#    send_email({
#        to      => get_hashval($user_record,'email'),
#        subject => "Khaospy. Reset Password",
#        body    => $body,
#    });
#
#    session 'reset_username' => $user;
#    redirect '/login';
};



sub _send_password_token {


}

sub rand_password {
    my @alphanum = qw(
        a b c d e f g h i j k m n p r s t u v w x y z
        A B C D E F G H J K L M N P R S T U V W X Y Z
        0 1 2 3 4 5 6 7 8 9);
    return join( "", map { $alphanum[rand(int(@alphanum))] } 1 .. 10 );
}

post '/api/v1/operate/:control/:action'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    my $control_name = params->{control};
    my $action       = params->{action};

    my $ret = {};

    try {
        $ret = { msg => queue_command($control_name,$action) };
    } catch {
        status 'bad_request';
        return "Couldn't operate $control_name with action '$action'";
    };

    return to_json $ret;
};

get '/api/v1/status/:control' => needs login => sub {
    my $stat = get_control_status(params->{control});

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

    my $stat = get_control_status();
    return to_json $stat;
};

get '/status'  => needs login => sub {
    return template 'status.tt', {
        page_title      => 'Status',
        user            => session('user'),
#        DANCER_BASE_URL => $DANCER_BASE_URL,
        entries         => get_control_status(),
    };
};

get '/cctv'  => needs login => sub {
    return template 'cctv.tt', {
        page_title      => 'CCTV',
        user            => session('user'),
#        DANCER_BASE_URL => $DANCER_BASE_URL,
        entries         => get_control_status(),
    };
};

sub get_control_status {
    my ($control_name) = @_;

    my $control_select = '';

    my @bind_vals = ();
    if ( $control_name ) {
        $control_select = "where control_name = ?";
        push @bind_vals, $control_name;
    }

    my $sql = <<"    EOSQL";
    select control_name,
        request_time,
        current_state,
        current_value
    from control_status
    where id in
        ( select max(id)
            from control_status
            $control_select
            group by control_name )
    order by control_name;
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind_vals);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){

        my $control_name = get_hashval($row,'control_name');

        if ( defined $row->{current_value}){
            $row->{current_value}
                = sprintf('%+0.1f', $row->{current_value});
        }

        if ( defined $row->{current_state} ){
            $row->{status_alias} =
                get_status_alias(
                    $control_name, get_hashval($row, 'current_state')
                );
        }

        $row->{can_operate} = can_operate($control_name);

# TODO. therm sensors have a range. These need CONSTANTS and the therm-config to support-range.
#        $row->{in_range} = "too-low","correct","too-high"
# colours will be blue==too-cold, green=correct, red=too-high.

        $row->{current_state_value}
            = $row->{status_alias} || $row->{current_value} ;

        push @$results, $row;
    }

    return $results;
}

sub get_user_password {
    my ($user, $password) = @_;

    my $sql = <<"    EOSQL";
    select * from users
    where
        lower(username) = ?
        and passhash = crypt( ? , passhash);
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(lc($user), $password);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    # TODO what if more than one record is returned ?
    # handle error.

    return $results->[0] if @$results;
    return;
}

sub get_user {
    my ($user) = @_;

    my $sql = " select * from users where lower(username) = ? ";
    my $sth = dbh->prepare($sql);
    $sth->execute(lc($user));

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    # TODO what if more than one record is returned ?
    # handle error.

    return $results->[0] if @$results;
    return;
}
dance;

