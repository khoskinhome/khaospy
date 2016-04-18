#!/usr/bin/perl
use strict;
use warnings;

my $rrdpath = "/opt/khaospy/rrd";

chdir $rrdpath;

while ( <*> ) {
    print "$_\n";
    system( "/opt/khaospy/bin/rrdcreategraph.sh $_ ");
}
