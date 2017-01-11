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

use Khaospy::WebUI::Util; # can't import.
sub user_template_flds { Khaospy::WebUI::Util::user_template_flds(@_) };

##################
# admin controls :
get '/admin/list_controls'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    return template 'admin_list_controls' => {
        user_template_flds('Admin : List Controls'),
        list_controls   => get_controls(),
    };
};

get '/admin/add_control'  => needs login => sub {
    redirect '/admin' if ! session->read('user_is_admin');

    #return template 'admin_add_control' => {
    return template 'not_implemented' => {
        user_template_flds('Admin : Add Control'),
    };
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
            #user_template_flds('Admin : Add Control'),
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
