package Khaospy::DBH::Controls;
use strict; use warnings;

use Exporter qw/import/;
use Carp qw(confess);
use Try::Tiny;
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
    iso8601_parse
);

use Khaospy::Conf::Controls qw(
    get_control_config
    control_exists
    can_operate
    can_set_value
    can_set_string

    state_to_binary
);

use Khaospy::Constants qw(
    $PI_STATUS_RRD_UPDATE_TIMEOUT
    $WEBUI_ALL_CONTROL_TYPES
);

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

sub control_status_insert {
    my ( $values ) = @_;

    my $control_name = get_hashval($values,'control_name');
    my $control      = get_control_config($control_name);
    my $control_type = get_hashval($control,'type');

    my $curr_rec =
        get_controls_from_db($control_name);

    # TODO before inserting or updating the controls, needs to check the existing
    # current_state and/or current_value.
    #
    # The control_status (which is really control_logs should always have the insertion.

    if ( scalar @$curr_rec ) {
        # update
        my $sql = <<"        EOSQL";
        UPDATE controls SET
          alias = ?,
          current_state = ?,
          current_value = ?,
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
                $values->{current_value} || undef,
                $values->{last_change_state_time} || undef,
                $values->{last_change_state_by} || undef,
                $values->{manual_auto_timeout_left} || undef,
                $values->{request_time},
                $control_type,
                $control_name,
            );
        };
        klogerror "$@ \n".Dumper($values) if $@;

    } else {
        # insert
        my $sql = <<"        EOSQL";
        INSERT INTO controls
        ( control_name, alias, current_state, current_value,
          last_change_state_time, last_change_state_by,
          manual_auto_timeout_left,
          request_time, db_update_time, control_type
        )
        VALUES
        ( ?,?,?,?,?,?,?,?,NOW(), ? );
        EOSQL

        my $sth = dbh->prepare( $sql );
        eval {
            $sth->execute(
                $control_name,
                $control->{alias},
                $values->{current_state} || undef,
                $values->{current_value} || undef,
                $values->{last_change_state_time} || undef,
                $values->{last_change_state_by} || undef,
                $values->{manual_auto_timeout_left} || undef,
                $values->{request_time},
                $control_type,
            );
        };
        klogerror "$@ \n".Dumper($values) if $@;
    }

    my $sql = <<"    EOSQL";
    INSERT INTO control_status
    ( control_name, current_state, current_value,
      last_change_state_time, last_change_state_by,
      manual_auto_timeout_left,
      request_time, db_update_time
    )
    VALUES
    ( ?,?,?,?,?,?,?,NOW() );
    EOSQL

    my $sth = dbh->prepare( $sql );

    #    my $current_value = $values->{current_value};
    #    $current_value = sprintf("%0.3f",$current_value)
    #        if defined $current_value;

    eval {
        $sth->execute(
            $control_name,
            $values->{current_state} || undef,
            $values->{current_value} || undef,
            $values->{last_change_state_time} || undef,
            $values->{last_change_state_by} || undef,
            $values->{manual_auto_timeout_left} || undef,
            $values->{request_time},
        );
    };

    klogerror "$@ \n".Dumper($values) if $@;
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

        if ( defined $row->{current_value}){
            $row->{current_value}
                = sprintf('%+0.1f', $row->{current_value});
        }

        if ( defined $row->{current_state} ){
            $row->{status_alias} = get_hashval($row, 'current_state');
        }

        $row->{can_operate}    = can_operate($control_name);
        $row->{can_set_value}  = can_set_value($control_name);
        $row->{can_set_string} = can_set_string($control_name);

# TODO. therm sensors have a range. These need CONSTANTS and the therm-config to support-range.
#        $row->{in_range} = "too-low","correct","too-high"
# colours will be blue==too-cold, green=correct, red=too-high.

        $row->{current_state_value}
            = $row->{status_alias} || $row->{current_value} || '' ;

        push @$results, $row;
    }

    return $results;

}

sub get_controls_in_room_for_user {
    my ($user_id, $room_id) = @_;

    my $sql = <<"    EOSQL";
    select
        ct.control_name,
        ct.control_type,
        ct.request_time,
        ct.current_state,
        ct.current_value,
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

        if ( defined $row->{current_value}){
            $row->{current_value}
                = sprintf('%+0.1f', $row->{current_value});
        }

        if ( defined $row->{current_state} ){
            $row->{status_alias} = get_hashval($row, 'current_state');
        }

        my $c_op = $row->{can_operate};
        $row->{can_operate}    = $c_op && can_operate($control_name);
        $row->{can_set_value}  = $c_op && can_set_value($control_name);
        $row->{can_set_string} = $c_op && can_set_string($control_name);


        $row->{current_state_value}
            = $row->{status_alias} || $row->{current_value} || '' ;

        push @$results, $row;
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
        push @$results, $row;
    }
    return $results;
}

sub get_last_control_state {
    # should be refactored with other methods in this module.

    my $last_control_state = {};

    my $sql = <<"    EOSQL";
        select
            control_name,
            alias,
            current_state,
            current_value,
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

    while ( my $hr = $sth->fetchrow_hashref ){

        my $control_name = get_hashval($hr,"control_name");
        if ( ! control_exists($control_name)){
            warn "looks like control '$control_name' has been changed."
                ." DB has stale data. $@";
            next;
        }
        my $control      = get_control_config($control_name);

        init_last_control_state ($last_control_state, $control_name);

        $last_control_state->{$control_name}{last_value}
            = state_to_binary(
                $hr->{current_state} || $hr->{current_value}
            );

        $last_control_state->{$control_name}{last_rrd_update_time}
            = time - $PI_STATUS_RRD_UPDATE_TIMEOUT;

        # deprecating current_state, slowly ... ( just going with current_value )
        for my $hrky ( keys %$hr){
            $last_control_state->{$control_name}{$hrky} = $hr->{$hrky};
        }

        $last_control_state->{$control_name}{current_value} =
            $last_control_state->{$control_name}{last_value};

        delete $last_control_state->{$control_name}{current_state};

        $last_control_state->{$control_name}{last_change_state_time_epoch} =
            iso8601_parse($hr->{last_change_state_time});

        # A hack to make sure the control_type is populated,
        # will get removed once the control-conf is pushed to the DB by the webui :
        $last_control_state->{$control_name}{control_type} =
            get_hashval($control,'type') if ! $hr->{control_type};
    }

    return $last_control_state;
}

sub init_last_control_state {
    # Only init if it doesn't already exist.
    my ($last_control_state, $control_name) = @_;
    if ( ! exists $last_control_state->{$control_name} ){
        $last_control_state->{$control_name}={};
        $last_control_state->{$control_name}{last_value} = undef;
        $last_control_state->{$control_name}{last_rrd_update_time} = undef;
        #$last_control_state->{$control_name}{statusd_updated} = undef;
    }
}

1;
