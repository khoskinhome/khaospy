package Khaospy::WebUI::Util;
use strict; use warnings;

use Exporter qw/import/;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

#use Khaospy::DBH qw(dbh);
#use Khaospy::Constants qw(
#    true false
#);


#use Khaospy::Utils qw(
#    get_hashval
#    get_iso8601_utc_from_epoch
#);

#use Khaospy::Conf::Controls qw(
#    get_status_alias
#    can_operate
#);

our @EXPORT_OK = qw(
    pop_error_msg
    pop_session
);

sub pop_error_msg {
    return pop_session('error_msg');
}

sub pop_session {
    my ($field) = @_;
    if ( ! $field ){
        # TODO raise an error maybe ?
        warn "pop_session called without a field name";
        return '' ;
    }
    my $value = session->read($field) || "";
    session $field => "";
    return $value;
}

1;
