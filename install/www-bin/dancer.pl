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
    get_iso8601_utc_from_epoch
);

use Khaospy::QueueCommand qw/ queue_command /;

use Khaospy::Constants qw(
    true false
    $DANCER_BASE_URL
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

    # TODO check if password has expired, if it has redirect to change_password    # if there is a must change then redirect to reset_password and raise an error message saying saying the emailed password has expired.




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

    # TODO has password expired ? if so redirect to a change password page.

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
    my $body = <<"EOBODY";
Your password has been reset.

This reset password will expire in 60 minutes.

When you login, you will be required to change the password

Password is:

$new_password

EOBODY


    eval {
        update_user_password(
            $user,
            $new_password,
            true,
            get_iso8601_utc_from_epoch(time+3600),
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
            eval {
                $row->{status_alias} =
                    get_status_alias(
                        $control_name, get_hashval($row, 'current_state')
                    );
            };

            if ($@) {
                warn "looks like control_name has been changed."
                    ." DB has stale data. $@";
                next;
            }
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

sub update_user_password {
    my ($user,$password, $must_change, $expire_time) = @_;

    #truncate password to 72 chars. That is all "bf" can handle.

    #$expire_time = 'null' if ! $expire_time ;

    if ( $must_change ) { $must_change = 'true' }
    else { $must_change = 'false' }

    my $sql =<<"    EOSQL";
        update users
        set passhash             = crypt( ? ,gen_salt('bf',8)) ,
            passhash_must_change = ? ,
            passhash_expire      = ?
        where username  = ?
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute($password, $must_change, $expire_time ,lc($user));
}

dance;

