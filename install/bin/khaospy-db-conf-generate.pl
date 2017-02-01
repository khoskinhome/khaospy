#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw(
    burp
    get_hashval
);

use Khaospy::Constants qw(
    true false
    $JSON
    $DATABASE_CONF_FULLPATH
);

# script to generate db-conf.
# interactively asks about the default values below :

my $conf_ar = [
        {param =>'host',          default => 'localhost',      change => true},
        {param =>'username',      default => 'khaospy_write',  change => false},
        {param =>'username_read', default => 'khaospy_read',   change => false},
        {param =>'password',      default => 'changepassword', change => true},
        {param =>'dbname',        default => 'khaospy',        change => false},
        {param =>'port',          default => 5432,             change => false},
        {param =>'sslmode',       default => 'require',        change => false},
    ];

my $conf_hsh ={};

for my $cf (@$conf_ar){

    $conf_hsh->{get_hashval($cf,'param')} =
        readin(get_hashval($cf,'param'), get_hashval($cf,'default'), get_hashval($cf,'change'));
}

write_out_db_conf();


sub readin {
    my ( $param, $default_val, $recommend_change ) = @_;

    print "Please enter '$param' (default = $default_val) ";
    print "  You are ".($recommend_change? '':' NOT ')."recommended to change this\n";
    print " ? : ";
    my $val = <STDIN>;
    chomp($val);

    return $val || $default_val;
}

sub write_out_db_conf {

    print "Generating $DATABASE_CONF_FULLPATH\n";

    burp ( $DATABASE_CONF_FULLPATH,
        $JSON->pretty->encode($conf_hsh)
    );

    my $mode = 0600;
    chmod $mode, $DATABASE_CONF_FULLPATH;
}


