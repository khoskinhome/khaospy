#!/usr/bin/perl
use strict;
use warnings;

my $rrdpath = "/opt/khaospy/rrd";
my $rrdimgpath = "/opt/khaospy/rrdimg";

chdir $rrdpath;


my $address_map = {


    '28-0000066ebc74' => 'Alison',
    '28-0000066fe99e' => 'playhouse-2',
    '28-00000670596d' => 'Bathroom',
    '28-000006e04e8b' => 'playhouse-1',
    '28-021463277cff' => 'Loft',
    '28-0214632d16ff' => 'Amelia',
    '28-021463423bff' => 'Upstairs-Landing',

};




while ( <*> ){
    print "$_ $address_map->{$_} \n";

    my $path=$rrdimgpath."/".$_;

    if ( ! -d $path ){
        mkdir $path ;
    }

    my $linkpath = $rrdimgpath."/".lc($address_map->{$_});
    if ( ! -l $linkpath ) {
        system("ln -s $path $linkpath");
    }

    system( "/opt/khaospy/bin/rrdcreategraph.sh $_  $address_map->{$_} $_-".lc($address_map->{$_}) );
}
