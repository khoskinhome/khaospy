package Khaospy::DBH;
use strict; use warnings;
use DBI;
use Exporter qw/import/;

our @EXPORT_OK = qw(
    dbh

    gen_field_valid_sub
    gen_field_desc_sub

    anything_valid
    anything_desc_sub

    boolean_valid
    boolean_desc_sub

    timestamp_with_tz_valid
    timestamp_with_tz_desc_sub

);

use Khaospy::Constants qw(
    true false
);

use Khaospy::Conf qw( get_database_conf );
use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::Exception qw(
    KhaospyExcept::InvalidFieldName
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



sub gen_field_valid_sub {
    my ( $table_name, $valid_spec ) = @_;

    return sub {
        my ($field, $value) = @_;
        $field = lc($field);

        KhaospyExcept::InvalidFieldName->throw(
            error => "$table_name : Invalid field '$field'"
        ) if ! exists $valid_spec->{$field};

        return true if $valid_spec->{$field}->($value);

        return false;
    }
}

sub gen_field_desc_sub {
    my ( $table_name, $desc_spec ) = @_;
    return sub {
        my ($field) = @_;
        $field = lc($field);

        KhaospyExcept::InvalidFieldName->throw(
            error => "$table_name : Invalid field '$field'"
        ) if ! exists $desc_spec->{$field};

        return $desc_spec->{$field}->();
    }
}

# general field validation subs :

sub boolean_valid {
    # TODO maybe some boolean checking here.
    return true;
}

sub boolean_desc_sub {
    my ($field) = @_;
    $field = lc($field);

    return sub {
        return "$field is not a boolean. ";
    }
}

sub anything_valid {
    return true;
}

sub anything_desc_sub {
    my ($field) = @_;
    $field = lc($field);

    return sub {
        return "$field is allowed to be anything";
    }
}

sub timestamp_with_tz_valid {
    # TODO maybe some timestamp tz checking here.
    # 2016-12-14 00:36:17.35655+00
    return 1;
}

sub timestamp_with_tz_desc_sub {
    my ($field) = @_;
    $field = lc($field);

    return sub {
        return "$field is not a timestamp with TZ. ";
    }
}


1;
