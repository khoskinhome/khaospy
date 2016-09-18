package Khaospy::DBH::Controls;
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
);

use Khaospy::Conf::Controls qw(
    get_status_alias
    can_operate
);

our @EXPORT_OK = qw(
    get_control_status
    get_controls_from_db
    control_status_insert
);

sub control_status_insert {
    my ( $values ) = @_;
    my $curr_rec =
        get_controls_from_db($values->{control_name});

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
          db_update_time = NOW()
        WHERE
            control_name = ?
        ;
        EOSQL

        my $sth = dbh->prepare( $sql );
        eval {
            $sth->execute(
                'TODO fix in Khaopsy::WebUI::DB',
                $values->{current_state} || undef,
                $values->{current_value} || undef,
                $values->{last_change_state_time} || undef,
                $values->{last_change_state_by} || undef,
                $values->{manual_auto_timeout_left} || undef,
                $values->{request_time},
                $values->{control_name},
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
          request_time, db_update_time
        )
        VALUES
        ( ?,?,?,?,?,?,?,?,NOW() );
        EOSQL

        my $sth = dbh->prepare( $sql );
        eval {
            $sth->execute(
                $values->{control_name},
                'TODO fix in Khaopsy::WebUI::DB',
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
            $values->{control_name},
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

sub get_controls_from_db {
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

sub get_control_status {
    # TODO this will be deprecated. control_status will be used for the full log of control statues . the table should really be called "controls_status_log"

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

1;
