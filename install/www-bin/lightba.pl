#!/usr/bin/perl -w
use strict;

# this is put in a cgi-bin dir somewhere. the listen_dir and post_dir paths have to be set up for IPC . I've used sshfs to do this.

use CGI;
use JSON;
use Time::HiRes qw/usleep time/;
use Data::Dumper;

##### my $listen_dir = '/home/khoskin/sshfs_khoskin_raspberry_pi/tmp/amelia_lights/listen/';

# TODO some stuff that checks that the sshfs mounts to the following is actually setup :-
#my $listen_dir = "/home/www-data/sshfs_khoskin_raspberry_pi/tmp/amelia_lights/listen/";
#my $post_dir = "/home/www-data/sshfs_khoskin_raspberry_pi/tmp/amelia_lights/post/";

my $imgwebroot = "/img/";

my $listen_dir = "/tmp/amelia_lights/listen/";
my $post_dir = "/tmp/amelia_lights/post/";

#sshfs khoskin@192.168.1.9:/ /home/www-data/sshfs_khoskin_raspberry_pi/

my $q = CGI->new;
    print $q->header('text/html');

if ( ! -d $listen_dir ) {
    print "can't access the listen_dir\n";
    exit 0;
}

if ( ! -d $post_dir ) {
    print "can't access the post_dir\n";
    exit 0;
}


#my @names = $q->param;

my $data_out = {
##    amelia_light_0 => 0,
##    amelia_light_1 => 1,
##    amelia_light_2 => 0,
##    amelia_light_3 => 0,
##    amelia_light_4 => 0,
##    amelia_light_5 => 1,
##    amelia_light_6 => "invert",
##    amelia_lights_all_on => 0,
##    amelia_lights_all_off => 0,
##    amelia_lights_all_invert => 0,
##    amelia_lights_array_invert => [0,3,5],
##    amelia_lights_array_on => [0,3,5],
#    amelia_lights_array_invert => [6,7,8],
#
};
#

my %params = ();

for my $tp ( qw/all state disco rand chaser/ ){
    $params{$tp} = $q->param($tp);
    delete $params{$tp} if ! defined $params{$tp};
}

if ( exists $params{all} ) {
    $data_out->{amelia_lights_all_on} = 1 if $params{state} eq '1';
    $data_out->{amelia_lights_all_off} = 1 if $params{state} eq '0';
    $data_out->{amelia_lights_all_invert} = 1 if $params{state} eq 'invert';
} elsif (  exists $params{disco} ||  exists $params{rand} ||  exists $params{chaser} ){
    my $type = $params{disco} ;
    $data_out->{"amelia_lights_$type"} = 1;
} else {
    my $light_array = [];
    for my $z ( 1..9 ) {
        my $val = $q->param("light$z");
        #$params{"light$z"} =  $val
        if (  defined $val ) {
            push @$light_array, ($z-1); # the daemon needs 0 - 8 numbering .
        }

    }

    print STDERR "state = ".$params{state}."\n";
    print STDERR "light array = ".join( " ", @$light_array)."\n";

    if ( @$light_array && $params{state} eq '1'      ) {
        $data_out->{amelia_lights_array_on}     = $light_array;
    }
    if ( @$light_array && $params{state} eq '0'      ) {
        $data_out->{amelia_lights_array_off}    = $light_array;
    }
    if ( @$light_array && $params{state} eq 'invert' ) {
        $data_out->{amelia_lights_array_invert} = $light_array;
    }
}


my $json = JSON->new->allow_nonref;

if ( scalar keys %$data_out ) {
    my $filename = $listen_dir."/".time."data.out";
    my $json_text = $json->pretty->encode ( $data_out );
    burp ( $filename , $json_text );
    system ( "mv $filename $filename.lights.cmd" );
    usleep 250000;
}


####################################################


my $json_status = slurp ( $post_dir."/status");

my $statty_stuff = $json->decode( $json_status );


my $serialised_statty_stuff = $statty_stuff->{amelia_lights_state};


my @stylight=();
my @lightimg=();

