#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

# This is a terrible script . It does work though.
# install/bin/khaospy-command-queue-d.pl:18:use Getopt::Long;
if ( $>  != 0 ) {
    die "Need to run this as root \n";
}

use Getopt::Long;
my $KILL;
GetOptions ( "kill|k" => \$KILL );

my $out = qx{ps -eF | grep khaospy | grep -v grep};
my $struct = { 1 => {} };
for my $line (  split /\n/, $out ) {
    if ( my ($pid , $ppid, $script ) = $line  =~ /^\w+\s*(\d+)\s*(\d+).*?\d\d:\d\d:\d\d\s(.*)/ ){
#       printf ( "%s %s %s\n" , $pid , $ppid , trim_script($script));

        if ($ppid == 1 ) {
            $struct->{1}{$pid}={};
        }
    };
};

my $kill_line = '';

for my $line (  split /\n/, $out ) {
    if ( my ($pid , $ppid, $script ) = $line  =~ /^\w+\s*(\d+)\s*(\d+).*?\d\d:\d\d:\d\d\s(.*)/ ){
        if (exists $struct->{1}{$ppid} ) {
            $struct->{1}{$ppid}{$pid}=trim_script($script);
            $kill_line .= "$ppid $pid ";
        }
    };
};

use Data::Dumper;
print Dumper ($struct);

$kill_line = "sudo kill -9 $kill_line";

if ( $KILL ) {
    system ("sudo kill -9 $kill_line" );
    say "have just run : $kill_line";
} else {
    say "have NOT run : $kill_line";
    say " use --kill or -k to kill";
}

sub trim_script {
    my ($script)  = @_;

    my $ret;
    if ( $script =~ m{/usr/bin/daemon} ) {
        ($ret ) = $script =~ m{\-\-command=(.+?)\s};
    } else {
        $ret = $script
    }

    return $ret;
}
