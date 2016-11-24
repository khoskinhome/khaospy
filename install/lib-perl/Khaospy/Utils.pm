package Khaospy::Utils;
use strict;
use warnings;

use POSIX qw(strftime);
use Carp qw/croak confess/;
use Data::Dumper;
use Exporter qw/import/;
use JSON;
use DateTime;

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
    trans_ON_to_value_or_return_val
    password_meets_restrictions
    password_restriction_desc
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

sub trans_ON_to_value_or_return_val { # and OFF to false
    my ($ONOFF) = @_;

    return $ONOFF if $ONOFF !~ /^[a-z]+$/i;

    return true  if $ONOFF eq ON;
    return false if $ONOFF eq OFF;

    die "Can't translate a non ON or OFF value ($ONOFF) to value";

}

sub password_meets_restrictions {
    my ($password) = @_;

    if ( $password =~ /[A-Z]/
      && $password =~ /[a-z]/
      && $password =~ /[0-9]/
      && length($password) > 7
    ){ return true }

    if ( $password =~ /[A-Z]/i
      && $password =~ /\W/
      && $password =~ /[0-9]/
      && length($password) > 7
    ){ return true }

    return false;
}

sub password_restriction_desc {
    return "Passwords need to be at least 8 characters long and contain one UPPER and one lower case letter plus one number. Alternatively you can have a password that has one letter, one number and one non-word char that is 8 chararacters long. Passwords longer than 72 characters are truncated";
}

sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s+//g;
    $txt =~ s/\s+$//g;
    return $txt;
}

1;
