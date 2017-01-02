package Khaospy::DBH::UserRooms;
use strict; use warnings;

use Exporter qw/import/;

use Email::Valid;

use Khaospy::DBH qw(
    dbh

    gen_field_valid_sub
    gen_field_desc_sub

    boolean_valid
    boolean_desc_sub
);

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
    get_user_rooms
    insert_user_room
    update_user_room
    delete_user_room

    userrooms_field_valid
    userrooms_field_desc
);

sub get_user_rooms {
    my ( $p ) = @_;

    my @where_ar;
    my @bind;

    for my $pfld (qw(user_id room_id)){
        if ( $p->{$pfld} ){
            push @where_ar, " $pfld = ? ";
            push @bind , $p->{$pfld};
        }
    }

    my $where = join ( ' AND ', @where_ar );
    $where = "WHERE $where" if $where;

    my $sql =<<"    EOSQL";
    SELECT
        ur.id,
        user_id,
        room_id,
        can_operate,
        can_view,
        username,
        u.name as userfullname,
        r.name as room_name,
        r.tag  as room_tag

    FROM user_rooms as ur

    LEFT JOIN users as u on (u.id = ur.user_id)
    LEFT JOIN rooms as r on (r.id = ur.room_id)

    $where

    ORDER BY user_id
    EOSQL

    warn "user_rooms sql = $sql";

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results;
}

sub update_user_room {
#    my ($room_id, $update) = @_;
#
#    my ( @fields, @values, @placeholders );
#
#    for my $fld ( keys %$update ){
#        KhaospyExcept::InvalidFieldName->throw(
#            error => rooms_field_desc($fld)
#        ) if ! rooms_field_valid($fld,$update->{$fld});
#
#        push @fields, " $fld = ? ";
#        push @values, $update->{$fld};
#    }
#
#    my $sql = " UPDATE rooms set"
#        .join( ", ",@fields)
#        ." WHERE id  = ?";
#
#    my $sth = dbh->prepare($sql);
#    $sth->execute(@values,$room_id);
}

sub insert_user_room {
#    my ( $add ) = @_;
#    my ( @fields, @values, @placeholders );
#
#    for my $fld ( keys %$add ){
#        KhaospyExcept::InvalidFieldName->throw(
#            error => rooms_field_desc($fld)
#        ) if ! rooms_field_valid($fld,$add->{$fld});
#
#        push @fields, $fld;
#        push @values, $add->{$fld};
#        push @placeholders, '?';
#    }
#
#    my $sql = " INSERT INTO rooms "
#        ."(".join( ", ",@fields).")"
#        ." VALUES (".join( ", ", @placeholders).")";
#
#    my $sth = dbh->prepare($sql);
#    $sth->execute(@values);
}

sub delete_user_room {
    my ( $del ) = @_;
    die "TODO delete_room() not yet implemented"; # TODO
}

####
# User field validation

my $fv_sub = gen_field_valid_sub( 'user_rooms', {
    can_operate => \&boolean_valid,
    can_view    => \&boolean_valid,
});
sub userrooms_field_valid { return $fv_sub->(@_) }


my $fd_sub = gen_field_desc_sub( 'user_rooms', {
    can_operate => boolean_desc_sub('can_operate'),
    can_view    => boolean_desc_sub('can_view'),
});
sub userrooms_field_desc { return $fd_sub->(@_) }

1;
