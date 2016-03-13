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

# This is to turn the front-room-tv off :
# Sunday to Thursday evenings between 10pm and 6am
# Friday , Saturday evenings between 1am and 6am.

use JSON;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use DateTime;
use Time::HiRes qw/usleep time/;

use Khaospy::ControlPiBoilerHomeEasy qw/run_rules_daemon/;

run_rules_daemon();

