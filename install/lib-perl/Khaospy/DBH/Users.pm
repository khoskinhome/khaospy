package Khaospy::DBH::Users;
use strict; use warnings;

use Exporter qw/import/;

use Khaospy::DBH qw(dbh);
use Khaospy::Constants qw(
    true false
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
    DEBUG
);

use Khaospy::Utils qw(
    get_hashval
    get_iso8601_utc_from_epoch
    password_meets_restrictions
);

use Khaospy::Exception qw(
    KhaospyExcept::InvalidFieldName
);

our @EXPORT_OK = qw(
    get_user
    get_user_by_id
    get_users
    get_user_password
    update_user_password
    update_user_id_password
    update_field_by_user_id
);

sub get_user_password {
    my ($user, $password) = @_;

    $password = _trunc_password($password);

    my $sql = <<"    EOSQL";
    SELECT * ,
        ( passhash_expire IS NOT NULL AND passhash_expire < NOW())
            as is_passhash_expired
    FROM users
    WHERE
        LOWER(username) = ?
        AND passhash = crypt( ? , passhash);
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(lc($user), $password);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    # TODO what if more than one record is returned ?
    # handle error. A few of these in this file ...

    return $results->[0] if @$results;
    return;
}

sub get_user {
    my ($user) = @_;

    my $sql =<<"    EOSQL";
    SELECT *,
        ( passhash_expire IS NOT NULL AND passhash_expire < NOW())
            as is_passhash_expired
    FROM users WHERE LOWER(username) = ?
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(lc($user));

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results->[0] if @$results;
    return;
}

sub get_user_by_id {
    my ($user_id) = @_;

    my $sql =<<"    EOSQL";
    SELECT *,
        ( passhash_expire IS NOT NULL AND passhash_expire < NOW())
            as is_passhash_expired
    FROM users WHERE id = ?
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute($user_id);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results->[0] if @$results;
    return;
}

sub get_users {

    my $sql =<<"    EOSQL";
    SELECT * FROM users order by username
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute();

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results;
}

sub update_user_id_password {
    my ($user_id, $password, $must_change, $expire_time) = @_;

    $password = _trunc_password($password);
    # could raise an exception ...
    die "password doesn't meet restrictions"
        if ! password_meets_restrictions($password);

    if ( $must_change ) { $must_change = 'true' }
    else { $must_change = 'false' }

    my $sql =<<"    EOSQL";
        update users
        set passhash             = crypt( ? ,gen_salt('bf',8)) ,
            passhash_must_change = ? ,
            passhash_expire      = ?
        where id  = ?
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute($password, $must_change, $expire_time, $user_id );

}

sub update_user_password {
    my ($user,$password, $must_change, $expire_time) = @_;

    $password = _trunc_password($password);
    # could raise an exception ...
    die "password doesn't meet restrictions"
        if ! password_meets_restrictions($password);

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

sub update_field_by_user_id {
    my ($user_id, $field, $value ) = @_;

    # should really get this from the DB schema ...
    # these are the only fields that an admin can update on the "list_users" page.
    my $valid_field = {
        username              =>1,
        name                  =>1,
        email                 =>1,
        is_api_user           =>1,
        is_admin              =>1,
        mobile_phone          =>1,
        can_remote            =>1,
        passhash_must_change  =>1,
        is_enabled            =>1,
    };

    KhaospyExcept::InvalidFieldName->throw(
        error => "Invalid field '$field' passed to update_field_by_user_id"
    ) if ! exists $valid_field->{$field};

    my $sql =<<"    EOSQL";
        update users
        set $field = ?
        where id = ?
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute($value, $user_id);
}

sub _trunc_password {
    my ($password) = @_;

    # postgres bf algorithm truncates at 72 chars
    # not sure if this is necessary, but I guess its best to be safe.
    if (length($password) > 72){
        return substr $password,0,72;
    }

    return $password;
}

1;
