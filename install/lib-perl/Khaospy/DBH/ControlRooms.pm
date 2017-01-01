package Khaospy::DBH::ControlRooms;
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
    get_controlrooms
    insert_controlroom
    update_controlroom
    delete_controlroom

    controlrooms_field_valid
    controlrooms_field_desc
);

sub get_controlrooms {

    my $sql =<<"    EOSQL";
    SELECT * FROM control_rooms order by user_id
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute();

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results;
}

sub update_controlroom {
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

sub insert_controlroom {
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

sub delete_controlroom {
    my ( $del ) = @_;
    die "TODO delete_controlroom() not yet implemented"; # TODO
}

####
# User field validation

my $fv_sub = gen_field_valid_sub( 'control_rooms', {

});
sub controlrooms_field_valid { return $fv_sub->(@_) }


my $fd_sub = gen_field_desc_sub( 'control_rooms', {

});
sub controlrooms_field_desc { return $fd_sub->(@_) }

1;
