#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";
# by Karl Kount-Khaos Hoskin. 2015-2016
#
# uses the pi-hosts config file.
#
# this is usually run from the root crontab . i.e.
#
#       sudo crontab -e
#
# then add the line something like to the crontab :
#
#       */1  * * * * /opt/khaospy/bin/khaospy-run-daemons.pl  2>&1  > /dev/null
#

use Data::Dumper;

die "Not root user" if $>;

use Khaospy::Constants qw(
    $JSON
    $KHAOSPY_LOG_DIR
    $KHAOSPY_PID_DIR
);

use Khaospy::Conf::PiHosts qw(
    get_this_pi_host_config
);

my $conf = get_this_pi_host_config;

die "daemons key doesn't exist in conf\n".Dumper($conf)
    if ! exists $conf->{daemons};

for my $daemon_cfg ( @{$conf->{daemons}} ){

    my $script = $daemon_cfg->{script};
    my ( $script_short ) = $script =~ /.*\/(.*)$/;

    my $pid_log_name = $script_short;
    my $cli_opts     = '';

    my $options_rh = $daemon_cfg->{options};
    for my $opt ( keys %{$options_rh} ){
        $pid_log_name .= "_${opt}_$options_rh->{$opt}";
        # TODO could get quoting issues with the following :
        $cli_opts     .= " $opt=$options_rh->{$opt}";
    }

    my $command = "$script $cli_opts";

    print "Checking $command\n";

    my $log_file = "$KHAOSPY_LOG_DIR/$pid_log_name";
    my $pid_file = "$pid_log_name.pid";

    # currently the directory /opt/khaospy/bin is "unsafe"
    # hence "/usr/bin/daemon" needs
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

