package Khaospy::Conf::Global;
use strict; use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2017

use Exporter qw/import/;
our @EXPORT_OK = qw(
    get_global_conf
    gc_TEMP_RANGE_DEG_C
);

# Things will migrate from Constants to here,
# if they are settable in the global-conf.

use Khaospy::Constants qw(
    $JSON
    $GLOBAL_CONF_FULLPATH

);

use Khaospy::Conf qw(get_conf);

my $global_conf;

sub get_global_conf {
    my ($force_reload) = @_;
    get_conf( \$global_conf, $GLOBAL_CONF_FULLPATH, $force_reload);
}

get_global_conf();
#######################

sub gc_TEMP_RANGE_DEG_C {
    # This is the default range between the upper and lower temperatures
    # This is used in the webui for displaying too-cold, just-right and too-hot
    # It is also used by the rules for switching on and off heating devices.
    # Also one-wire-therm-controls can have this set on an individual basis,
    # via another control.
    # ( the control setting will take precedence over this )
    $global_conf->{temp_range_deg_c} || 1;
}





1;
