#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw(
    get_iso8601_utc_from_epoch
);

print get_iso8601_utc_from_epoch(time+.0137);

