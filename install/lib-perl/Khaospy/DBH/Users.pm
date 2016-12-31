package Khaospy::DBH::Users;
use strict; use warnings;

use Exporter qw/import/;

use Email::Valid;

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
    trim
    get_hashval
    get_iso8601_utc_from_epoch
);

use Khaospy::Exception qw(
    KhaospyExcept::InvalidFieldName
);

our @EXPORT_OK = qw(
    get_user
    get_user_by_id
    get_users
    get_user_password
    update_user_by_id

    insert_user
    delete_user

    password_valid
    password_desc

    email_address_valid
    email_address_desc

    mobile_phone_valid
    mobile_phone_desc

    users_field_valid
    users_field_desc
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

sub get_user { # get user by username
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

sub update_user_by_id {
    my ( $user_id, $data ) = @_;

    my $errors = {};
    my (@fields, @values);

    for my $fld (keys %$data){
        next if $fld eq 'id';
        my $val = trim(get_hashval($data,$fld,true));

        if ( ! users_field_valid($fld, $data->{$fld}) ){
            $errors->{$fld} = users_field_desc($fld);
        } else {
            if ( $fld eq 'password'){
                push @fields, " passhash = crypt( ? ,gen_salt('bf',8)) ";
                $val = _trunc_password($val);
            } else {
                push @fields, " $fld = ? ";
            }
            push @values , $val;
        }
    }

    KhaospyExcept::InvalidFieldName->throw(
        error => Dumper($errors)
    ) if keys %$errors;

    my $sql =
        " UPDATE users SET ".join( ", ",@fields)." WHERE id = ? ";

    my $sth = dbh->prepare($sql);
    $sth->execute( @values, $user_id );
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

sub delete_user {
    die "TODO . delete_user not yet implemented";
}

sub insert_user {
    my ( $add ) = @_;

    my ( @fields, @values, @placeholders );

    for my $fld ( keys %$add ){
        KhaospyExcept::InvalidFieldName->throw(
            error => users_field_desc($fld)
        ) if ! users_field_valid($fld,$add->{$fld});

        if ( $fld eq 'password' ) {
            push @fields, "passhash";
            push @placeholders, "crypt( "
                .dbh->quote($add->{$fld})
                ." ,gen_salt('bf',8))";
        } else {
            push @fields, $fld;
            push @values, $add->{$fld};
            push @placeholders, '?';
        }
    }

    my $sql = " INSERT INTO users "
        ."(".join( ", ",@fields).")"
        ." VALUES (".join( ", ", @placeholders).")";

    my $sth = dbh->prepare($sql);
    $sth->execute(@values);
}

####
# User field validation

sub username_valid {
    my ($username) = @_;
    return false if length($username) < 4;

    return true if $username =~ /^[a-z][a-z0-9\-_]+$/;
    return false;
}

sub username_desc {
    return "The 'username' must be at least 4 characters long, start with a letter, only contain lower case a-z, numerics, underscore or hyphen. ";
}

sub name_valid {
    return true if length($_[0]) > 2;
    return false;
}

sub name_desc {
    return "The 'name' must be at least 3 characters long. ";
}

sub password_valid {
    my ($password) = @_;

    if ( $password =~ /[A-Z]/
      && $password =~ /[a-z]/
      && $password =~ /[0-9]/
      && length($password) > 7
    ){ return true }

    if ( $password =~ /[A-Z]/i
      && $password =~ /\W/
      && $password =~ /[0-9]/
      && length($password) > 7
    ){ return true }

    return false;
}

sub password_desc {
    return "Passwords need to be at least 8 characters long and contain one UPPER and one lower case letter plus one number. Alternatively you can have a password that has one letter, one number and one non-word char that is 8 chararacters long. Passwords longer than 72 characters are truncated. ";
}

sub email_address_valid { Email::Valid->address($_[0]) }

sub email_address_desc {
    return "email address must conform to normal standards. ";
}

sub mobile_phone_valid {
    my ($mobile_phone) = @_;

    return true if
        ! defined $mobile_phone
        || $mobile_phone eq "";

    if ( $mobile_phone !~ /^\+?[\d\-\s_]+$/ ){
        return false;
    }
    return true;
}

sub mobile_phone_desc {
    return 'The mobile phone number can only have an optional prefixed-plus-sign, digits, (minus-sign), (underscore) or (space) characters. The mobile phone can be left blank. ';
}

sub anything_valid {
    return true;
}

sub anything_desc_sub {
    my ($field) = @_;
    $field = lc($field);

    return sub {
        return "$field is allowed to be anything";
    }
}

sub boolean_valid {
    # TODO maybe some boolean checking here.
    return 1;
}

sub boolean_desc_sub {
    my ($field) = @_;
    $field = lc($field);

    return sub {
        return "$field is not a boolean. ";
    }
}

sub timestamp_with_tz_valid {
    # TODO maybe some timestamp tz checking here.
    # 2016-12-14 00:36:17.35655+00
    return 1;
}

sub timestamp_with_tz_desc_sub {
    my ($field) = @_;
    $field = lc($field);

    return sub {
        return "$field is not a boolean. ";
    }
}


sub users_field_valid {
    my ($field, $value) = @_;
    $field = lc($field);

    # The fields must never be added to validation here :
    #    passhash
    #    id

    my $valid_field_sub = {
        username                => \&username_valid,
        name                    => \&name_valid,
        password                => \&password_valid,
        email                   => \&email_address_valid,
        mobile_phone            => \&mobile_phone_valid,
        is_enabled              => \&boolean_valid,
        is_api_user             => \&boolean_valid,
        is_admin                => \&boolean_valid,
        can_remote              => \&boolean_valid,
        passhash_must_change    => \&boolean_valid,
        passhash_expire         => \&timestamp_with_tz_valid,
        email_confirm_hash      => \&anything_valid,
    };

    KhaospyExcept::InvalidFieldName->throw(
        error => "users_field_valid() : Invalid field '$field'"
    ) if ! exists $valid_field_sub->{$field};

    return true if $valid_field_sub->{$field}->($value);

    return false;
}

sub users_field_desc {
    my ($field) = @_;
    $field = lc($field);

    my $desc_field_sub = {
        username                => \&username_desc,
        name                    => \&name_desc,
        password                => \&password_desc,
        email                   => \&email_address_desc,
        mobile_phone            => \&mobile_phone_desc,
        is_enabled              => boolean_desc_sub('is_enabled'),
        is_api_user             => boolean_desc_sub('is_api_user'),
        is_admin                => boolean_desc_sub('is_admin'),
        can_remote              => boolean_desc_sub('can_remote'),
        passhash_must_change    => boolean_desc_sub('passhash_must_change'),
        passhash_expire         => timestamp_with_tz_desc_sub('passhash_expire'),
        email_confirm_hash      => anything_desc_sub('email_confirm_hash'),

   };

    KhaospyExcept::InvalidFieldName->throw(
        error => "users_field_desc() : Invalid field '$field'"
    ) if ! exists $desc_field_sub->{$field};

    return $desc_field_sub->{$field}->();
}

1;
