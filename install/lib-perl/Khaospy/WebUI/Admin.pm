package Khaospy::WebUI::Admin;
use strict; use warnings;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

get '/admin' => needs login => sub {

#    redirect '/' if session('user');
    return template 'admin' => {
        page_title      => 'Admin',
        user            => session('user'),
    };
};

get '/admin/user_update_create'  => needs login => sub {
    # for non-admin users to update details
    # username, name, email, mobile_phone is_api_user is_admin can_remote
    # password
    # needs to check the current logged in user is_admin=true


};

post '/admin/user_update_create'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone
    # needs to check the current logged in user is_admin=true


};


1;
