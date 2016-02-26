package Khaospy::Conf;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

# Reads in most of the confs once.
#
# Some confs are read in every once in a while,
# so they can change whilst the daemons are running.
#
# The rest of Khaospy should get to the confs from here.

use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    true false

    $HEATING_DAEMON_CONF_FULLPATH
    $HEATING_DAEMON_CONF_RELOAD_SECS

    $BOILERS_CONF_FULLPATH
    $GLOBAL_CONF_FULLPATH

);

use Khaospy::Utils;

our @EXPORT_OK = qw(
    get_one_wire_heating_control_conf
    get_boiler_conf
    get_global_conf
    get_conf
);

sub get_conf {
    my ($conf_rs, $conf_path, $force_reload, $validate_rc, $last_reload_rs, $reload_every ) = @_;

    die "get_conf: force_reload can only be true, false or undefined and not '$force_reload'\n"
        if defined $force_reload
            and $force_reload != true
            and $force_reload != false;

    if ( ! $$conf_rs || $force_reload
        || ( defined $last_reload_rs && defined $reload_every
            && $$last_reload_rs + $reload_every < time
        )
    ) {
        $$conf_rs = $JSON->decode(
             Khaospy::Utils::slurp( $conf_path )
        );

        $$last_reload_rs = time if defined $reload_every;

        $validate_rc->($$last_reload_rs) if defined $validate_rc;
    }
    return $$conf_rs;
}

my $heating_conf;
my $heating_conf_last_loaded;
sub get_one_wire_heating_control_conf {
    my ($force_reload) = @_;
    get_conf(
        \$heating_conf,
        $HEATING_DAEMON_CONF_FULLPATH,
        $force_reload,
        undef,
        \$$heating_conf_last_loaded,
        $HEATING_DAEMON_CONF_RELOAD_SECS
    )
}

my $boiler_conf;
sub get_boiler_conf {
    my ($force_reload) = @_;
    get_conf(\$boiler_conf, $BOILERS_CONF_FULLPATH, $force_reload);
}

my $global_conf;
sub get_global_conf {
    my ($force_reload) = @_;
    get_conf( \$global_conf, $GLOBAL_CONF_FULLPATH, $force_reload);
}

1;
