#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use Time::Local;
use DateTime;
use Scalar::Util qw(looks_like_number);

for my $d (
'2016-12-22T16:11:28.91078+00',
'2016-12-22 16:11:28.91078+00',
'2016-12-22 16:11:28+00',
'2016-12-22 16:11:28+00:00',
'2016-12-22 16:11:28',
'2016-12-22',
'2016-12-22 16:11:28.91078+00:30',
'2016-12-22 16:11:28.91078+0030',
'2016-12-22 16:11:28.91078+00:30',
'2016-12-22 16:11:28.91078+00:30',
'2016-12-22 16:11:28.91078+00:30',
'2016-12-22 16:11:28.91078+00:30',
'2016-12-22 16:11:28.91078+00:30',
#'2016-12-25 15:39:30.68342+00',
#'2016-10-02 21:40:26.57717+00',
#'2017-01-02 19:05:44.36334+00',
#'2017-01-16 20:28:41.99991+00',
#'2017-01-16 20:21:32.74851+00',
#'2017-01-15 19:06:32.41873+00',
#'2017-01-16 19:56:33.88182+00',
#'2017-01-16 20:29:43.64212+00',
#'2017-01-16 20:28:45.21422+00',
#'2017-01-16 19:51:34.15393+00',
#'2017-01-15 19:27:52.46671+00',
){

    say "\n################";
    my $epoch = iso8601_parse($d);
    say $d;
    say get_iso8601_utc_from_epoch($epoch);
    say $epoch;
    say iso8601_parse(get_iso8601_utc_from_epoch($epoch));
    say get_iso8601_utc_from_epoch(iso8601_parse(get_iso8601_utc_from_epoch($epoch)));
    say iso8601_parse(get_iso8601_utc_from_epoch(iso8601_parse(get_iso8601_utc_from_epoch($epoch))));

    say iso8601_or_epoch_to_timestamp($epoch);
    say iso8601_or_epoch_to_timestamp($d);
    say iso8601_or_epoch_to_epoch($epoch);
    say iso8601_or_epoch_to_epoch($d);
    say iso8601_from_epoch($epoch,'Europe/Berlin');

}


sub iso8601_parse {
    my ($iso8601) = @_;
    return if ! defined $iso8601;

    my ($year, $month, $day, $hour, $min, $sec, $frac, $tz) = $iso8601 =~
        /^(\d{4})-(\d\d)-(\d\d)(?:[ T-](\d\d):(\d\d)(?::(\d\d) (?: \. (\d+) )? )?
           ([+-]\d\d (?: :? \d\d)? | [Zz] )? ) ?$/x;

    die("iso8601_parse(): Invalid timestamp '$iso8601'") if ! defined $day;

    my $offsecs;
    if (!defined $tz || uc($tz) eq 'Z') { $offsecs = 0 }
    elsif ($tz =~ /^([+-])(\d\d):?(\d\d)$/) {
        my $delta = $2 * 3600 + $3 * 60;
        $offsecs = ($1 eq '+') ? $delta : $delta * -1;
    }
    else { $offsecs = $tz * 3600 }

    my $epoch = timegm($sec||0, $min||0, $hour||0, $day, $month-1, $year)-$offsecs;
    $epoch += "0.$frac" if defined $frac;
    return $epoch;
}

sub get_iso8601_utc_from_epoch {
    my ($epoch) = @_;

    return if ! defined $epoch;

    my $dt =
        DateTime->from_epoch(
            epoch => $epoch,
            time_zone => 'UTC',
        );

    return $dt->strftime('%F %T.%6N%z');
}

sub iso8601_from_epoch {
    my ($epoch, $tz) = @_;
    $tz = "UTC" if ! $tz;

    return if ! defined $epoch;

    my $dt =
        DateTime->from_epoch(
            epoch => $epoch,
            time_zone => $tz,
        );

    return $dt->strftime('%F %T.%6N%z');
}

sub iso8601_or_epoch_to_timestamp {
    my ( $iso_epoch, $tz ) = @_;
    return iso8601_from_epoch($iso_epoch, $tz) if looks_like_number($iso_epoch);
    return iso8601_from_epoch(iso8601_parse($iso_epoch, $tz));
}

sub iso8601_or_epoch_to_epoch {
    my ( $iso_epoch ) = @_;

    return $iso_epoch if looks_like_number($iso_epoch);
    return iso8601_parse($iso_epoch);
}

