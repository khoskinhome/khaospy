#!/bin/bash

# original code by https://weather.bartbania.com/bash.txt
############################
#
# Parameters to adjust
#
############################

RRDPATH="/home/khoskin/temperature-monitor/rrddb/"
IMGPATH="/home/khoskin/temperature-monitor/img/"

RRDFILE="temperature.rrd"
LAT="51.6290100N"
LON="0.3584240E"

# Graph Colors
RAWCOLOUR="#FF9933"
RAWCOLOUR2="#0000FF"
RAWCOLOUR3="#336699"
RAWCOLOUR4="#006600"
RAWCOLOUR5="#000000"
TRENDCOLOUR="#FFFF00"

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
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEB#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#E0E0E0 \
AREA:nightminus#E0E0E0 \
CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:dusktilldawn#CCCCCC \
AREA:dawntilldusk#CCCCCC \
COMMENT:"  Location         Last        Avg\l" \
LINE2:temp2$RAWCOLOUR2:"b" \
GPRINT:temp2:LAST:"%5.1lf °C" \
GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\t\t\t\t\t\t---------------------------\l" \
LINE2:temp4$RAWCOLOUR4:"d" \
GPRINT:temp4:LAST:"%5.1lf °C" \
GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN\r" \
LINE1:temp5$RAWCOLOUR5:"e" \
GPRINT:temp5:LAST:"%5.1lf °C" \
GPRINT:temp5:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Sunrise\: $SUNRISEHR\:$SUNRISEMIN\r" \
LINE1:temp1$RAWCOLOUR:"a" \
GPRINT:temp1:LAST:"%5.1lf °C" \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN\r" \
LINE1:temp3$RAWCOLOUR3:"c" \
GPRINT:temp3:LAST:"%5.1lf °C" \
GPRINT:temp3:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Dusk\:    $DUSKHR\:$DUSKMIN\r" \
HRULE:0#66CCFF:"freezing\l"

#day
rrdtool graph $IMGPATH/day.png --start -1d --end now \
-v "Last day (°C)" \
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEA#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
CDEF:trend1=temp4,21600,TREND \
CDEF:trend2=temp5,21600,TREND \
CDEF:trend3=temp1,21600,TREND \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#E0E0E0 \
AREA:nightminus#E0E0E0 \
CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:dusktilldawn#CCCCCC \
AREA:dawntilldusk#CCCCCC \
COMMENT:"  Location         Last        Avg\l" \
LINE2:temp2$RAWCOLOUR2:"b" \
GPRINT:temp2:LAST:"%5.1lf °C" \
GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\t\t\t\t\t\t---------------------------\l" \
LINE2:temp4$RAWCOLOUR4:"d" \
GPRINT:temp4:LAST:"%5.1lf °C" \
GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Dawn\:    $DAWNHR\:$DAWNMIN\r" \
LINE1:temp5$RAWCOLOUR5:"e" \
GPRINT:temp5:LAST:"%5.1lf °C" \
GPRINT:temp5:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Sunrise\: $SUNRISEHR\:$SUNRISEMIN\r" \
LINE1:temp1$RAWCOLOUR:"a" \
GPRINT:temp1:LAST:"%5.1lf °C" \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Sunset\:  $SUNSETHR\:$SUNSETMIN\r" \
LINE1:temp3$RAWCOLOUR3:"c" \
GPRINT:temp3:LAST:"%5.1lf °C" \
GPRINT:temp3:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
COMMENT:"Dusk\:    $DUSKHR\:$DUSKMIN\r" \
HRULE:0#66CCFF:"freezing\l"

#week
rrdtool graph $IMGPATH/week.png --start -1w \
--full-size-mode \
-v "Last week (°C)" \
--width=700 --height=400 \
--slope-mode \
--color=SHADEB#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#E0E0E0 \
AREA:nightminus#E0E0E0 \
CDEF:dusktilldawn=LTIME,86400,%,$DAWN,LT,INF,LTIME,86400,%,$DUSK,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:dawntilldusk=LTIME,86400,%,$DAWN,LT,NEGINF,LTIME,86400,%,$DUSK,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:dusktilldawn#CCCCCC \
AREA:dawntilldusk#CCCCCC \
COMMENT:"  Location         Last        Avg\l" \
COMMENT:"\u" \
COMMENT:"Location         Last        Avg  \r" \
LINE2:temp2$RAWCOLOUR2:"b" \
GPRINT:temp2:LAST:"%5.1lf °C" \
GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\t\t\t\t\t\t---------------------------\l" \
LINE2:temp4$RAWCOLOUR4:"d" \
GPRINT:temp4:LAST:"%5.1lf °C" \
GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
LINE1:temp5$RAWCOLOUR5:"e" \
GPRINT:temp5:LAST:"%5.1lf °C" \
GPRINT:temp5:AVERAGE:"%5.1lf °C\r" \
LINE1:temp1$RAWCOLOUR:"a" \
GPRINT:temp1:LAST:"%5.1lf °C" \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
LINE1:temp3$RAWCOLOUR3:"c" \
GPRINT:temp3:LAST:"%5.1lf °C" \
GPRINT:temp3:AVERAGE:"%5.1lf °C\r" \
HRULE:0#66CCFF:"freezing\l"

