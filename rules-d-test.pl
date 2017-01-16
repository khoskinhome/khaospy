#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use Carp qw(confess);

sub OFF   {'off'}; # closed
sub ON    {'on'};   # open
sub true  {1}
sub false {0}

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


my $ctl = {
    'ameliarad'                 => { current_value => OFF },
    'amelia_window'             => { current_value => OFF },
    'mac-amelia-iphone-6s-plus' => { current_value => OFF },
    'therm-amelia-door'         => { current_value => 3.9 },
    'var-amelia-room-temp'      => { current_value => 21 },
    'var-minimum-room-temp'     => { current_value => 5 },
    'var-allowed-temp-drop'     => { current_value => 1 },

};
sub ctl {
    my ($control_name) = @_;
    return get_hashval( get_hashval($ctl, $control_name), 'current_value');
}

my $rules = [
     {
        rule_name    => 'amelia-rad-control',
        control_name => 'ameliarad',
        ifs => [ # first "if" wins ...
            {   action => OFF,
                if     => "ctl('var-amelia-room-temp') < ctl('therm-amelia-door')"
            },
            {   action => OFF,
                if     => "ctl('amelia_window') eq ON",
            },
            {   action => OFF,
                if     => "ctl('mac-amelia-iphone-6s-plus') eq OFF && ctl('var-minimum-room-temp') < ctl('therm-amelia-door')"
            },
            {   action => ON,
                if     => "ctl('var-amelia-room-temp') - ctl('var-allowed-temp-drop') > ctl('therm-amelia-door') &&  ctl('mac-amelia-iphone-6s-plus') eq ON"
            },
            {   action => ON,
                if     => "ctl('var-minimum-room-temp') - ctl('var-allowed-temp-drop') > ctl('therm-amelia-door') &&  ctl('mac-amelia-iphone-6s-plus') eq OFF"
            },

        ],
    }
];

for my $rule (@$rules){
    try_rule($rule);
}

#if ( $ctl->{'mac-amelia-iphone-6s-plus'} eq OFF && $ctl->{'var-minimum-room-temp'} > $ctl->{'therm-amelia-door'} ){ $do = true }

sub try_rule {
    my ($rule) = @_;

    my $control_name = $rule->{control_name};
    my $rule_name    = $rule->{rule_name};
    my $action       = $rule->{action};
    say "running rule name $rule->{rule_name} on $control_name";
    my $ifs = $rule->{ifs};
    for my $if (@$ifs){
        my $action = $if->{action};
        my $iftest = $if->{if};
        my $do = false;

        my $evalstr = 'if ( '.$iftest.' ){ $do = true }';
        say "  $iftest";
        eval ( $evalstr );

        if ($@){
            say "error in rule $rule_name. $@";
            return;
        }
        if ($do) {
            say "    : matches $iftest\n    : do action '$action'" ;
            do_action($control_name, $action);
            return;
        }
    }
    say "    : no rule matches";
}

sub do_action {
    my ($control_name, $action) = @_;


}








