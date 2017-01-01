package Khaospy::WebUI::Admin::Controls;
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

use Khaospy::DBH::Controls qw(
    get_controls
);

use Khaospy::WebUI::Util qw(
    pop_error_msg
);

sub pop_error_msg  { Khaospy::WebUI::Util::pop_error_msg() };

##################
# admin controls :
get '/admin/list_controls'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_list_controls' => {
        page_title      => 'Admin : List Controls',
        user            => session('user'),
        list_controls   => get_controls(),
        error_msg       => pop_error_msg(),
    };
};

get '/admin/add_control'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'not_implemented' => {
        page_title      => 'Admin : Add Control',
        user            => session('user'),
        error_msg       => pop_error_msg(),
    };

#    return template 'admin_add_control' => {
#        page_title  => 'Admin : Add Control',
#        user        => session('user'),
#        error_msg   => pop_error_msg(),
#    };

};

post '/admin/add_control'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

#    my $add = {};
#    my $error ={};
#    my $error_msg = '';
#
#    for my $fld (qw( name tag )){
#        my $val = trim(param($fld));
#        next if ! defined $val;
#
#        $add->{$fld} = $val;
#        if ( ! controls_field_valid($fld, $add->{$fld}) ){
#            $error->{$fld} = controls_field_desc($fld);
#            $error_msg     = "field errors";
#        }
#    };
#
#    if ( $error_msg ){
#        session 'error_msg' => $error_msg;
#        return template 'admin_add_control' => {
#            page_title  => 'Admin : Add Control',
#            user        => session('user'),
#            error_msg   => pop_error_msg(),
#            add         => $add,
#            error       => $error,
#        };
#    }
#
#    try {
#        insert_control($add);
#    } catch {
#        $error_msg = "Error inserting into DB. $_";
#    };
#
#    return template 'admin_add_control' => {
#        page_title  => 'Admin : Add Control',
#        user        => session('user'),
#        error_msg   => $error_msg,
#        add         => $add,
#    } if $error_msg;
#
#    session 'error_msg' => "Control '$add->{control_name}' added";
    redirect uri_for('/admin/add_control', {});
    return;
};


1;
