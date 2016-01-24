package Khaospy::Log;
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Exporter qw/import/;
use Carp qw/confess/;
use Sys::Hostname;
use Data::Dumper;

use Khaospy::Conf qw/get_global_conf/;
use Khaospy::Utils qw/timestamp/;

sub START {"start"};
sub FATAL {"fatal"};
sub ERROR {"error"};
sub WARN  {"warn"};
sub INFO  {"info"};
sub DEBUG {"debug"};

sub klogstart ($;$) { klog(START,@_) };
sub klogfatal ($;$) { klog(FATAL,@_) };
sub klogerror ($;$) { klog(ERROR,@_) };
sub klogwarn  ($;$) { klog(WARN ,@_) };
sub kloginfo  ($;$) { klog(INFO ,@_) };
sub klogdebug ($;$) { klog(DEBUG,@_) };

our @EXPORT_OK = qw(
    klog START FATAL ERROR WARN INFO DEBUG
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
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

our $OVERRIDE_CONF_LOGLEVEL;

sub klog {
    my ( $type, $msg, $dump ) = @_;
    $type = lc ($type);

    my $global_conf = get_global_conf;

    my $log_level = $OVERRIDE_CONF_LOGLEVEL || $global_conf->{log_level};

    my $log_level_val = $type_to_val->{$log_level};

    $log_level_val = 4 if ! $log_level_val;

    if (! exists $type_to_val->{$type} ){
        confess "Illegal log type of $type\n";
    }

    my $line = timestamp."|".uc($type)."|".hostname."|$msg|";
    $line .= "Dump :\n".Dumper($dump) if $dump;
    $line .= "\n";

    if ( $type eq "fatal" ) {
        confess $line;
    }

    my $tval = $type_to_val->{$type};

    # only warn, info and debug can be switched off from logging
    print $line
        if $tval <= $log_level_val or $tval <= 3;
}

1;
