#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;

my $rrdpath          = "/opt/khaospy/rrd";
my $rrdimgpath       = "/opt/khaospy/rrdimg";
my $rrdimgpath_group = "/opt/khaospy/rrdimg-group";

# mkdir $rrdimgpath if ( ! -d $rrdimgpath )

chdir $rrdpath;

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

my $address_map = {
    '28-0000066ebc74' => {
        name  => 'Alison',
        group => 'upstairs',
    },
    '28-000006e04e8b' => {
        name  => 'playhouse-tv',
        group => 'outside',
    },
    '28-0000066fe99e' => {
        name  => 'playhouse-9e-door',
        group => 'outside',
    },
    '28-00000670596d' => {
        name  => 'Bathroom',
        group => 'upstairs',
    },
    '28-021463277cff' => {
        name  => 'Loft',
        group => 'upstairs',
    },
    '28-0214632d16ff' => {
        name  => 'Amelia',
        group => 'upstairs',
    },
    '28-021463423bff' => {
        name  => 'Upstairs-Landing',
        group => 'upstairs',
    },
};


my $groups = { all => [] };

while ( <*> ){
    my $address = $_;
    my $name    = $address_map->{$address}{name};
    my $group   = $address_map->{$address}{group};

    print "$address name => $address : group => $group \n";

    my $imgpath="$rrdimgpath/$address-$name";
    mkdir $imgpath if ( ! -d $imgpath );

    $groups->{$group} = [] if ! exists $groups->{$group};

    my $this_g = {
            rrdpath_n_file => "$rrdpath/$address",
            location_name => $name,
        };

    push @{$groups->{$group}}, $this_g;
    push @{$groups->{all}}, $this_g;

    graph_periods($imgpath, [ $this_g ] );

}

print "\n";

for my $tgrp ( keys %$groups ){
    print "group $tgrp\n";

    my $imgpath="$rrdimgpath/$tgrp";
    mkdir $imgpath if ! -d $imgpath ;

    # multi_graph_day( $imgpath, "day", "1d", $groups->{$tgrp} );

    graph_periods($imgpath,$groups->{$tgrp});

}


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
    #my ($imgpath,$rrdpath,$rrdfile, $location_name, $graph_name, $period) = @_;

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


sub graph_day {

    my ($imgpath,$rrdpath,$rrdfile, $location_name, $graph_name, $period) = @_;

    my $cmd = <<"    EODAY";
        rrdtool graph $imgpath/$graph_name --start -$period --end now
        -v "Last day (°C)"
        --lower-limit=0
        --full-size-mode
        --width=1024 --height=768
        --slope-mode
        --color=SHADEA#9999CC
        --watermark="© khaos - 2015"
        DEF:temp1=$rrdpath/$rrdfile:a:AVERAGE
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
        LINE1:temp1$RAWCOLOUR:'$location_name'
        COMMENT:' Last = '
        GPRINT:temp1:LAST:'%5.1lf °C     '
        COMMENT:' Ave = '
        GPRINT:temp1:AVERAGE:'%5.1lf °C\\l'
        HRULE:0#66CCFF:'freezing\\l'

    EODAY

    $cmd =~ s/\n//g;
    #print "\n\n$cmd\n\n";

    system($cmd);

}


#        rrdtool graph $imgpath/day.png --start -1d --end now
#        -v "Last day (°C)"
#        --lower-limit=0
#        --full-size-mode
#        --width=700 --height=400
#        --slope-mode
#        --color=SHADEA#9999CC
#        --watermark="© khaos - 2015"
#        DEF:temp1=$rrdpath/$rrdfile:a:AVERAGE
#        CDEF:trend3=temp1,21600,TREND
#        CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF
#        CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF
#        AREA:nightplus#E0E0E0
#        AREA:nightminus#E0E0E0
#        CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF
#        CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF
#        AREA:dusktilldawn#CCCCCC
#        AREA:dawntilldusk#CCCCCC
#        COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN  Sunrise\: $SUNRISEHR\:$SUNRISEMIN\l"
#        COMMENT:"\u"
#        COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN  Dusk\:    $DUSKHR\:$DUSKMIN\r"
#        LINE1:temp1$RAWCOLOUR:"$location_name"
#        COMMENT:" Last = "
#        GPRINT:temp1:LAST:"%5.1lf °C     "
#        COMMENT:" Ave = "
#        GPRINT:temp1:AVERAGE:"%5.1lf °C\l"
#        HRULE:0#66CCFF:"freezing\l"
#


