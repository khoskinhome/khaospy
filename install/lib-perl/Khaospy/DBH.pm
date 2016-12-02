package Khaospy::DBH;
use strict; use warnings;
use DBI;
use Exporter qw/import/;

our @EXPORT_OK = qw(
    dbh
);

use Khaospy::Conf qw( get_database_conf );
use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::Conf::Controls qw(
    control_exists
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
        my $db_sslmode  = get_hashval($db_conf, 'sslmode');

        my $dsn = "DBI:Pg:dbname=$db_name;host=$db_host;sslmode=$db_sslmode;port=$db_port";
        $dbh = DBI->connect($dsn, $db_username, $db_password,
                    { RaiseError => 1 })
                        or die $DBI::errstr;
    }
    return $dbh;
}

1;