#month
rrdtool graph $IMGPATH/month.png --start -1m \
-v "Last month (°C)" \
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEA#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
COMMENT:"  Location         Last        Avg\l" \
COMMENT:"\u" \
COMMENT:"Location         Last        Avg  \r" \
LINE2:temp2$RAWCOLOUR2:"b" \
GPRINT:temp2:LAST:"%5.1lf °C" \
GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\t\t\t\t\t\t---------------------------\l" \
LINE2:temp4$RAWCOLOUR4:"d" \
GPRINT:temp4:LAST:"%5.1lf °C" \
GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
LINE1:temp5$RAWCOLOUR5:"e" \
GPRINT:temp5:LAST:"%5.1lf °C" \
GPRINT:temp5:AVERAGE:"%5.1lf °C\r" \
LINE1:temp1$RAWCOLOUR:"a" \
GPRINT:temp1:LAST:"%5.1lf °C" \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
LINE1:temp3$RAWCOLOUR3:"c" \
GPRINT:temp3:LAST:"%5.1lf °C" \
GPRINT:temp3:AVERAGE:"%5.1lf °C\r" \
HRULE:0#66CCFF:"freezing\l"

#year
rrdtool graph $IMGPATH/year.png --start -1y \
--full-size-mode \
-v "Last year (°C)" \
--width=700 --height=400 \
--color=SHADEB#9999CC \
--slope-mode \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
COMMENT:"  Location         Last        Avg\l" \
COMMENT:"\u" \
COMMENT:"Location         Last        Avg  \r" \
LINE1:temp2$RAWCOLOUR2:"b" \
GPRINT:temp2:LAST:"%5.1lf °C" \
GPRINT:temp2:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\t\t\t\t\t\t---------------------------\l" \
LINE1:temp4$RAWCOLOUR4:"d" \
GPRINT:temp4:LAST:"%5.1lf °C" \
GPRINT:temp4:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
LINE1:temp5$RAWCOLOUR5:"e" \
GPRINT:temp5:LAST:"%5.1lf °C" \
GPRINT:temp5:AVERAGE:"%5.1lf °C\r" \
LINE1:temp1$RAWCOLOUR:"a" \
GPRINT:temp1:LAST:"%5.1lf °C" \
GPRINT:temp1:AVERAGE:"%5.1lf °C\l" \
COMMENT:"\u" \
LINE1:temp3$RAWCOLOUR3:"c" \
GPRINT:temp3:LAST:"%5.1lf °C" \
GPRINT:temp3:AVERAGE:"%5.1lf °C\r" \
HRULE:0#66CCFF:"freezing\l"

#averages
rrdtool graph $IMGPATH/avg.png --start -1w \
-v "Weekly averages (°C)" \
--full-size-mode \
--width=700 --height=400 \
--slope-mode \
--color=SHADEB#9999CC \
--watermark="© khaos - 2015" \
DEF:temp1=$RRDPATH/$RRDFILE:a:AVERAGE \
DEF:temp2=$RRDPATH/$RRDFILE:b:AVERAGE \
DEF:temp3=$RRDPATH/$RRDFILE:c:AVERAGE \
DEF:temp4=$RRDPATH/$RRDFILE:d:AVERAGE \
DEF:temp5=$RRDPATH/$RRDFILE:e:AVERAGE \
CDEF:trend1=temp4,86400,TREND \
CDEF:trend2=temp5,86400,TREND \
CDEF:trend3=temp1,86400,TREND \
CDEF:trend4=temp2,86400,TREND \
CDEF:trend5=temp3,86400,TREND \
CDEF:nightplus=LTIME,86400,%,$SUNR,LT,INF,LTIME,86400,%,$SUNS,GT,INF,UNKN,temp1,*,IF,IF \
CDEF:nightminus=LTIME,86400,%,$SUNR,LT,NEGINF,LTIME,86400,%,$SUNS,GT,NEGINF,UNKN,temp1,*,IF,IF \
AREA:nightplus#CCCCCC \
AREA:nightminus#CCCCCC \
LINE2:trend4$RAWCOLOUR2:"b 6h average\l" \
COMMENT:"\t\t\t\t\t\t---------------------------\l" \
LINE2:trend1$RAWCOLOUR4:"d 6h average\l" \
COMMENT:"\u" \
LINE1:trend3$RAWCOLOUR:"a 6h average\r" \
LINE1:trend2$RAWCOLOUR5:"e 6h average\l" \
COMMENT:"\u" \
LINE1:trend5$TRENDCOLOUR:"c 6h average\r"

