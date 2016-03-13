#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
# This is a very hacky hardcoded controller for my one-off of
# getting an homeeasy remote control by pi-gpios, just running on piboiler.
#
# it doesn't seem worth the effort going through all the config stuff.
# there is an hardcoded config. this is never going to be used more than once.
# homeeasy controls are crap, and will be deprecated from my system.

use JSON;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::ControlPiBoilerHomeEasy qw/operate/;

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
operate( $control_name, $action );

sub die_usage {
    die " $0 -c <control-name> -a <action>(on|off|status)\n";
};
