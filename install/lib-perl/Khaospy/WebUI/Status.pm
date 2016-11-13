package Khaospy::WebUI::Status;
use strict; use warnings;

use Try::Tiny;
use Data::Dumper;
use DateTime;
use Dancer2 appname => 'Khaospy::WebUI';
use Dancer2::Core::Request;
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Session::Memcached;


use Khaospy::QueueCommand qw/ queue_command /;


use Khaospy::DBH::Controls qw(
    get_controls_from_db
);

use Khaospy::WebUI::Constants qw(
    $DANCER_BASE_URL
);

use Khaospy::Constants qw(
    true false
);

post '/api/v1/operate/:control/:action'  => needs login => sub {

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    my $control_name = params->{control};
    my $action       = params->{action};

    my $ret = {};

    try {
        # TODO this needs to have a timeout :
        $ret = { msg => queue_command($control_name,$action) };
    } catch {
        status 'bad_request';
        $ret = "Couldn't operate $control_name with action '$action'";
    };

    return $ret if ref $ret ne 'HASH';
    return to_json $ret;
};

get '/api/v1/status/:control' => needs login => sub {
    my $stat = get_controls_from_db(params->{control});

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    if ( ! scalar @$stat ){
        status 'not_found';
        return "Control doesn't exist";
    }

    if ( scalar @$stat > 1 ){
        status 'bad_request';
        return "More than one control";
    }

    return to_json $stat->[0];
};

get '/api/v1/statusall' => needs login => sub {
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    my $stat = get_controls_from_db();
    return to_json $stat;
};

get '/status'  => needs login => sub {
    return template 'status.tt', {
        page_title      => 'Status',
        user            => session('user'),
#        DANCER_BASE_URL => $DANCER_BASE_URL,
        entries         => get_controls_from_db(),
    };
};

get '/cctv'  => needs login => sub {
    return template 'cctv.tt', {
        page_title      => 'CCTV',
        user            => session('user'),
#        DANCER_BASE_URL => $DANCER_BASE_URL,
        entries         => get_controls_from_db(),
    };
};

1;
