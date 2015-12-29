package Khaospy::Utils;
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
    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    $KHAOSPY_ONE_WIRED_SENDER_SCRIPT

    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $KHAOSPY_CONTROLS_CONF_FULLPATH
);

use Khaospy::Conf qw(
    get_heating_thermometer_conf
    get_controls_conf
);

our @EXPORT_OK = qw(
    slurp
    burp
    get_one_wire_sender_hosts
    get_controls_for_boiler
    get_hashval
);


sub slurp {
    my ( $file ) = @_;
    open( my $fh, $file ) or die "Can't open file $file $!\n";
    my $text = do { local( $/ ) ; <$fh> } ;
    return $text;
}

sub burp {
    my( $file_name ) = shift ;
    open( my $fh, ">" , $file_name ) || die "Can't create $file_name $!" ;
    print $fh @_ ;
}

sub get_one_wire_sender_hosts {

    my $daemon_runner_conf = $json->decode(
        slurp ( $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH )
    );

    my $one_wire_sender_host = [];
    for my $host ( keys %$daemon_runner_conf ){

        print "get_one_wire_sender_hosts host = $host \n";

        push @$one_wire_sender_host, $host
            if (
                grep { $_ =~ /^$KHAOSPY_ONE_WIRED_SENDER_SCRIPT/ }
                @{$daemon_runner_conf->{$host}}
            );
    }

    my %ret = map { $_ => 1 } @$one_wire_sender_host ;
    return keys %ret ;
}

sub get_controls_for_boiler {
    # goes through the heating_thermometer_conf, and returns
    # a list of control_names that need to operate the "boiler".

    my $heating_thermometer_conf = get_heating_thermometer_conf();
    my $controls_conf = get_controls_conf();

    my $check_controls_conf = sub {
        my ($control_name) = @_;
        return $control_name
            if exists $controls_conf->{$control_name};

        croak "ERROR in config. heating_thermometer control '$control_name' doesn't exist in the controls config\n"
                ."   check the configs :\n"
                ."       $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH\n"
                ."       $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    };

    return [
        map { $check_controls_conf->($heating_thermometer_conf->{$_}{control}) }
        grep {
            exists $heating_thermometer_conf->{$_}{boiler}
            && $heating_thermometer_conf->{$_}{boiler}
        }
        keys %$heating_thermometer_conf
    ];

}

sub get_hashval {
    my ($hash, $key, $allow_undef) = @_;

    die "key '$key' not in HASH\n"
        if ! exists $hash->{key};

    die "key '$key' is not defined in HASH"
        if ! $allow_undef and ! defined $hash->{$key};

    return $hash->{$key};
}

1;