#    rrdtool graph $IMGPATH/day.png --start -1d --end now \
#    -v "Last day (°C)" \
#    --full-size-mode \
#    --width=700 --height=400 \
#    --slope-mode \
#    --color=SHADEA#9999CC \
#    --watermark="© khaos - 2015" \
#    DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
#    DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
#    DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
#    DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
#    DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
#    CDEF:trend1=temp4,21600,TREND \
#    CDEF:trend2=temp5,21600,TREND \
#    CDEF:trend3=temp1,21600,TREND \
#    CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
#    CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
#    AREA:nightplus#E0E0E0 \
#    AREA:nightminus#E0E0E0 \
#    CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
#    CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
#    AREA:dusktilldawn#CCCCCC \
#    AREA:dawntilldusk#CCCCCC \
#    COMMENT:"  Location         Last        Avg\l" \
#    LINE2:temp2$RAWCOLOUR2:"b" \
#    GPRINT:temp2:LAST:"%5.1lf °C" \
#    GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
#    COMMENT:"\t\t\t\t\t\t---------------------------\l" \
#    LINE2:temp4$RAWCOLOUR4:"d" \
#    GPRINT:temp4:LAST:"%5.1lf °C" \
#    GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
#    COMMENT:"\u" \
#    COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN\r" \
#    LINE1:temp5$RAWCOLOUR5:"e" \
#    GPRINT:temp5:LAST:"%5.1lf °C" \
#    GPRINT:temp5:AVERAGE:"%5.1lf °C\l" \
#    COMMENT:"\u" \
#    COMMENT:"Sunrise\: $SUNRISEHR\:$SUNRISEMIN\r" \
#    LINE1:temp1$RAWCOLOUR:"a" \
#    GPRINT:temp1:LAST:"%5.1lf °C" \
#    GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
#    COMMENT:"\u" \
#    COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN\r" \
#    LINE1:temp3$RAWCOLOUR3:"c" \
#    GPRINT:temp3:LAST:"%5.1lf °C" \
#    GPRINT:temp3:AVERAGE:"%5.1lf °C\l" \
#    COMMENT:"\u" \
#    COMMENT:"Dusk\:    $DUSKHR\:$DUSKMIN\r" \
#    HRULE:0#66CCFF:"freezing\l"
#


#    my $linkpath = $rrdimgpath."/".lc($address_map->{$_});
#    if ( ! -l $linkpath ) {
#        system("ln -s $path $linkpath");
#    }

