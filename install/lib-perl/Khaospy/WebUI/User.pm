package Khaospy::WebUI::User;
use strict; use warnings;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

get '/user' => needs login => sub {

#    redirect '/' if session('user');
    return template 'user' => {
        page_title      => 'User',
        user            => session('user'),
    };
};

get '/user/update'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone
    # warning that giving an invalid email address will require an admin user to fix it. especially if they want to change their password.



};

post '/user/update'  => needs login => sub {
    # for non-admin users to update details
    # name, email, mobile_phone


};


1;
