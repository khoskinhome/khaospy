package Khaospy::DBH::Controls;
use strict; use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2017

use Exporter qw/import/;

our @EXPORT_OK = qw(
    get_controls
    get_controls_from_db
    control_status_insert
    get_last_control_state
    init_last_control_state
    get_controls_in_room_for_user
    user_can_operate_control
    get_controls_webui_var_type
);

use Data::Dumper;
use Carp qw(confess);
use Try::Tiny;
use Khaospy::DBH qw(dbh);

use Khaospy::Conf::Global qw(
    gc_PI_STATUS_RRD_UPDATE_TIMEOUT
);

use Khaospy::Constants qw(
    true false
    $WEBUI_ALL_CONTROL_TYPES
);

use Khaospy::Utils qw(
    get_hashval
    get_iso8601_utc_from_epoch
    iso8601_parse
);

use Khaospy::Conf::Controls qw(
    get_control_config
    control_exists
    can_set_on_off
    can_set_value
    can_set_string

    state_trans_control
    state_to_binary
    control_good_state
    get_one_wire_therm_desired_range
);

sub control_status_insert {
    my ( $values ) = @_;

    my $control_name = get_hashval($values,'control_name');
    my $control      = get_control_config($control_name);
    my $control_type = get_hashval($control,'type');

    confess "can't insert current_state_trans" if exists $values->{current_state_trans};

    #eventually enable this line :
    #confess "can't insert current_value" if exists $values->{current_value};

    # and this should eventually be removed :
    if ($values->{current_value} ){
        warn "control_status_insert() received a 'current_value'\n";

        $values->{current_state} = $values->{current_value}
            if ! $values->{current_state};
    }

    my $curr_rec =
        get_controls_from_db($control_name);

    # The control_status (which is really control_logs should always have the insertion.

    # TODO needs to insert / update in the controls table only ( not control_status )
    # the fields :
    #    last_lowest_state_time   TIMESTAMP WITH TIME ZONE,
    #    last_lowest_state        TEXT,
    #    last_highest_state_time  TIMESTAMP WITH TIME ZONE,
    #    last_highest_state       TEXT,

    if ( scalar @$curr_rec ) {
        # update
        my $sql = <<"        EOSQL";
        UPDATE controls SET
          alias = ?,
          current_state = ?,
          last_change_state_time = ? ,
          last_change_state_by = ? ,
          manual_auto_timeout_left = ?,
          request_time = ?,
          db_update_time = NOW(),
          control_type = ?
        WHERE
            control_name = ?
        ;
        EOSQL

        my $sth = dbh->prepare( $sql );
        eval {
            $sth->execute(
                $control->{alias},
                $values->{current_state} || undef,
                $values->{last_change_state_time} || undef,
                $values->{last_change_state_by} || undef,
                $values->{manual_auto_timeout_left} || undef,
                $values->{request_time},
                $control_type,
                $control_name,
            );
        };
        confess "$@ \n".Dumper($values) if $@;

    } else {
        # insert
        my $sql = <<"        EOSQL";
        INSERT INTO controls
        ( control_name, alias, current_state,
          last_change_state_time, last_change_state_by,
          manual_auto_timeout_left,
          request_time, db_update_time, control_type
        )
        VALUES
        ( ?,?,?,?,?,?,?,NOW(), ? );
        EOSQL

        my $sth = dbh->prepare( $sql );
        eval {
            $sth->execute(
                $control_name,
                $control->{alias},
                $values->{current_state} || undef,
                $values->{last_change_state_time} || undef,
                $values->{last_change_state_by} || undef,
                $values->{manual_auto_timeout_left} || undef,
                $values->{request_time},
                $control_type,
            );
        };
        confess "$@ \n".Dumper($values) if $@;
    }

    my $sql = <<"    EOSQL";
    INSERT INTO control_status
    ( control_name, current_state,
      last_change_state_time, last_change_state_by,
      manual_auto_timeout_left,
      request_time, db_update_time
    )
    VALUES
    ( ?,?,?,?,?,?,NOW() );
    EOSQL

    my $sth = dbh->prepare( $sql );

    eval {
        $sth->execute(
            $control_name,
            $values->{current_state} || undef,
            $values->{last_change_state_time} || undef,
            $values->{last_change_state_by} || undef,
            $values->{manual_auto_timeout_left} || undef,
            $values->{request_time},
        );
    };

    confess "$@ \n".Dumper($values) if $@;
}

sub get_controls {
    # This version just gets db fields
    my ( $p ) = @_;
    $p = {} if ! $p;

    my $where = '';
    my @bind;

    if ( $p->{id} ){
        $where = " WHERE id = ? ";
        push @bind, $p->{id};
    } elsif ( $p->{control_name} ){
        $where = " WHERE control_name = ? ";
        push @bind, $p->{control_name};
    }

    my $sql = <<"    EOSQL";
    select * from controls
    $where
    order by control_name
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind);
    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }
    return $results;
}

sub get_controls_from_db {
    # This version calcs things for display

    # if the webui code is changed, this could get removed,
    # and just get_controls_in_room_for_user() left remaining.

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
        current_state
    from controls
    $control_select
    order by control_name
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind_vals);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){

        my $control_name = get_hashval($row,'control_name');
        if ( ! control_exists($control_name)){
            warn "looks like control '$control_name' has been changed."
                ." DB has stale data. $@";
            next;
        }

        # This method isn't used for setting the webui controls , so
        # these aren't really needed, plus there isn't a permissions check.
        #$row->{can_set_on_off} = can_set_on_off($control_name);
        #$row->{can_set_value}  = can_set_value($control_name);
        #$row->{can_set_string} = can_set_string($control_name);

        $row->{good_state} = control_good_state($control_name);

        $row->{current_state_trans} = state_trans_control(
            $control_name, get_hashval($row,'current_state', true));

        push @$results, $row;
    }

    for my $row (@$results){
        my $control_name = get_hashval($row,'control_name');
        ( $row->{therm_lower}, $row->{therm_higher} ) =
            get_one_wire_therm_desired_range($control_name, $results);
    }

    return $results;

}

