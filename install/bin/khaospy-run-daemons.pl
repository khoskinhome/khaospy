#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Data::Dumper;

# This script should be run at least every 2 mins from the root crontab.
# TODO insist this script is run as root.

use Khaospy::Utils qw/slurp/;
use Khaospy::Constants qw(
    $JSON
    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    $KHAOSPY_LOG_DIR
    $KHAOSPY_PID_DIR
);

use Sys::Hostname qw/hostname/;
my $thishost = hostname;
print "This host is $thishost\n";

my $conf = $JSON->decode( slurp ($KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH) );

if ( ! exists $conf->{$thishost} ) {
    print "This hostname $thishost not found in the config file"
        ." $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH . Dumper of conf = \n";
    die Dumper ($conf);
}

for my $cfg_entry ( @{$conf->{$thishost}} ){

    my ( $scriptname_short ) = $cfg_entry =~ /.*\/(.*)$/;
    $scriptname_short =~ s/[=\/\s]/_/g;

    my $command = "$cfg_entry";
    print "Checking $command\n";

    my $log_file = "$KHAOSPY_LOG_DIR/${scriptname_short}";
    my $pid_file = "${scriptname_short}.pid";

    # currently the directory /opt/khaospy/bin is unsafe . so "/usr/bin/daemon" needs
    # to be run with -U switch. TODO this needs fixing.
    my $syscall = <<"    EOCOMMAND";
        sudo /usr/bin/daemon
            -U
            --name=$pid_file
            --pidfiles=$KHAOSPY_PID_DIR
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

