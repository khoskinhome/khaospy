package Khaospy::DBH::Rooms;
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
);

use Khaospy::Exception qw(
    KhaospyExcept::InvalidFieldName
);

our @EXPORT_OK = qw(
    get_rooms
    insert_room
    update_room
    delete_room

    room_name_valid
    room_name_desc

    room_tag_valid
    room_tag_desc
);

sub get_rooms {

    my $sql =<<"    EOSQL";
    SELECT * FROM rooms order by name
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute();

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results;
}

sub update_room {
    # TODO
#    my ($user_id, $password, $must_change, $expire_time) = @_;
#
#    $password = _trunc_password($password);
#    # could raise an exception ...
#    die "password doesn't meet restrictions"
#        if ! password_valid($password);
#
#    if ( $must_change ) { $must_change = 'true' }
#    else { $must_change = 'false' }
#
#    my $sql =<<"    EOSQL";
#        update users
#        set passhash             = crypt( ? ,gen_salt('bf',8)) ,
#            passhash_must_change = ? ,
#            passhash_expire      = ?
#        where id  = ?
#    EOSQL
#
#    my $sth = dbh->prepare($sql);
#    $sth->execute($password, $must_change, $expire_time, $user_id );

}

sub insert_room {
    my ( $add ) = @_;
    # TODO
#    my ( @fields, @values, @placeholders );
#
#    for my $fld ( keys %$add ){
#        KhaospyExcept::InvalidFieldName->throw(
#            error => users_field_desc($fld)
#        ) if ! users_field_valid($fld,$add->{$fld});
#
#        if ( $fld eq 'password' ) {
#            push @fields, "passhash";
#            push @values, "crypt( ? ,gen_salt('bf',8))";
#            push @placeholders, '?';
#        } else {
#            push @fields, $fld;
#            push @values, $add->{$fld};
#            push @placeholders, '?';
#        }
#    }
#
#    my $sql = " INSERT INTO users "
#        ."(".join( ", ",@fields).")"
#        ." VALUES (".join( ", ", @placeholders).")";
#
#    my $sth = dbh->prepare($sql);
#    $sth->execute(@values);

}

sub delete_room {
    my ( $add ) = @_;
    # TODO
}
####
# User field validation

sub room_name_valid {
    my ($name) = @_;
    return false if length($name) < 2;

    return true if $name =~ /^[a-z][a-z0-9\-_\s]+$/i;
    return false;
}

sub room_name_desc {
    return "The 'room-name' must be at least 3 characters long, must start with a-z and only contain a-z, numerics, underscore, space or hyphen. ";
}

sub room_tag_valid {
    my ($tag) = @_;
    return false if length($tag) < 2;

    return true if $tag =~ /^[a-z][a-z0-9\-_]+$/;
    return false;
}

sub room_tag_desc {
    return "The 'tag-name' must be at least 3 characters long, must start with lower-case a-z and only contain lower-case a-z, numerics, underscore or hyphen. ";
}

1;