sub get_controls_in_room_for_user {
    # This version calcs things for display
    # if this is to replace get_controls_from_db(), then it will
    # probably need an optional $control_name param ( like that sub does )
    my ($user_id, $room_id) = @_;

    my $sql = <<"    EOSQL";
    select
        ct.control_name,
        ct.control_type,
        ct.request_time,
        ct.current_state,
        usrm.can_operate

    FROM user_rooms as usrm
       JOIN control_rooms as ctrm on (usrm.room_id = ctrm.room_id)
       JOIN controls as ct on (ct.id = ctrm.control_id)

    WHERE
        usrm.user_id = ? and usrm.room_id = ?
    order by control_name
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute($user_id,$room_id);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){

        my $control_name = $row->{'control_name'};
        next if ! $control_name; # This happens if no controls have been added to the room.

        if ( ! control_exists($control_name)){
            warn "looks like control '$control_name' has been changed."
                ." DB has stale data. $@";
            next;
        }

        my $c_op = $row->{can_operate};
        $row->{can_set_on_off} = $c_op && can_set_on_off($control_name);
        $row->{can_set_value}  = $c_op && can_set_value($control_name);
        $row->{can_set_string} = $c_op && can_set_string($control_name);

        $row->{good_state}     = control_good_state($control_name);

        $row->{current_state_trans} = state_trans_control(
            $control_name, get_hashval($row,'current_state', true));

        push @$results, $row;
    }

    for my $row (@$results){
        my $control_name = get_hashval($row,'control_name');
        ( $row->{therm_lower}, $row->{therm_higher} ) =
            get_one_wire_therm_desired_range($control_name, $results);
    }

    return $results;
}

sub user_can_operate_control {
    my ($p) = @_;

    my $where ;
    my @bind;
    if ($p->{control_name}){
        $where = "WHERE ct.control_name = ? AND usrm.user_id = ? AND usrm.can_operate";
        push @bind, $p->{control_name};
        push @bind, $p->{user_id};
    } elsif ($p->{control_id} ){
        $where = "WHERE ct.id = ? AND usrm.user_id = ? AND usrm.can_operate";
        push @bind, $p->{control_id};
        push @bind, $p->{user_id};
    } else {
        confess "need to supply either control_id or control_name";
    }

    my $sql = <<"    EOSQL";
    select ct.id, usrm.can_operate
    FROM user_rooms as usrm
      JOIN control_rooms as ctrm on (usrm.room_id = ctrm.room_id)
      JOIN controls as ct on (ct.id = ctrm.control_id)
    $where
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind);
    while ( my $row = $sth->fetchrow_hashref ){
        return true;
    }
    return false;
}

sub get_controls_webui_var_type {

    my $control_types =
        join(', ',
            map { dbh->quote($_) }
            keys %$WEBUI_ALL_CONTROL_TYPES);

    my $sql = <<"    EOSQL";
        select * from controls
        where control_type in ( $control_types )
        order by control_name
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute();
    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){

        my $control_name = $row->{'control_name'};
        if ( ! control_exists($control_name)){
            warn "looks like control '$control_name' has been changed."
                ." DB has stale data. $@";
            next;
        }

        push @$results, $row;
    }
    return $results;
}

sub get_last_control_state {
    # should be refactored with other methods in this module.

    my $lcs = {};

    my $sql = <<"    EOSQL";
        select
            control_name,
            alias,
            current_state,
            coalesce(last_change_state_time,request_time)
                as last_change_state_time,
            last_change_state_by,
            manual_auto_timeout_left,
            request_time,
            db_update_time,
            id,
            control_type
        from controls
        order by control_name
    EOSQL

    my $sth = dbh->prepare( $sql );
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref ){

        my $control_name = get_hashval($row,"control_name");
        if ( ! control_exists($control_name)){
            warn "looks like control '$control_name' has been changed."
                ." DB has stale data. $@";
            next;
        }
        my $control      = get_control_config($control_name);

        init_last_control_state ($lcs, $control_name);

        $lcs->{$control_name}{current_state_trans} = state_trans_control(
            $control_name, get_hashval($row,'current_state', true));

        $lcs->{$control_name}{last_value}
            = state_to_binary( $row->{current_state} );

        $lcs->{$control_name}{last_rrd_update_time}
            = time - gc_PI_STATUS_RRD_UPDATE_TIMEOUT;

        for my $mpf ( keys %$row){
            $lcs->{$control_name}{$mpf} = $row->{$mpf};
        }

        $lcs->{$control_name}{last_change_state_time_epoch} =
            iso8601_parse($row->{last_change_state_time});

        # A hack to make sure the control_type is populated,
        # will get removed once the control-conf is pushed to the DB by the webui :
        $lcs->{$control_name}{control_type} =
            get_hashval($control,'type') if ! $row->{control_type};
    }

    return $lcs;
}

sub init_last_control_state {
    # Only init if it doesn't already exist.
    my ($lcs, $control_name) = @_;
    if ( ! exists $lcs->{$control_name} ){
        $lcs->{$control_name}={};
        $lcs->{$control_name}{last_value} = undef;
        $lcs->{$control_name}{last_rrd_update_time} = undef;
        #$lcs->{$control_name}{statusd_updated} = undef;
    }
}

1;
