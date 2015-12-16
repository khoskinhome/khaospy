#!/bin/bash

# original code by https://weather.bartbania.com/bash.txt
############################
#
# Parameters to adjust
#
############################

# TODO error checking for the 3 params :
# $1 = rrdfile
# $2 = location
# $3 = dir-name-for images.

RRDPATH="/opt/khaospy/rrd/"
IMGPATH="/opt/khaospy/rrdimg/$3"

if [[ ! -d $IMGPATH ]] ; then
    mkdir -p $IMGPATH
fi 

RRDFILE=$1

LOCATION_NAME=$2

LAT="51.6290100N"
LON="0.3584240E"

# Graph Colors
RAWCOLOUR="#0000FF"
#RAWCOLOUR="#FF9933"
RAWCOLOUR4="#006600"

# Calculating Civil Twilight based on location from LAT LON
DUSKHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 45-46`
DUSKMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 47-48`
DAWNHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 30-31`
DAWNMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun rises/{:a;n;/Nautical twilight/b;p;ba}' | cut -c 32-33`

# Calculating sunset/sunrise based on location from LAT LON
SUNRISEHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 30-31`
SUNRISEMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 32-33`
SUNSETHR=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 45-46`
SUNSETMIN=`/usr/bin/sunwait sun up $LAT $LON -p | sed -n '/Sun transits/{:a;n;/Civil twilight/b;p;ba}' | cut -c 47-48`

# Converting to seconds
SUNR=$(($SUNRISEHR * 3600 + $SUNRISEMIN * 60))
SUNS=$(($SUNSETHR * 3600 + $SUNSETMIN * 60))
DUSK=$(($DUSKHR * 3600 + $DUSKMIN * 60))
DAWN=$(($DAWNHR * 3600 + $DAWNMIN * 60))

############################
#
# Creating graphs
#
############################
#hour
rrdtool graph $IMGPATH/hour.png --start -6h --end now \
-v "Last 6 hours (°C)" \
--lower-limit=0 \
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEB#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#E0E0E0 \
AREA:nightminus#E0E0E0 \
CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:dusktilldawn#CCCCCC \
AREA:dawntilldusk#CCCCCC \
COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN  Sunrise\: $SUNRISEHR\:$SUNRISEMIN\l" \
COMMENT:"\u" \
COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN  Dusk\:    $DUSKHR\:$DUSKMIN\r" \
LINE2:temp1$RAWCOLOUR:"$LOCATION_NAME" \
COMMENT:" Last = " \
GPRINT:temp1:LAST:"%5.1lf °C" \
COMMENT:" Ave = " \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
HRULE:0#66CCFF:"freezing\l"


#day
rrdtool graph $IMGPATH/day.png --start -1d --end now \
-v "Last day (°C)" \
--lower-limit=0 \
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEA#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
CDEF:trend3=temp1,21600,TREND \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#E0E0E0 \
AREA:nightminus#E0E0E0 \
CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:dusktilldawn#CCCCCC \
AREA:dawntilldusk#CCCCCC \
COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN  Sunrise\: $SUNRISEHR\:$SUNRISEMIN\l" \
COMMENT:"\u" \
COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN  Dusk\:    $DUSKHR\:$DUSKMIN\r" \
LINE1:temp1$RAWCOLOUR:"$LOCATION_NAME" \
COMMENT:" Last = " \
GPRINT:temp1:LAST:"%5.1lf °C     " \
COMMENT:" Ave = " \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
HRULE:0#66CCFF:"freezing\l"

#week
rrdtool graph $IMGPATH/week.png --start -1w \
--full-size-mode \
-v "Last week (°C)" \
--lower-limit=0 \
--width=700 --height=400 \
--slope-mode \
--color=SHADEB#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
CDEF:trend1=temp1,86400,TREND \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#E0E0E0 \
AREA:nightminus#E0E0E0 \
CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:dusktilldawn#CCCCCC \
AREA:dawntilldusk#CCCCCC \
LINE2:trend1$RAWCOLOUR4:"$LOCATION_NAME 6h average\l" \
LINE1:temp1$RAWCOLOUR:"$LOCATION_NAME" \
COMMENT:" Last = " \
GPRINT:temp1:LAST:"%5.1lf °C     " \
COMMENT:" Ave = " \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
HRULE:0#66CCFF:"freezing\l"

#month
rrdtool graph $IMGPATH/month.png --start -1m \
-v "Last month (°C)" \
--lower-limit=0 \
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEA#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
LINE1:temp1$RAWCOLOUR:"$LOCATION_NAME" \
COMMENT:" Last = " \
GPRINT:temp1:LAST:"%5.1lf °C     " \
COMMENT:" Ave = " \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
HRULE:0#66CCFF:"freezing\l"

#year
rrdtool graph $IMGPATH/year.png --start -1y \
--full-size-mode \
-v "Last year (°C)" \
--lower-limit=0 \
--width=700 --height=400 \
--color=SHADEB#9999CC \
--slope-mode \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
LINE1:temp1$RAWCOLOUR:"$LOCATION_NAME" \
COMMENT:" Last = " \
GPRINT:temp1:LAST:"%5.1lf °C     " \
COMMENT:" Ave = " \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
HRULE:0#66CCFF:"freezing\l"

#averages
rrdtool graph $IMGPATH/avg.png --start -1w \
-v "Weekly averages (°C)" \
--lower-limit=0 \
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEB#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
CDEF:trend1=temp1,86400,TREND \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#CCCCCC \
AREA:nightminus#CCCCCC \
LINE2:trend1$RAWCOLOUR4:"$LOCATION_NAME 6h average\l" \

