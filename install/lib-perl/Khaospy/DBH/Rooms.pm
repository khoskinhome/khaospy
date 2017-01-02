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

    rooms_field_valid
    rooms_field_desc
);

sub get_rooms {
    my ( $p ) = @_;
    $p = {} if ! $p;

    my $where;
    my @bind;

    if ($p->{id}){
        $where = " WHERE id = ? ";
        push @bind, $p->{id};
    }

    my $sql =<<"    EOSQL";
    SELECT * FROM rooms
    $where ORDER BY name
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results;
}

sub update_room {
    my ($room_id, $update) = @_;

    my ( @fields, @values, @placeholders );

    for my $fld ( keys %$update ){
        KhaospyExcept::InvalidFieldName->throw(
            error => rooms_field_desc($fld)
        ) if ! rooms_field_valid($fld,$update->{$fld});

        push @fields, " $fld = ? ";
        push @values, $update->{$fld};
    }

    my $sql = " UPDATE rooms set"
        .join( ", ",@fields)
        ." WHERE id  = ?";

    my $sth = dbh->prepare($sql);
    $sth->execute(@values,$room_id);
}

sub insert_room {
    my ( $add ) = @_;
    my ( @fields, @values, @placeholders );

    for my $fld ( keys %$add ){
        KhaospyExcept::InvalidFieldName->throw(
            error => rooms_field_desc($fld)
        ) if ! rooms_field_valid($fld,$add->{$fld});

        push @fields, $fld;
        push @values, $add->{$fld};
        push @placeholders, '?';
    }

    my $sql = " INSERT INTO rooms "
        ."(".join( ", ",@fields).")"
        ." VALUES (".join( ", ", @placeholders).")";

    my $sth = dbh->prepare($sql);
    $sth->execute(@values);
}

sub delete_room {
    my ( $del ) = @_;
    die "TODO delete_room() not yet implemented"; # TODO
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

sub rooms_field_valid {
    my ($field, $value) = @_;
    $field = lc($field);

    my $valid_field_sub = {
        name => \&room_name_valid,
        tag  => \&room_tag_valid,
    };

    KhaospyExcept::InvalidFieldName->throw(
        error => "users_field_valid() : Invalid field '$field'"
    ) if ! exists $valid_field_sub->{$field};

    return true if $valid_field_sub->{$field}->($value);

    return false;
}

sub rooms_field_desc {
    my ($field) = @_;
    $field = lc($field);

    my $desc_field_sub = {
        name => \&room_name_desc,
        tag  => \&room_tag_desc,
   };

    KhaospyExcept::InvalidFieldName->throw(
        error => "users_field_desc() : Invalid field '$field'"
    ) if ! exists $desc_field_sub->{$field};

    return $desc_field_sub->{$field}->();
}


1;
