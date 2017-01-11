package Khaospy::WebUI::Admin;
use strict; use warnings;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

use Khaospy::Email qw(send_email);
use Khaospy::Utils qw(
    trim
    get_hashval
);

use Khaospy::WebUI::Util; # can't import.
sub user_template_flds { Khaospy::WebUI::Util::user_template_flds(@_) };

get '/admin' => needs login => sub {

    return template 'permission_denied.tt' => {
        user_template_flds('Admin'),
    } if ! session->read('user_is_admin');

    return template 'admin' => {
        user_template_flds('Admin'),
    };
};

1;
