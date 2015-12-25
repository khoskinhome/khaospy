#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;
use Data::Dumper;

# see the crontab one from Pavel Shved
# http://stackoverflow.com/questions/1603109/how-to-make-a-python-script-run-like-a-service-or-daemon-in-linux

use JSON;

use Sys::Hostname qw/hostname/;
my $thishost = hostname;
print "This host is $thishost\n";

my $khaospy_root = "/opt/khaospy";
my $conf_file="$khaospy_root/conf/daemon-runner.json";


my $pid_dir ="/tmp/khaospy-pid";

if ( ! -d $pid_dir ) {
    system("mkdir $pid_dir") && die "Can't create dir $pid_dir\n";
    system("ln -s $pid_dir /opt/khaospy/pid") && die "Can't create sym link to $pid_dir\n";
}

my $log_dir ="/opt/khaospy/log";
die "no log dir $log_dir\n" if ! -d $log_dir;

my $json = JSON->new->allow_nonref;

my $conf = $json->decode( slurp ($conf_file) );

if ( ! exists $conf->{$thishost} ) {

    die "This hostname $thishost not found in the config file $conf_file . Dumper of conf = \n";
    print Dumper ($conf);

}


print Dumper ($conf);

$tconf = $conf->($thishost);

for my $cfg_entry ( @$tconf ) {

    my $scriptname_short = $cfg_entry->{script} || die "No script entry !";

    $scriptname_short =~/[\/\s]/_/g;

    die "No params entry !" if ! exists $cfg_entry->{params};
    my $params_short = $cfg_entry->{params} || "" ;
    $params_short =~/[\/\s]/_/g;

    my $log_file = "$log_dir/$scriptname_short.$params_short";
    my $pid_file = "$pid_dir/$scriptname_short.$params_short";

    print "log file = $log_file\npid file = $pid_file\n";

}


sub slurp {
    my ($file ) = @_;

    open( my $fh, $file ) or die "Can't open $file\n";
    return do { local( $/ ) ; <$fh> } ;
}
