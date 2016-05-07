#!/usr/bin/perl
use strict; use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Data::Dumper;
use Dancer2;
use Khaospy::DBH qw(dbh);
use Khaospy::Conf::Controls qw(
    get_status_alias
);

use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::Constants qw(
    $DANCER_BASE_URL
);

get '/api/v1/status/:control' => sub {
    my $stat = get_control_status(params->{control});

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
    header( 'Content-Type'  => 'application/json' );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

    my $stat = get_control_status();
    return to_json $stat;
};

get '/status' => sub {
    return template 'status.tt', {
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

        if ( defined $row->{current_value}){
            $row->{current_value}
                = sprintf('%+0.1f', $row->{current_value});
        } else {
            $row->{current_state} =
                get_status_alias(
                    get_hashval($row,'control_name'),$row->{current_state}
                );
        }

        $row->{current_state_value}
            = $row->{current_state} || $row->{current_value} ;

        push @$results, $row;
    }

    return $results;
}

dance;

