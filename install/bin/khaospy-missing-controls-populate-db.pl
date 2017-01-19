#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Data::Dumper;

use Khaospy::DBH::Controls qw(
    get_controls
    control_status_insert
);

use Khaospy::Utils qw(
    get_hashval
    timestamp
    burp
    get_iso8601_utc_from_epoch
);

use Khaospy::Conf::Controls qw(
    get_control_config
    get_controls_conf
);

my $controls_from_db = { map { $_->{control_name} => $_ } @{get_controls()} };

my $controls_conf = get_controls_conf();

#print Dumper($controls_conf);

for my $control_name ( keys %$controls_conf ){
    if(  ! exists $controls_from_db->{$control_name}){
        print "DB missing $control_name\n";
#install/lib-perl/Khaospy/StatusD.pm:304:        control_status_insert( $record );

        my $record = {
            control_name  => $control_name,
            control_type  => $controls_conf->{$control_name}{type},
            current_value => $controls_conf->{$control_name}{value} || 0,
            last_change_state_time => get_iso8601_utc_from_epoch(time) ,
            last_change_state_by => "insert-script",
            request_time => get_iso8601_utc_from_epoch(time),
        };
        control_status_insert( $record );

        print Dumper ($record);
    }
}

for my $lcsk ( keys %$controls_from_db  ){
    if ( ! $controls_from_db->{$lcsk}{control_type} ){
        print "DB control $lcsk doesn't have a control_type\n";


    }
}

exit 0;
