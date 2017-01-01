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

use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

get '/admin' => needs login => sub {

    return template 'permission_denied.tt' => {
        page_title      => 'Admin',
        user            => session('user'),
    } if ! session->read('user_is_admin');

    return template 'admin' => {
        page_title      => 'Admin',
        user            => session('user'),
    };
};

1;
