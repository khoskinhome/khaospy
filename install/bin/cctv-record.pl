#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use POSIX qw/strftime/;

=pod

    script to be cron to run hourly at 00 mins with
        0 * * * * /bin/record.pl

    needs :
        sudo apt-get install livemedia-utils

=cut

my $cifs_root = '/media/khoskin/';
my $cam_store_root = "$cifs_root/nas_movies_n_tv/cctv/";

#my $stat_cifs_root        = qx{stat -fc%t:%T '$cifs_root'};
#my $stat_cifs_root_dotdot = qx{stat -fc%t:%T '$cifs_root/..'};
#
#print "cifs root    = $stat_cifs_root \n";
#print "cifs root/.. = $stat_cifs_root_dotdot \n";
#    $stat_cifs_root !~ /cifs$/
#    $stat_cifs_root eq $stat_cifs_root_dotdot

my $cam_store_stat =  qx{stat -fc%t:%T '$cam_store_root'};

print $cam_store_stat."\n";

if ( $cam_store_stat !~ /cifs$/ ) {
    die "$cam_store_root is NOT cifs mounted. Cannot record\n";
}

if ( qx{which openRTSP} !~ /openRTSP/ ){
    die "can't record . openRTSP isn't installed.\n"
        ."Run install:\n   sudo apt-get install livemedia-utils\n";
}

my $cams = {
    'ipcam04' => {
        url => 'rtsp://ipcam04.khaos:554/ucast/11',
    }
};

for my $cam ( keys %$cams ) {
 
    my $tstmp_day  = strftime( '%F' , gmtime );
    my $tstmp_hour = strftime( '%H' , gmtime );
    my $tstmp_hourmin = strftime( '%H%M', gmtime );

    my $path = "$cam_store_root/$cam/$tstmp_day/$tstmp_hour";

    my $fileprefix = "$cam-$tstmp_day-$tstmp_hourmin";

    if ( ! -d $path ){
        my $mkcmd = "mkdir -p $path";
        print $mkcmd."\n";
        system($mkcmd) and die "can't $mkcmd";
    }

    chdir $path or die "can't chdir to $path";

    my $url = $cams->{$cam}{url};

    # script is to be run hourly, hence -d == 3660 , so the following command will
    # record 61 mins, split up into (-P 300) 5 min files.
    my $rec_cmd = "openRTSP -D 1 -B 10000000 -b 10000000 -4 -Q -F $fileprefix -d 3600 -P 300 $url &";
    print "$rec_cmd\n";
    system($rec_cmd);

}


#-U 20160409T202200Z \
#-E 20160409T202100Z \

#-c \

