package Khaospy::Log;
use strict;
use warnings;

use Exporter qw/import/;
use Carp qw/croak/;
use Sys::Hostname;
use Data::Dumper;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Conf qw/get_global_conf/;
use Khaospy::Utils qw/timestamp/;

sub START {"start"};
sub FATAL {"fatal"};
sub ERROR {"error"};
sub WARN  {"warn"};
sub INFO  {"info"};
sub DEBUG {"debug"};

our @EXPORT_OK = qw(
    log START FATAL ERROR WARN INFO DEBUG
);
=pod
    types
        ERROR
        WARN
        INFO
        DEBUG

    format of a log line :
        timestamp|type|host|message

=cut

my $type_to_val = {
    start =>1,
    fatal =>2,
    error =>3,
    warn  =>4,
    info  =>5,
    debug =>6,
};

sub log {
    my ( $type, $msg, $dump ) = @_;
    $type = lc ($type);

    my $global_conf = get_global_conf;
    my $conf_log_level = $type_to_val->{$global_conf->{log_level}};
    $conf_log_level = 4 if ! $conf_log_level;

    if (! exists $type_to_val->{$type} ){
        croak "Illegal log type of $type\n";
    }

    my $line = timestamp."|".uc($type)."|".hostname."|$msg|";
    $line .= "Dump :\n".Dumper($dump) if $dump;
    $line .= "\n";

    if ( $type eq "fatal" ) {
        croak $line;
    }

    my $tval = $type_to_val->{$type};

    # only warn, info and debug can be switched off from logging
    print $line
        if $tval <= $conf_log_level or $tval <= 3;
}

1;
