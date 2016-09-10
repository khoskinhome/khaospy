package Khaospy::WebUI::DB;
use strict; use warnings;

use Exporter qw/import/;

use Khaospy::DBH qw(dbh);
use Khaospy::Constants qw(
    true false
);

use Khaospy::Utils qw(
    get_hashval
    get_iso8601_utc_from_epoch
);

use Khaospy::Conf::Controls qw(
    get_status_alias
    can_operate
);

our @EXPORT_OK = qw(
    get_user
    get_user_password
    get_control_status
    update_user_password

);


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

1;