for my $i ( 0..8 ){
    $stylight[$i+1] = ''; #get_style( $statty_stuff->{amelia_lights_config}{"amelia_light_$i"}{current_state});

    $lightimg[$i+1] = get_light_img( $statty_stuff->{amelia_lights_config}{"amelia_light_$i"}{current_state} );

}

my $styswitch = get_style( $statty_stuff->{amelia_lights_config}{"amelia_light_switch_detect"}{current_state} );
my $wallswitchimg=get_wall_switch_img($statty_stuff->{amelia_lights_config}{"amelia_light_switch_detect"}{current_state});

sub get_style {
    if ( $_[0] ) {
        return "background-color: yellow";
    } else {
        return "background-color: grey";
    }
}

sub get_light_img {
    if ( $_[0] ) {
        return "$imgwebroot/yellow-light.png";  # on
    } else {
        return "$imgwebroot/grey-light.png";  # off
    }
}

sub get_wall_switch_img {
    if ( $_[0] ) {
        return "$imgwebroot/light-switch-icon-on.jpg";  # on
    } else {
        return "$imgwebroot/light-switch-icon-off.jpg";  # off
    }
}


sub slurp {
    my ( $file ) = @_;
    open( my $fh, $file ) or die "sudden flaming death $file\n";
    my $text = do { local( $/ ) ; <$fh> } ;
    return $text;
}

sub burp {
    my( $file_name ) = shift ;
    open( my $fh, ">" , $file_name ) ||
                     die "can't create $file_name $!" ;
    print $fh @_ ;
}

my $switchleft  = "$imgwebroot/light-switch-left-cl.jpg";
my $switchright = "$imgwebroot/light-switch-right-cl.jpg";

# image sizing 
my $sizemin = 10;
my $sizemax = 120;

my $size  = $q->param('size') || 40;
$size = $sizemin if ( $size < $sizemin );
$size = $sizemax if ( $size > $sizemax );
my $heightspacer = $size;
my $heightmain   = $size*3;

my $sizesmaller = $size - 5;
my $sizebigger  = $size + 5;

print <<"EOSTR";

<!DOCTYPE html>
<html>

<head>
<title>Amelia Lights</title>

<!-- <link rel=STYLESHEET type="text/css" href="main.css"> -->

<meta name="author" content="Khoskin">
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />

<!-- <script language="JavaScript" src="./mouseover.js" type="text/javascript"></script> -->


<style>

tr {height:$size; }

td.spacer { width:20;}

</style>


</head>

<body>

<!-- <div style='vertical-align:middle;height:100%;margin-left:auto;margin-right:auto;' > -->

<div align='center' > 

<br><br><br>

<table style='vertical-align:middle;' border='0' cellpadding='0' cellspacing='0' >

<tr align='center'>
   <td align='right'><a href='?all&state=1&size=$size'      ><img src='$switchleft' height='$heightmain' alt='ON'  ></a></td>
   <td align='left' ><a href='?all&state=0&size=$size'      ><img src='$switchright' height='$heightmain' alt='OFF' ></a></td>
   <td class='spacer'></td>
   <td align='right'><a href='?light3&light6&light9&state=1&size=$size'      ><img src='$switchleft' height='$heightmain' alt='ON'  ></a></td>
   <td align='left' ><a href='?light3&light6&light9&state=0&size=$size'      ><img src='$switchright' height='$heightmain' alt='OFF' ></a></td>
   <td class='spacer'></td>
   <td align='right'><a href='?light2&light5&light8&state=1&size=$size'      ><img src='$switchleft' height='$heightmain' alt='ON'  ></a></td>
   <td align='left' ><a href='?light2&light5&light8&state=0&size=$size'      ><img src='$switchright' height='$heightmain' alt='OFF' ></a></td>
   <td class='spacer'></td>
   <td align='right'><a href='?light1&light4&light7&state=1&size=$size'      ><img src='$switchleft' height='$heightmain' alt='ON'  ></a></td>
   <td align='left' ><a href='?light1&light4&light7&state=0&size=$size'      ><img src='$switchright' height='$heightmain' alt='OFF' ></a></td>

</tr>

<tr align='center'><td colspan='11'><img src='/blank.jpg' height='$heightspacer' alt='' ></td> </tr>


