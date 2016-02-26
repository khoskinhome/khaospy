#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use JSON;
use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw/slurp/;
use Khaospy::Constants qw(
    $CONTROLS_CONF_FULLPATH
);

use Khaospy::OrviboS20 qw/signal_control/;


# generate the daemon-runner JSON conf file in perl !

my $json = JSON->new->allow_nonref;

  ## install/bin/khaospy-generate-rrd-graphs.pl:21:my $thermometer_conf = $json->decode( # TODO rm this line

  ## install/lib-perl/Khaospy/Constants.pm:113:        '28-0000066ebc74' => { # TODO rm this line

my $controls = $json->decode(
    slurp ( $CONTROLS_CONF_FULLPATH )
);


#my $host  = '192.168.1.160';
#my $mac = 'AC-CF-23-72-F3-D4';
#test_on_off_status($host,$mac);

use Getopt::Long;

my $control_name;
my $action ;

GetOptions (
    "c=s" => \$control_name,
    "a=s" => \$action,
);
$action = lc($action);

if ( ! $control_name || ! $action ) {
    print "You need to supply both parameters\n";
    die_usage();
}
if ( $action ne 'on' && $action ne 'off' && $action ne 'status' ){
    print "The action '-a $action' can only be 'on', 'off' or 'status'\n";
    die_usage();
}

if ( ! exists $controls->{$control_name} ){
    print "The control name '-c $control_name' wasn't found in the config\n";
    print Dumper ( $controls ) ;
    die_usage();

}

my $control = $controls->{$control_name};
if ( $control->{type} ne 'orviboS20'){
    print "The control name '-c $control_name' isn't an 'orvibos20'\n";
    print Dumper ( $controls ) ;
    die_usage();
}

my $host = $control->{host};
my $mac  = $control->{mac};

my $return;
eval { $return = signal_control( $host, $mac, $action ) };

if ( $@ ) {
    print "FAILED to operate control ($host, $mac, $action) DIED with return = $return ; $@\n";
} else {
    if ($action eq $return){
        print "PASSED operating control ($host, $mac, $action) return = $return\n";
    } else {
        print "FAILED to operate control ($host, $mac, $action) return = $return\n";
    }
}

sub die_usage {
    die " $0 -c <control-name> -a <action>(on|off|status)\n";
};
