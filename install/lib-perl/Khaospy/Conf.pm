package Khaospy::Conf;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2017

# Reads in most of the confs once.
#
# Some confs are read in every once in a while,
# so they can change whilst the daemons are running.
#
# The rest of Khaospy should get to the confs from here.

use Exporter qw/import/;
our @EXPORT_OK = qw(
    get_one_wire_heating_control_conf
    get_rulesd_conf
    get_boiler_conf
    get_database_conf
    get_email_conf
    get_conf
);



use Carp qw/confess croak/;
use Data::Dumper;

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    true false

    $HEATING_DAEMON_CONF_FULLPATH
    $HEATING_DAEMON_CONF_RELOAD_SECS

    $RULES_DAEMON_CONF_FULLPATH
    $RULES_DAEMON_RELOAD_SECS

    $BOILERS_CONF_FULLPATH
    $DATABASE_CONF_FULLPATH
    $EMAIL_CONF_FULLPATH
);

use Khaospy::Utils;

sub get_conf {
    my ($conf_rs, $conf_path, $force_reload, $validate_rc, $last_reload_rs, $reload_every ) = @_;

    die "get_conf: force_reload can only be true (1), false (0) or undefined and not '$force_reload'\n"
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

my $rules_conf;
my $rules_conf_last_loaded;
sub get_rulesd_conf {
    my ($force_reload) = @_;
    get_conf(
        \$rules_conf,
        $RULES_DAEMON_CONF_FULLPATH,
        $force_reload,
        undef,
        \$$rules_conf_last_loaded,
        $RULES_DAEMON_RELOAD_SECS
    )
}

my $boiler_conf;
sub get_boiler_conf {
    my ($force_reload) = @_;
    get_conf(\$boiler_conf, $BOILERS_CONF_FULLPATH, $force_reload);

    # TODO validate that a rad-control can only be used by one boiler-control

}

my $database_conf;
sub get_database_conf {
    my ($force_reload) = @_;
    get_conf( \$database_conf, $DATABASE_CONF_FULLPATH, $force_reload);
}

my $email_conf;
sub get_email_conf {
    my ($force_reload) = @_;
    get_conf( \$email_conf, $EMAIL_CONF_FULLPATH, $force_reload);
}

1;
