package Khaospy::DBH::ControlRooms;
use strict; use warnings;

use Exporter qw/import/;

use Email::Valid;

use Khaospy::DBH qw(dbh);

use Khaospy::Constants qw( true false );

use Khaospy::Utils qw(
    trim
    get_hashval
);

use Khaospy::Exception qw(
    KhaospyExcept::InvalidFieldName
);

our @EXPORT_OK = qw(
    get_control_rooms
    insert_control_room
    delete_control_room
);

sub get_control_rooms {
    my ( $p ) = @_;

    my @where_ar;
    my @bind;

    for my $pfld (qw(control_id room_id)){
        if ( $p->{$pfld} ){
            push @where_ar, " $pfld = ? ";
            push @bind , $p->{$pfld};
        }
    }

    my $where = join ( ' AND ', @where_ar );
    $where = "WHERE $where" if $where;

    my $sql =<<"    EOSQL";
    SELECT
        cr.id,
        control_id,
        room_id,
        control_name,
        alias as control_alias,
        r.name as room_name,
        r.tag  as room_tag

    FROM control_rooms as cr

    LEFT JOIN controls as ctrl on (ctrl.id = cr.control_id)
    LEFT JOIN rooms as r on (r.id = cr.room_id)

    $where

    ORDER BY room_tag, control_name
    EOSQL

    warn "control_rooms sql = $sql";

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results;
}

sub insert_control_room {
    my ( $control_id, $room_id ) = @_;

    die "There is already a record for control_id=$control_id, room_id=$room_id"
        if _get_id($control_id, $room_id);

    my $sql = "INSERT INTO control_rooms (control_id, room_id) VALUES( ?, ?)";
    my $sth = dbh->prepare($sql);
    $sth->execute($control_id, $room_id);

    return _get_id($control_id, $room_id);
}

sub _get_id {
    my ( $control_id, $room_id ) = @_;
    my $sql_sel ="SELECT * FROM control_rooms where control_id = ? and room_id = ?";
    my $sth = dbh->prepare($sql_sel);
    $sth->execute($control_id, $room_id);
    while ( my $row = $sth->fetchrow_hashref ){
        return get_hashval($row,'id');
    }
    return;
}

sub delete_control_room {
    my ( $control_room_id ) = @_;
    my $sql =" DELETE FROM control_rooms WHERE id = ?";
    my $sth = dbh->prepare($sql);
    $sth->execute($control_room_id);
}

1;
