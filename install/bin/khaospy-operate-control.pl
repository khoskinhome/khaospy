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
    $KHAOSPY_CONTROLS_CONF_FULLPATH
    STATUS
);

use Khaospy::OperateControls qw/signal_control/;

my $json = JSON->new->allow_nonref;

my $controls = $json->decode(
    slurp ( $KHAOSPY_CONTROLS_CONF_FULLPATH )
);

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

$action = lc $action;

my $return;
eval { $return = signal_control( $control_name, $action ) };

if ( $@ ) {
    print "FAILED to operate control '$control_name' with '$action'. DIED with return = $return ; $@\n";
    die_usage();
} else {
    if ($action eq $return or $action = STATUS ){
        print "PASSED operating control '$control_name' with '$action' . returned = $return\n";
    } else {
        print "FAILED to operate control '$control_name' with '$action'. DIED with return = $return ; $@\n";
        die_usage();
    }
}

sub die_usage {
    die " $0 -c <control-name> -a <action>(on|off|status)\n";
};
