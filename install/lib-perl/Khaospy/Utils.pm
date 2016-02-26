package Khaospy::Utils;
use strict;
use warnings;

use POSIX qw(strftime);
use Carp qw/croak confess/;
use Data::Dumper;
use Exporter qw/import/;
use JSON;

my $json = JSON->new->allow_nonref;

use Khaospy::Constants qw(
    true false
    ON OFF STATUS
    $ONE_WIRED_SENDER_SCRIPT

    $HEATING_DAEMON_CONF_FULLPATH
    $CONTROLS_CONF_FULLPATH
    $MESSAGES_OVER_SECS_INVALID
);

use Khaospy::Exception qw(
    KhaospyExcept::ShellCommand
);

our @EXPORT_OK = qw(
    timestamp
    slurp
    burp
    get_one_wire_sender_hosts
    get_hashval
    get_cmd
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


## TODO this is going to be done PiHostss.pm
## this code needs moving there.
sub get_one_wire_sender_hosts {

    # TODO fix this hack,
    return qw/
        piold piloft piboiler
    /;


#    my $daemon_runner_conf = $json->decode(
#        slurp ( $DAEMON_RUNNER_CONF_FULLPATH )
#    );
#
#    my $one_wire_sender_host = [];
#    for my $host ( keys %$daemon_runner_conf ){
#        push @$one_wire_sender_host, $host
#            if (
#                grep { $_ =~ /^$ONE_WIRED_SENDER_SCRIPT/ }
#                @{$daemon_runner_conf->{$host}}
#            );
#    }
#
#    my %ret = map { $_ => 1 } @$one_wire_sender_host ;
#    return keys %ret ;
}

sub get_hashval {
    my ($hash, $key, $allow_undef) = @_;

    confess "Not a hash" if ref $hash ne "HASH";

    confess "key '$key' not in HASH\n"
        if ! exists $hash->{$key};

    confess "key '$key' is not defined in HASH"
        if ! $allow_undef and ! defined $hash->{$key};

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

1;
