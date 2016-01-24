#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Data::Dumper;

use Khaospy::Conf::Controls qw/get_controls_conf/;

my $c = get_controls_conf;

print Dumper ($c);

