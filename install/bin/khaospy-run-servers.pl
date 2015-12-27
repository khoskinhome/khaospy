#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;
use Data::Dumper;

# This script should be run at least every 2 mins from the root crontab.

# TODO insist this script is run as root.

use JSON;

use Sys::Hostname qw/hostname/;
my $thishost = hostname;
print "This host is $thishost\n";

my $khaospy_root = "/opt/khaospy";
my $conf_file="$khaospy_root/conf/daemon-runner.json";

my $pid_dir ="/tmp/khaospy/pid";
if ( ! -d $pid_dir ) {
    system("mkdir -p $pid_dir") && die "Can't create dir $pid_dir\n";
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

for my $cfg_entry ( @{$conf->{$thishost}} ){

    my ( $scriptname_short ) = $cfg_entry =~ /.*\/(.*)$/;
    $scriptname_short =~ s/[=\/\s]/_/g;

    my $command = "$cfg_entry";
    print "Checking $command\n";

    my $log_file = "$log_dir/${scriptname_short}";
    my $pid_file = "${scriptname_short}.pid";

    # currently the directory /opt/khaospy/bin is unsafe . so "/usr/bin/daemon" needs
    # to be run with -U switch. TODO this needs fixing.
    my $syscall = <<"    EOCOMMAND";
        sudo /usr/bin/daemon
            -U
            --name=$pid_file
            --pidfiles=$pid_dir
            --stdout=$log_file.stdout
            --stderr=$log_file.stderr
            --errlog=$log_file.errlog
            --dbglog=$log_file.dbglog
            --output=$log_file.output
            --command='$command';
    EOCOMMAND

    $syscall =~ s/\n/ /g;
    $syscall =~ s/\s{2,}/ /g;

    print $syscall."\n";

    system ( "$syscall" ) ;
}

sub slurp {
    my ($file ) = @_;
    print "Opening file $file\n";

    open( my $fh, $file ) or die "Can't open $file\n";
    return do { local( $/ ) ; <$fh> } ;
}

