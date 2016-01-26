#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Conf::HardCoded qw(
    CONF_LIVE
    write_out_conf
);

write_out_conf(CONF_LIVE);

