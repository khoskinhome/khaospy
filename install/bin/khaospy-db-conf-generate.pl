#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw(burp);
use Khaospy::Constants qw(
    $JSON
    $DATABASE_CONF_FULLPATH
);


# script to generate db-conf. change values below :

our $DB_HOST     = 'localhost';
our $DB_USERNAME = 'khaospy_write';
our $DB_PASSWORD = 'password';
our $DB_NAME     = 'khaospy';
our $DB_PORT     = 5432;

write_out_db_conf();

sub write_out_db_conf {

    print "Generating $DATABASE_CONF_FULLPATH\n";

    burp ( $DATABASE_CONF_FULLPATH,

           $JSON->pretty->encode({
                host     => $DB_HOST,
                username => $DB_USERNAME,
                password => $DB_PASSWORD,
                dbname   => $DB_NAME,
                port     => $DB_PORT,
            })
    );

    my $mode = 0600;
    chmod $mode, $DATABASE_CONF_FULLPATH;
}
