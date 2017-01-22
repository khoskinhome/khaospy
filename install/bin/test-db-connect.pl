#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Data::Dumper;
use Khaospy::DBH qw(dbh);

my $dbh = dbh();


print Dumper ( get_control_status() );


sub get_control_status {
    my $sql = <<"    EOSQL";
    select control_name,
        request_time,
        current_state
    from control_status
    where id in
        ( select max(id)
            from control_status
            group by control_name )
    order by control_name;
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute();

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){
        push @$results, $row;
    }

    return $results;
}
