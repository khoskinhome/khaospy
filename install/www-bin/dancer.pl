#!/usr/bin/perl
use strict; use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Try::Tiny;
use Data::Dumper;
use Dancer2;
use Dancer2::Plugin::Auth::Tiny;
use Khaospy::DBH qw(dbh);
use Khaospy::Conf::Controls qw(
    get_control_config
    get_status_alias
    can_operate
);

#install/lib-perl/Khaospy/Conf/Controls.pm:372:        try {

use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::QueueCommand qw/ queue_command /;

use Khaospy::Constants qw(
    $DANCER_BASE_URL
);

get '/' => needs login => sub {
    return template index => {};
};

get '/login' => sub {
    print STDERR "Generate Login Page\n";
    return template 'login' => { return_url => params->{return_url} };
};

post '/login' => sub {
    print STDERR "Posted to Login\n";
    my $user  = param('user');
    my $password  = param('password');
    my $redir_url = param('redirect_url') || '/';

    print STDERR " TESTING login criteria $redir_url\n";

    $user eq 'john' && $password eq 'let'
        or redirect $redir_url;

    print STDERR " PASSED login criteria\n";

    session 'user' => $user;
    #redirect '/status';
    redirect $redir_url;
};

post '/api/v1/operate/:control/:action' => sub {
#    session('user') or redirect('/login');

    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    my $control_name = params->{control};
    my $action       = params->{action};

    print STDERR "Post action to $control_name\n";

    my $ret = {};

    try {
        $ret = { msg => queue_command($control_name,$action) };
    } catch {
        status 'bad_request';
        return "Couldn't operate $control_name with action '$action'";
    };

    return to_json $ret;
};

get '/api/v1/status/:control' => sub {
#    session('user') or redirect('/login');
    my $stat = get_control_status(params->{control});

#    print STDERR "Get status for control ".params->{control}."\n";
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

get '/api/v1/statusall' => sub {
#    session('user') or redirect('/login');
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    my $stat = get_control_status();
    return to_json $stat;
};

get '/status' => sub {
#    session('user') or redirect('/login');
    return template 'status-new.tt', {
        DANCER_BASE_URL => $DANCER_BASE_URL,
        entries => get_control_status(),
    };
};

sub get_control_status {
    my ($control_name) = @_;

    my $control_select = '';

    my @bind_vals = ();
    if ( $control_name ) {
        $control_select = "where control_name = ?";
        push @bind_vals, $control_name;
    }

    my $sql = <<"    EOSQL";
    select control_name,
        request_time,
        current_state,
        current_value
    from control_status
    where id in
        ( select max(id)
            from control_status
            $control_select
            group by control_name )
    order by control_name;
    EOSQL

    my $sth = dbh->prepare($sql);
    $sth->execute(@bind_vals);

    my $results = [];
    while ( my $row = $sth->fetchrow_hashref ){

        my $control_name = get_hashval($row,'control_name');

        if ( defined $row->{current_value}){
            $row->{current_value}
                = sprintf('%+0.1f', $row->{current_value});
        }

        if ( defined $row->{current_state} ){
            $row->{status_alias} =
                get_status_alias(
                    $control_name, get_hashval($row, 'current_state')
                );
        }

        $row->{can_operate} = can_operate($control_name);

# TODO. therm sensors have a range. These need CONSTANTS and the therm-config to support-range.
#        $row->{in_range} = "too-low","correct","too-high"
# colours will be blue==too-cold, green=correct, red=too-high.

        $row->{current_state_value}
            = $row->{status_alias} || $row->{current_value} ;

        push @$results, $row;
    }

    return $results;
}

dance;