<tr align='center'>
   <td align='right'><a href='?light1&light2&light3&state=1&size=$size'      ><img src='$switchleft' height='$heightmain' alt='ON' ></a></td>
   <td align='left' ><a href='?light1&light2&light3&state=0&size=$size'      ><img src='$switchright' height='$heightmain' alt='OFF' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[3]'><a href='?light3&state=invert&size=$size' accesskey="3" ><img src='$lightimg[3]' height='$heightmain' alt='3' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[2]'><a href='?light2&state=invert&size=$size' accesskey="2" ><img src='$lightimg[2]' height='$heightmain' alt='2' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[1]'><a href='?light1&state=invert&size=$size' accesskey="1" ><img src='$lightimg[1]' height='$heightmain' alt='1' ></a></td>

</tr>

<tr align='center'><td colspan='11'><img src='/blank.jpg' height='$heightspacer' alt='' ></td> </tr>

<tr align='center'>

   <td align='right'><a href='?light4&light5&light6&state=1&size=$size'      ><img src='$switchleft' height='$heightmain' alt='ON'  ></a></td>
   <td align='left' ><a href='?light4&light5&light6&state=0&size=$size'      ><img src='$switchright' height='$heightmain' alt='OFF' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[6]'><a href='?light6&state=invert&size=$size' accesskey="6" ><img src='$lightimg[6]' height='$heightmain' alt='6' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[5]'><a href='?light5&state=invert&size=$size' accesskey="5" ><img src='$lightimg[5]' height='$heightmain' alt='5' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[4]'><a href='?light4&state=invert&size=$size' accesskey="4" ><img src='$lightimg[4]' height='$heightmain' alt='4' ></a></td>
</tr>

<tr align='center'><td colspan='11'><img src='/blank.jpg' height='$heightspacer' alt='' ></td> </tr>

<tr align='center'>
   <td align='right'><a href='?light7&light8&light9&state=1&size=$size'      ><img src='$switchleft' height='$heightmain' alt='ON' ></a></td>
   <td align='left' ><a href='?light7&light8&light9&state=0&size=$size'      ><img src='$switchright' height='$heightmain' alt='OFF' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[9]'><a href='?light9&state=invert&size=$size' accesskey="9" ><img src='$lightimg[9]' height='$heightmain' alt='9' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[8]'><a href='?light8&state=invert&size=$size' accesskey="8" ><img src='$lightimg[8]' height='$heightmain' alt='8' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' style='$stylight[7]'><a href='?light7&state=invert&size=$size' accesskey="7" ><img src='$lightimg[7]' height='$heightmain' alt='7' ></a></td>
</tr>

<!--
<tr align='center'><td colspan='11'><img src='/blank.jpg' height='$heightspacer' alt='' ></td> </tr>
<tr align='center'>
   <td colspan='2'><a href='?disco=1&size=$size' ><img src='' height='$heightmain' alt='DISCO' ></a></td>
   <td class='spacer'></td>
   <td colspan='2'><a href='?rand=1&size=$size' ><img src='' height='$heightmain' alt='RAND' ></a></td>
   <td class='spacer'></td>
   <td colspan='2'><a href='?chaser=1&size=$size' ><img src='' height='$heightmain' alt='CHASER' ></a></td>
</tr>
-->

<tr align='center'><td colspan='11'><img src='/blank.jpg' height='$heightspacer' alt='' ></td> </tr>

<tr align='center'>
   <td colspan='2'><a href='/cgi-bin/lightba.pl?size=$size' ><img src='$imgwebroot/refresh.png' height='$heightmain' alt='REFRESH' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' ><img src='$wallswitchimg' height='$heightmain' alt='SWITCH' ></td>
   <td class='spacer'></td>
   <td colspan='2' ><a href='/cgi-bin/lightba.pl?size=$sizesmaller' ><img src='$imgwebroot/down-arrow.png' height='$heightmain' alt='Smaller' ></a></td>
   <td class='spacer'></td>
   <td colspan='2' ><a href='/cgi-bin/lightba.pl?size=$sizebigger'  ><img src='$imgwebroot/up-arrow.png'   height='$heightmain' alt='Bigger'  ></a></td>
</tr>

</table>

</div>

</body>
</html>

EOSTR

;



