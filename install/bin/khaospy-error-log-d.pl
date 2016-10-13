#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::ErrorLogDaemon qw(
    run_error_log_daemon
);

=pod


=cut

#TODO write it !

run_error_log_daemon();


exit 0;
