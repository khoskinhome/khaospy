#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::ControlUtils;
use Khaospy::MACSwitchDaemon;
use Khaospy::WebUI;
use Khaospy::WebUI::Admin::Controls;
use Khaospy::WebUI::Admin::UserRooms;
use Khaospy::WebUI::Admin::ControlRooms;
use Khaospy::WebUI::Admin::Users;
use Khaospy::WebUI::Admin::Rooms;
use Khaospy::WebUI::Admin;
use Khaospy::WebUI::DB;
use Khaospy::WebUI::User;
use Khaospy::WebUI::Util;
use Khaospy::WebUI::Constants;
use Khaospy::WebUI::SendMessage;
use Khaospy::WebUI::Status;
use Khaospy::WebUI::UserLogin;
use Khaospy::WebUI::Rooms;
use Khaospy::ControlsCurrentState;
use Khaospy::DBH::Controls;
use Khaospy::DBH::UserRooms;
use Khaospy::DBH::ControlRooms;
use Khaospy::DBH::Users;
use Khaospy::DBH::Rooms;
use Khaospy::RulesD;
use Khaospy::ErrorLogDaemon;
use Khaospy::Email;

use Khaospy::Conf;
use Khaospy::Conf::Global;
use Khaospy::Conf::Controls;
use Khaospy::Conf::PiHosts;
use Khaospy::Conf::HardCoded;

use Khaospy::Exception;

use Khaospy::Conf::Global;

use Khaospy::Constants;
use Khaospy::QueueCommand;

use Khaospy::BoilerDaemon;

use Khaospy::ControlOrviboS20;

use Khaospy::ControlDispatch;
use Khaospy::ControlOther;
use Khaospy::ControlPi;
use Khaospy::ControlPiGPIO;
use Khaospy::ControlPiMCP23017;

use Khaospy::DBH;

use Khaospy::HeatingDaemon;

use Khaospy::Log;

use Khaospy::Message;

use Khaospy::OneWireThermometer;

use Khaospy::OrviboS20;

use Khaospy::ControlsDaemon;
use Khaospy::CommandQueueDaemon;

use Khaospy::Utils;
use Khaospy::StatusD;

use Khaospy::ZMQSubscribeAllPublishers;
use Khaospy::ZMQAnyEvent;

use zhelpers;

say '';
say "$0 all modules got used okay";

#./install/lib-perl/t/KhaospyTest/PiGPIO.pm
#./install/lib-perl/t/KhaospyTest/PiMCP23017.pm

