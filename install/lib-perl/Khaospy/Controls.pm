package Khaospy::Controls;
use strict;
use warnings;

use Carp qw/croak/;
use Data::Dumper;
use Exporter qw/import/;
use JSON;
my $json = JSON->new->allow_nonref;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    $KHAOSPY_CONTROLS_CONF_FULLPATH
    $KHAOSPY_HEATING_THERMOMETER_CONF
);

use Khaospy::Utils qw(
    slurp
);

use Khaospy::OrviboS20 qw/signal_control/;

our @EXPORT_OK = qw(
    send_command
);

my $control_types = {
    orvibos20    => \&_orvibo_command,
    picontroller => \&_picontroller_command,
};

my $controls = $json->decode(
    slurp ( $KHAOSPY_CONTROLS_CONF_FULLPATH )
);

sub send_command {
    # sends an "action" to a "named" control.

    my ($control_name, $action) = @_;

    if ( ! exists $controls->{$control_name} ){
        croak "ERROR in config. Control '$control_name' "
            ."doesn't exist in $KHAOSPY_CONTROLS_CONF_FULLPATH\n"
            ."(this could be a misconfig in $KHAOSPY_HEATING_THERMOMETER_CONF )\n";
    }

    my $control = $controls->{$control_name};

    if ( ! exists $control->{type} ){
        croak "ERROR in config. Control '$control_name' doesn't have a 'type' key\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    my $type = lc($control->{type});

    if ( ! exists $control_types->{$type} ){
        croak "ERROR in config. Control '$control_name' has an invalid 'type' of $type\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    return $control_types->{$type}($control, $control_name, $action);

}

sub _orvibo_command {
    my ( $control, $control_name, $action ) = @_;

    print "Khaospy::Controls run orviboS20 command '$control_name $action'\n";

    if ( ! exists $control->{host} ){
        croak "ERROR in config. Control '$control_name' doesn't have a 'host' configured\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    if ( ! exists $control->{mac} ){
        croak "ERROR in config. Control '$control_name' doesn't have a 'mac' configured\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    return signal_control( $control->{host} , $control->{mac}, $action );

}

sub _picontroller_command {
    my ( $control, $control_name, $action ) = @_;

    print "Khaospy::Controls PRETEND RUN PICONTROLLER COMMAND $control_name $action\n";
    print "picontroller_command not yet implemented\n";

    return "the status of the command";
}

1;
