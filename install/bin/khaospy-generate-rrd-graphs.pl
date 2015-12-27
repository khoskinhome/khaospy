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
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $KHAOSPY_RRD_DIR
    $KHAOSPY_RRD_IMAGE_DIR
);

my $json = JSON->new->allow_nonref;

my $thermometer_conf = $json->decode(
    slurp ( $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH )
);

print Dumper($thermometer_conf);

# TODO the Latitude and Longitude need to go into a central config :
my $LAT="51.6290100N";
my $LON="0.3584240E";

# Calculating Civil Twilight based on location from LAT LON
my $DUSKHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 45-46`;
my $DUSKMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 47-48`;
my $DAWNHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 30-31`;
my $DAWNMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 32-33`;

# Calculating sunset/sunrise based on location from LAT LON
my $SUNRISEHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 30-31`;
my $SUNRISEMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 32-33`;
my $SUNSETHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 45-46`;
my $SUNSETMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 47-48`;

# Converting to seconds
my $SUNR=($SUNRISEHR * 3600 + $SUNRISEMIN * 60);
my $SUNS=($SUNSETHR * 3600 + $SUNSETMIN * 60);
my $DUSK=($DUSKHR * 3600 + $DUSKMIN * 60);
my $DAWN=($DAWNHR * 3600 + $DAWNMIN * 60);

print "sunrise $SUNR : sunset $SUNS : dusk $DUSK : dawn $DAWN \n";

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
        { name => "4hours.png" , period =>'4h'  },
        { name => "day.png"    , period =>'1d'  },
        { name => "3days.png"  , period =>'3d'  },
        { name => "week.png"   , period =>'7d'  },
        { name => "2weeks.png" , period =>'14d' },
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

        $COMMENT_lines .= << "        EOCOMMENT";
            LINE$count:temp${count}$COLOURS->[$count-1]:'$line->{location_name}'
            COMMENT:' Last = '
            GPRINT:temp$count:LAST:'%5.1lf °C     '
            COMMENT:' Ave = '
            GPRINT:temp$count:AVERAGE:'%5.1lf °C\\l'
        EOCOMMENT
        $count ++ ;
    }

    my $cmd = <<"    EODAY";
        rrdtool graph $imgpath/$graph_name --start -$period --end now
        -v "Last day (°C)"
        --lower-limit=0
        --full-size-mode
        --width=1600 --height=900
        --slope-mode
        --color=SHADEA#9999CC
        --watermark="© khaos - 2015"
        $DEF_lines
        CDEF:trend3=temp1,21600,TREND
        CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF
        CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF
        AREA:nightplus#E0E0E0
        AREA:nightminus#E0E0E0
        CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF
        CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF
        AREA:dusktilldawn#CCCCCC
        AREA:dawntilldusk#CCCCCC
        COMMENT:'Dawn\\:    $DAWNHR\\:$DAWNMIN  Sunrise\\: $SUNRISEHR\\:$SUNRISEMIN\\l'
        COMMENT:'\\u'
        COMMENT:'Sunset\\:  $SUNSETHR\\:$SUNSETMIN  Dusk\\:    $DUSKHR\\:$DUSKMIN\\r'
        $COMMENT_lines
        HRULE:0#66CCFF:'freezing\\l'

    EODAY

    $cmd =~ s/\n//g;
    #print "\n\n$cmd\n\n";

    system($cmd);

}

