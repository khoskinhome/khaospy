#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

# This is a terrible script . It does work though.
# install/bin/khaospy-command-queue-d.pl:18:use Getopt::Long;
if ( $>  != 0 ) {
    die "Need to run this as root \n";
}


chdir "/opt/khaospy/log" || die  "can't chdir to logs";


for my $f (<*>) {
    print "file $f\n";
    unlink $f;

}
