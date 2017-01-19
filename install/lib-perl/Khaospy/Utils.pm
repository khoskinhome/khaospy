package Khaospy::Utils;
use strict;
use warnings;

use POSIX qw(strftime);
use Carp qw/croak confess/;
use Data::Dumper;
use Exporter qw/import/;
use JSON;
use DateTime;
use Time::Local;

my $json = JSON->new->allow_nonref;

use Khaospy::Constants qw(
    true false
    ON OFF STATUS

    $HEATING_DAEMON_CONF_FULLPATH
    $CONTROLS_CONF_FULLPATH
    $MESSAGES_OVER_SECS_INVALID
);

use Khaospy::Exception qw(
    KhaospyExcept::ShellCommand
);

our @EXPORT_OK = qw(
    trim
    timestamp
    slurp
    burp
    get_hashval
    get_cmd
    get_iso8601_utc_from_epoch
    iso8601_parse
);

sub timestamp { return strftime("%F %T", gmtime( $_[0] || time) ); }

sub slurp {
    my ( $file ) = @_;
    open( my $fh, $file ) or die "Can't open file $file $!\n";
    my $text = do { local( $/ ) ; <$fh> } ;
    return $text;
}

sub burp {
    my( $file_name ) = shift ;
    open( my $fh, ">" , $file_name ) || die "Can't create $file_name $!" ;
    print $fh @_ ;
}

sub get_hashval {
    my ($hash, $key, $allow_undef, $default_on_undef, $default_on_not_exists) = @_;

    confess "Not a hash\n" if ref $hash ne "HASH";

    return $default_on_not_exists
        if defined $default_on_not_exists and ! exists $hash->{$key};

    confess "key '$key' not in HASH\n"
        if ! exists $hash->{$key};

    $allow_undef = true if defined $default_on_undef;

    confess "key '$key' is not defined in HASH"
        if ! $allow_undef and ! defined $hash->{$key};

    return $default_on_undef
        if defined $default_on_undef and ! defined $hash->{$key};

    return $hash->{$key};
}

sub get_cmd {
    my ($cmd) = @_;

    my $ret = qx( $cmd 2>&1 );

    if( $? ) {
        KhaospyExcept::ShellCommand->throw(
            error => "Shell command '$cmd' returned : shell-status $? : $ret"
        );
    }

    $ret =~ s/\s+$//g;

    return $ret;
}

sub get_iso8601_utc_from_epoch {
    my ($epoch) = @_;

    return if ! defined $epoch;

    my $dt =
        DateTime->from_epoch(
            epoch => $epoch,
            time_zone => 'UTC',
        );

    return $dt->strftime('%F %T.%6Nz');
}

sub iso8601_parse {
    my ($iso8601) = @_;
    return if ! defined $iso8601;

    my ($year, $month, $day, $hour, $min, $sec, $frac, $tz) = $iso8601 =~
        /^(\d{4})-(\d\d)-(\d\d)(?:[ T-](\d\d):(\d\d)(?::(\d\d) (?: \. (\d+) )? )?
           ([+-]\d\d (?: :? \d\d)? | [Zz] )? ) ?$/x;

    confess("iso8601_parse(): Invalid timestamp '$iso8601'") if ! defined $day;

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

sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s+//g;
    $txt =~ s/\s+$//g;
    return $txt;
}


1;
