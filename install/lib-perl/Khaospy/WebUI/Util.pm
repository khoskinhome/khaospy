package Khaospy::WebUI::Util;
use strict; use warnings;

# Dancer2 that is needed for session() param() breaks Exporter
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

use Khaospy::WebUI::Constants qw(
    $DANCER_BASE_URL
);

#use Khaospy::Utils qw(
#    get_hashval
#    get_iso8601_utc_from_epoch
#);

sub user_template_flds {
    my ($page_title) = @_;
    my $error_msg = session('error_msg');
    session 'error_msg' => "";
    return (
        user                    => session('user') || param('user'),
        tt_user_id_logged_in    => session('user_id'),
        tt_user_is_admin        => session('user_is_admin'),
        tt_user_fullname        => session('user_fullname'),
        error_msg               => $error_msg,
        page_title              => $page_title,
        dancer_base_url         => $DANCER_BASE_URL,
        return_url              => param('return_url'),
        redirect_url            => param('redir_url'),
    );
}

1;
