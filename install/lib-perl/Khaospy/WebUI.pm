package Khaospy::WebUI;
use strict; use warnings;

use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;

use Khaospy::WebUI::Rooms;
use Khaospy::WebUI::Status;
use Khaospy::WebUI::UserLogin;
use Khaospy::WebUI::User;
use Khaospy::WebUI::Admin;
use Khaospy::WebUI::Admin::Users;
use Khaospy::WebUI::Admin::UserRooms;
use Khaospy::WebUI::Admin::Rooms;
use Khaospy::WebUI::Admin::Controls;
use Khaospy::WebUI::Admin::ControlRooms;

1;
