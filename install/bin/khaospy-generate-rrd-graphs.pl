#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use JSON;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw/slurp/;
use Khaospy::Constants qw(
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    $KHAOSPY_RRD_DIR
    $KHAOSPY_RRD_IMAGE_DIR
);

my $json = JSON->new->allow_nonref;

my $thermometer_conf = $json->decode(
    slurp ( $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH )
);

my $COLOURS = [
    my $RAWCOLOUR="#FF9933",
    my $RAWCOLOUR2="#0033FF",
    my $RAWCOLOUR3="#FF00FF",
    my $RAWCOLOUR4="#336633",
    my $RAWCOLOUR5="#663333",
    my $RAWCOLOUR6="#66FF00",
    my $RAWCOLOUR7="#993366",
    my $RAWCOLOUR8="#339966",
    my $RAWCOLOUR9="#00ff33"
];

my $TRENDCOLOUR="#FFFF00",

my $rrd_groups = { all => [] };

chdir $KHAOSPY_RRD_DIR;

while ( <*> ){
    my $address   = $_;
    my $name      = $thermometer_conf->{$address}{name};
    my $rrd_group = $thermometer_conf->{$address}{rrd_group};

    print "$address name => $address : rrd_group => $rrd_group \n";

    my $imgpath="$KHAOSPY_RRD_IMAGE_DIR/$address-$name";
    mkdir $imgpath if ( ! -d $imgpath );

    $rrd_groups->{$rrd_group} = [] if ! exists $rrd_groups->{$rrd_group};

    my $this_g = {
            rrdpath_n_file => "$KHAOSPY_RRD_DIR/$address",
            location_name => $name,
        };

    push @{$rrd_groups->{$rrd_group}}, $this_g;
    push @{$rrd_groups->{all}}, $this_g;

    graph_periods($imgpath, [ $this_g ] );

}

print "\n";

for my $tgrp ( keys %$rrd_groups ){
    print "rrd_group $tgrp\n";

    my $imgpath="$KHAOSPY_RRD_IMAGE_DIR/$tgrp";
    mkdir $imgpath if ! -d $imgpath ;

    # multi_graph_day( $imgpath, "day", "1d", $rrd_groups->{$tgrp} );

    graph_periods($imgpath,$rrd_groups->{$tgrp});

}

########################################################################

sub graph_periods {
    my ($imgpath, $p ) = @_ ;

    print "graph_periods imgpath=$imgpath :\n".Dumper($p);

    my $periods = [
        { name => "4Hours.png"   , period =>'4h'  },
        { name => "Day.png"      , period =>'1d'  },
        { name => "2Days.png"    , period =>'2d'  },
        { name => "4Days.png"    , period =>'4d'  },
        { name => "Week.png"     , period =>'7d'  },
        { name => "2Weeks.png"   , period =>'14d' },
        { name => "Month.png"    , period =>'1m'  },
        { name => "Quarter.png"  , period =>'3m'  },
        { name => "6Months.png"  , period =>'6m'  },
        { name => "Year.png"     , period =>'1y'  },
        #{ name => "2years.png"   , period =>'2y'  },
    ];

    for my $t_p ( @$periods ) {
        multi_graph_day( $imgpath, $t_p->{name}, $t_p->{period} ,$p );
    };
}

sub multi_graph_day {
    my ($imgpath, $graph_name, $period, $p ) = @_ ;

    my $DEF_lines = '';
    my $COMMENT_lines = '';
    my $count = 1;

    my @sorted_p = sort { $a->{location_name} cmp $b->{location_name} } @$p;

    for my $line ( @sorted_p ){
        $DEF_lines .= "DEF:temp$count=$line->{rrdpath_n_file}:a:AVERAGE  ";

        my $padded_location_name
            = $line->{location_name} . ( " " x ( 20 - length $line->{location_name} ) );

        $COMMENT_lines .= << "        EOCOMMENT";
            LINE$count:temp${count}$COLOURS->[$count-1]:'$padded_location_name'
            COMMENT:' Min ='
            GPRINT:temp$count:MIN:'%2.1lf °C '
            COMMENT:' Max ='
            GPRINT:temp$count:MAX:'%2.1lf °C '
            COMMENT:' Ave ='
            GPRINT:temp$count:AVERAGE:'%2.1lf °C '
            COMMENT:' Last ='
            GPRINT:temp$count:LAST:'%2.1lf °C\\l'
        EOCOMMENT
        $count ++ ;
    }

    my $sun_config = '' ;

    if ( $period =~ /[dh]$/ ){
        $sun_config=rrd_sun_config();
    }

    my $vertical_title = $graph_name;
    $vertical_title =~ s/\.png$//;
    $vertical_title =~ s/(\d+)(.*)/\1 \2/;

    my $lc_graph_name = lc $graph_name;

    my $cmd = <<"    EODAY";
        rrdtool graph $imgpath/$lc_graph_name --start -$period --end now
        -v "$vertical_title (°C)"
        --lower-limit=0
        --full-size-mode
        --width=1200 --height=800
        --slope-mode
        --color=SHADEA#9999CC
        --watermark="© khaos - 2015"
        $DEF_lines
        CDEF:trend3=temp1,21600,TREND
        $sun_config
        $COMMENT_lines
        HRULE:0#66CCFF:'freezing\\l'
    EODAY

    $cmd =~ s/\n//g;
    #print "\n\n$cmd\n\n";

    system($cmd);

}

