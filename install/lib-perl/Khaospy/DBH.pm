package Khaospy::DBH;
use strict; use warnings;
use DBI;
use Exporter qw/import/;

our @EXPORT_OK = qw(
    dbh
    get_last_control_state
    init_last_control_state
);

use Khaospy::Conf qw( get_database_conf );
use Khaospy::Utils qw(
    get_hashval
    trans_ON_to_value_or_return_val
    
);

use Khaospy::Constants qw(
    $PI_STATUS_RRD_UPDATE_TIMEOUT
);

my $dbh;

sub dbh {
    if ( ! $dbh ){
        my $db_conf     = get_database_conf();
        my $db_host     = get_hashval($db_conf, 'host');
        my $db_username = get_hashval($db_conf, 'username');
        my $db_password = get_hashval($db_conf, 'password');
        my $db_name     = get_hashval($db_conf, 'dbname');
        my $db_port     = get_hashval($db_conf, 'port');

        # TODO sslmode  should go into a DB config setting.

        my $dsn = "DBI:Pg:dbname=$db_name;host=$db_host;sslmode=require;port=$db_port";
        $dbh = DBI->connect($dsn, $db_username, $db_password,
                    { RaiseError => 1 })
                        or die $DBI::errstr;
    }
    return $dbh;
}

# TODO the last_control_state should really be in a separate module.

sub get_last_control_state {

    my $last_control_state = {};

    my $sql = <<"    EOSQL";
        select control_name, request_time, current_state, current_value
        from control_status
        where id in (
            select max(id) from control_status group by control_name )
        order by control_name
    EOSQL

    my $sth = dbh->prepare( $sql );
    $sth->execute();

    while ( my $hr = $sth->fetchrow_hashref ){

        my $control_name = get_hashval($hr,"control_name");
        init_last_control_state ($last_control_state, $control_name);

        $last_control_state->{$control_name}{last_value}
            = trans_ON_to_value_or_return_val(
                $hr->{current_state} || $hr->{current_value}
            );

        $last_control_state->{$control_name}{last_rrd_update_time}
            = time - $PI_STATUS_RRD_UPDATE_TIMEOUT;
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
    }
}

1;
