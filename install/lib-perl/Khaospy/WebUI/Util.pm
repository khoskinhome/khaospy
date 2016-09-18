package Khaospy::WebUI::Util;
use strict; use warnings;

use Exporter qw/import/;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2;
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

#use Khaospy::DBH qw(dbh);
#use Khaospy::Constants qw(
#    true false
#);
#
#use Khaospy::Log qw(
#    klogstart klogfatal klogerror
#    klogwarn  kloginfo  klogdebug
#    DEBUG
#);
#
#use Khaospy::Utils qw(
#    get_hashval
#    get_iso8601_utc_from_epoch
#);
#
#use Khaospy::Conf::Controls qw(
#    get_status_alias
#    can_operate
#);

our @EXPORT_OK = qw(
    pop_error_msg
);

sub pop_error_msg {
    my $error_msg = session->read('error_msg') || "";
    session 'error_msg' => "";
    return $error_msg;
}

1;
