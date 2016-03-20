#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw/slurp/;
use Khaospy::Constants qw(
    $CONTROLS_CONF_FULLPATH
    STATUS
);

use Khaospy::OrviboS20 ;

use Khaospy::Conf::Controls qw(
    get_control_config
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

my $control = get_control_config($control_name);

$action = lc $action;

my $return;
my $current_state;

eval { $current_state = Khaospy::OrviboS20::signal_control(
        $control->{host}, $control->{mac}, $action
    );
};

if ( $@ ) {
    print "FAILED to operate control '$control_name' with '$action'. DIED with return = $current_state ; $@\n";
    die_usage();
} else {
    print "control state = $current_state\n";
}

sub die_usage {
    die " $0 -c <control-name> -a <action>(on|off|status)\n";
};