{
    my $sun_config;

    sub rrd_sun_config {

        return $sun_config if $sun_config;

        my $SUN;
        eval { $SUN = sunrise_dawn_n_dusk(); };

        return "" if $@;

        $sun_config = <<"        EOSUNCFG";

            CDEF:nightplus=LTIME,86400,%,$SUN->{sun_rise_epoch_secs},LT,INF,LTIME,86400,%,$SUN->{sun_set_epoch_secs},GT,INF,UNKN,temp1,*,IF,IF
            CDEF:nightminus=LTIME,86400,%,$SUN->{sun_rise_epoch_secs},LT,NEGINF,LTIME,86400,%,$SUN->{sun_set_epoch_secs},GT,NEGINF,UNKN,temp1,*,IF,IF
            AREA:nightplus#E0E0E0
            AREA:nightminus#E0E0E0
            CDEF:dusktilldawn=LTIME,86400,%,$SUN->{dawn_epoch_secs},LT,INF,LTIME,86400,%,$SUN->{dusk_epoch_secs},GT,INF,UNKN,temp1,*,IF,IF
            CDEF:dawntilldusk=LTIME,86400,%,$SUN->{dawn_epoch_secs},LT,NEGINF,LTIME,86400,%,$SUN->{dusk_epoch_secs},GT,NEGINF,UNKN,temp1,*,IF,IF
            AREA:dusktilldawn#CCCCCC
            AREA:dawntilldusk#CCCCCC
            COMMENT:'Dawn\\:    $SUN->{dawn_hour}\\:$SUN->{dawn_min}  Sunrise\\: $SUN->{sun_rise_hour}\\:$SUN->{sun_rise_min}\\l'
            COMMENT:'\\u'
            COMMENT:'Sunset\\:  $SUN->{sun_set_hour}\\:$SUN->{sun_set_min}  Dusk\\:    $SUN->{dusk_hour}\\:$SUN->{dusk_min}\\r'

        EOSUNCFG

        return $sun_config;
    };
}

sub sunrise_dawn_n_dusk {

    my $sunwait_cmd = "/usr/bin/sunwait";

    if ( ! -f $sunwait_cmd ){
        die "$sunwait_cmd is not installed. Cannot show sunrise and sunset in graphs \n";
    }

    # TODO the Latitude and Longitude need to go into a central config :
    my $LAT="51.6290100N";
    my $LON="0.3584240E";

    # Calculating Civil Twilight based on location from LAT LON
    my $dusk_hour=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 45-46`;
    my $dusk_min=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 47-48`;
    my $dawn_hour=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 30-31`;
    my $dawn_min=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 32-33`;

    # Calculating sunset/sunrise based on location from LAT LON
    my $sun_rise_hour=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 30-31`;
    my $sun_rise_min=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 32-33`;
    my $sun_set_hour=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 45-46`;
    my $sun_set_min=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 47-48`;

    # print "sunrise $SUNR : sunset $SUNS : dusk $DUSK : dawn $DAWN \n";

    return {
        dawn_hour           => $dawn_hour,
        dawn_min            => $dawn_min,
        dawn_epoch_secs     => ($dawn_hour * 3600 + $dawn_min * 60),

        sun_rise_hour       => $sun_rise_hour,
        sun_rise_min        => $sun_rise_min,
        sun_rise_epoch_secs => ($sun_rise_hour * 3600 + $sun_rise_hour * 60),

        sun_set_hour        => $sun_set_hour,
        sun_set_min         => $sun_set_min,
        sun_set_epoch_secs  => ($sun_set_hour * 3600 + $sun_set_min * 60),

        dusk_hour           => $dusk_hour,
        dusk_min            => $dusk_min,
        dusk_epoch_secs     => ($dusk_hour * 3600 + $dusk_min * 60),
    };
}