##!/bin/bash
#
## original code by https://weather.bartbania.com/bash.txt
#############################
##
## Parameters to adjust
##
#############################
#
#RRDPATH="/home/khoskin/temperature-monitor/rrddb/"
#IMGPATH="/home/khoskin/temperature-monitor/img/"
#
#RRDFILE="temperature.rrd"
#LAT="51.6290100N"
#LON="0.3584240E"
#
## Graph Colors
#RAWCOLOUR="#FF9933"
#RAWCOLOUR2="#0000FF"
#RAWCOLOUR3="#336699"
#RAWCOLOUR4="#006600"
#RAWCOLOUR5="#000000"
#TRENDCOLOUR="#FFFF00"
#
## Calculating Civil Twilight based on location from LAT LON
#DUSKHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 45-46`
#DUSKMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 47-48`
#DAWNHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 30-31`
#DAWNMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 32-33`
#
## Calculating sunset/sunrise based on location from LAT LON
#SUNRISEHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 30-31`
#SUNRISEMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 32-33`
#SUNSETHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 45-46`
#SUNSETMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 47-48`
#
## Converting to seconds
#SUNR=$(($SUNRISEHR * 3600 + $SUNRISEMIN * 60))
#SUNS=$(($SUNSETHR * 3600 + $SUNSETMIN * 60))
#DUSK=$(($DUSKHR * 3600 + $DUSKMIN * 60))
#DAWN=$(($DAWNHR * 3600 + $DAWNMIN * 60))
#
#############################
##
## Creating graphs
##
#############################
##hour
#rrdtool graph $IMGPATH/hour.png --start -6h --end now \
#-v "Last 6 hours (°C)" \
#--full-size-mode \
#--width=700 --height=400 \
#--slope-mode \
#--color=SHADEB#9999CC \
#--watermark="© khaos - 2015" \
#DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
#DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
#DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
#DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
#DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
#CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
#CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
#AREA:nightplus#E0E0E0 \
#AREA:nightminus#E0E0E0 \
#CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
#CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
#AREA:dusktilldawn#CCCCCC \
#AREA:dawntilldusk#CCCCCC \
#COMMENT:"  Location         Last        Avg\l" \
#LINE2:temp2$RAWCOLOUR2:"b" \
#GPRINT:temp2:LAST:"%5.1lf °C" \
#GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\t\t\t\t\t\t---------------------------\l" \
#LINE2:temp4$RAWCOLOUR4:"d" \
#GPRINT:temp4:LAST:"%5.1lf °C" \
#GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN\r" \
#LINE1:temp5$RAWCOLOUR5:"e" \
#GPRINT:temp5:LAST:"%5.1lf °C" \
#GPRINT:temp5:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Sunrise\: $SUNRISEHR\:$SUNRISEMIN\r" \
#LINE1:temp1$RAWCOLOUR:"a" \
#GPRINT:temp1:LAST:"%5.1lf °C" \
#GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN\r" \
#LINE1:temp3$RAWCOLOUR3:"c" \
#GPRINT:temp3:LAST:"%5.1lf °C" \
#GPRINT:temp3:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Dusk\:    $DUSKHR\:$DUSKMIN\r" \
#HRULE:0#66CCFF:"freezing\l"
#
##day
#rrdtool graph $IMGPATH/day.png --start -1d --end now \
#-v "Last day (°C)" \
#--full-size-mode \
#--width=700 --height=400 \
#--slope-mode \
#--color=SHADEA#9999CC \
#--watermark="© khaos - 2015" \
#DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
#DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
#DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
#DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
#DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
#CDEF:trend1=temp4,21600,TREND \
#CDEF:trend2=temp5,21600,TREND \
#CDEF:trend3=temp1,21600,TREND \
#CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
#CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
#AREA:nightplus#E0E0E0 \
#AREA:nightminus#E0E0E0 \
#CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
#CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
#AREA:dusktilldawn#CCCCCC \
#AREA:dawntilldusk#CCCCCC \
#COMMENT:"  Location         Last        Avg\l" \
#LINE2:temp2$RAWCOLOUR2:"b" \
#GPRINT:temp2:LAST:"%5.1lf °C" \
#GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\t\t\t\t\t\t---------------------------\l" \
#LINE2:temp4$RAWCOLOUR4:"d" \
#GPRINT:temp4:LAST:"%5.1lf °C" \
#GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN\r" \
#LINE1:temp5$RAWCOLOUR5:"e" \
#GPRINT:temp5:LAST:"%5.1lf °C" \
#GPRINT:temp5:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Sunrise\: $SUNRISEHR\:$SUNRISEMIN\r" \
#LINE1:temp1$RAWCOLOUR:"a" \
#GPRINT:temp1:LAST:"%5.1lf °C" \
#GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN\r" \
#LINE1:temp3$RAWCOLOUR3:"c" \
#GPRINT:temp3:LAST:"%5.1lf °C" \
#GPRINT:temp3:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#COMMENT:"Dusk\:    $DUSKHR\:$DUSKMIN\r" \
#HRULE:0#66CCFF:"freezing\l"
#
##week
#rrdtool graph $IMGPATH/week.png --start -1w \
#--full-size-mode \
#-v "Last week (°C)" \
#--width=700 --height=400 \
#--slope-mode \
#--color=SHADEB#9999CC \
#--watermark="© khaos - 2015" \
#DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
#DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
#DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
#DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
#DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
#CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
#CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
#AREA:nightplus#E0E0E0 \
#AREA:nightminus#E0E0E0 \
#CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
#CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
#AREA:dusktilldawn#CCCCCC \
#AREA:dawntilldusk#CCCCCC \
#COMMENT:"  Location         Last        Avg\l" \
#COMMENT:"\u" \
#COMMENT:"Location         Last        Avg  \r" \
#LINE2:temp2$RAWCOLOUR2:"b" \
#GPRINT:temp2:LAST:"%5.1lf °C" \
#GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\t\t\t\t\t\t---------------------------\l" \
#LINE2:temp4$RAWCOLOUR4:"d" \
#GPRINT:temp4:LAST:"%5.1lf °C" \
#GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#LINE1:temp5$RAWCOLOUR5:"e" \
#GPRINT:temp5:LAST:"%5.1lf °C" \
#GPRINT:temp5:AVERAGE:"%5.1lf °C\r" \
#LINE1:temp1$RAWCOLOUR:"a" \
#GPRINT:temp1:LAST:"%5.1lf °C" \
#GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#LINE1:temp3$RAWCOLOUR3:"c" \
#GPRINT:temp3:LAST:"%5.1lf °C" \
#GPRINT:temp3:AVERAGE:"%5.1lf °C\r" \
#HRULE:0#66CCFF:"freezing\l"
#
##month
#rrdtool graph $IMGPATH/month.png --start -1m \
#-v "Last month (°C)" \
#--full-size-mode \
#--width=700 --height=400 \
#--slope-mode \
#--color=SHADEA#9999CC \
#--watermark="© khaos - 2015" \
#DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
#DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
#DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
#DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
#DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
#COMMENT:"  Location         Last        Avg\l" \
#COMMENT:"\u" \
#COMMENT:"Location         Last        Avg  \r" \
#LINE2:temp2$RAWCOLOUR2:"b" \
#GPRINT:temp2:LAST:"%5.1lf °C" \
#GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\t\t\t\t\t\t---------------------------\l" \
#LINE2:temp4$RAWCOLOUR4:"d" \
#GPRINT:temp4:LAST:"%5.1lf °C" \
#GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#LINE1:temp5$RAWCOLOUR5:"e" \
#GPRINT:temp5:LAST:"%5.1lf °C" \
#GPRINT:temp5:AVERAGE:"%5.1lf °C\r" \
#LINE1:temp1$RAWCOLOUR:"a" \
#GPRINT:temp1:LAST:"%5.1lf °C" \
#GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#LINE1:temp3$RAWCOLOUR3:"c" \
#GPRINT:temp3:LAST:"%5.1lf °C" \
#GPRINT:temp3:AVERAGE:"%5.1lf °C\r" \
#HRULE:0#66CCFF:"freezing\l"
#
##year
#rrdtool graph $IMGPATH/year.png --start -1y \
#--full-size-mode \
#-v "Last year (°C)" \
#--width=700 --height=400 \
#--color=SHADEB#9999CC \
#--slope-mode \
#--watermark="© khaos - 2015" \
#DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
#DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
#DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
#DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
#DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
#COMMENT:"  Location         Last        Avg\l" \
#COMMENT:"\u" \
#COMMENT:"Location         Last        Avg  \r" \
#LINE1:temp2$RAWCOLOUR2:"b" \
#GPRINT:temp2:LAST:"%5.1lf °C" \
#GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\t\t\t\t\t\t---------------------------\l" \
#LINE1:temp4$RAWCOLOUR4:"d" \
#GPRINT:temp4:LAST:"%5.1lf °C" \
#GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#LINE1:temp5$RAWCOLOUR5:"e" \
#GPRINT:temp5:LAST:"%5.1lf °C" \
#GPRINT:temp5:AVERAGE:"%5.1lf °C\r" \
#LINE1:temp1$RAWCOLOUR:"a" \
#GPRINT:temp1:LAST:"%5.1lf °C" \
#GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
#COMMENT:"\u" \
#LINE1:temp3$RAWCOLOUR3:"c" \
#GPRINT:temp3:LAST:"%5.1lf °C" \
#GPRINT:temp3:AVERAGE:"%5.1lf °C\r" \
#HRULE:0#66CCFF:"freezing\l"
#
##averages
#rrdtool graph $IMGPATH/avg.png --start -1w \
#-v "Weekly averages (°C)" \
#--full-size-mode \
#--width=700 --height=400 \
#--slope-mode \
#--color=SHADEB#9999CC \
#--watermark="© khaos - 2015" \
#DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
#DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
#DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
#DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
#DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
#CDEF:trend1=temp4,86400,TREND \
#CDEF:trend2=temp5,86400,TREND \
#CDEF:trend3=temp1,86400,TREND \
#CDEF:trend4=temp2,86400,TREND \
#CDEF:trend5=temp3,86400,TREND \
#CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
#CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
#AREA:nightplus#CCCCCC \
#AREA:nightminus#CCCCCC \
#LINE2:trend4$RAWCOLOUR2:"b 6h average\l" \
#COMMENT:"\t\t\t\t\t\t---------------------------\l" \
#LINE2:trend1$RAWCOLOUR4:"d 6h average\l" \
#COMMENT:"\u" \
#LINE1:trend3$RAWCOLOUR:"a 6h average\r" \
#LINE1:trend2$RAWCOLOUR5:"e 6h average\l" \
#COMMENT:"\u" \
#LINE1:trend5$TRENDCOLOUR:"c 6h average\r"
#
