package Khaospy::ControlUtils;
use strict;
use warnings;
# By Karl Kount-Khaos Hoskin. 2015-2016

use Exporter qw/import/;
use Time::HiRes qw(time);

use Khaospy::Constants qw(
    true false
);

use Khaospy::Utils qw ( get_hashval );

our @EXPORT_OK = qw(
    set_manual_auto_timeout
);

sub set_manual_auto_timeout {
    my ( $control, $pi_c_state, $use_field ) = @_;
    # sets the pi_c_state->{manual_auto_timeout_left}
    # also returns this value ( for ease of use );

    my $timeout = get_hashval($control, 'manual_auto_timeout',true,0,0);
    my $last_manual
        = get_hashval( $pi_c_state, $use_field, true, 0,0);
    my $timeout_left = ( $last_manual + $timeout ) - time;


    $timeout_left = $timeout_left > 0 ? $timeout_left : 0 ;
    $pi_c_state->{manual_auto_timeout_left} = $timeout_left;
    return $timeout_left;

}

1;



