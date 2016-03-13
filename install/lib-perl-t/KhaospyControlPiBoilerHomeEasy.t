#!perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl/";
# by Karl Kount-Khaos Hoskin. 2015-2016

use Test::More qw/no_plan/;
use Test::Exception;
use Test::Deep;

use Sub::Override;
use Data::Dumper;

use DateTime;

sub true  { 1 };
sub false { 0 };

sub IN  {"in"};
sub OUT {"out"};

sub ON  {"on"};
sub OFF {"off"};

my $rules = [
    {
        start_time  => '0000',
        end_time    => '0600',
        day_of_week => qr/^[12345]$/,
        action      => OFF,
        channel     => 2,
    },

    {
        start_time  => '0100',
        end_time    => '0600',
        day_of_week => qr/^[67]$/,
        action      => OFF,
        channel     => 2,
    },

    {
        start_time  => '2200',
        end_time    => '2359',
        day_of_week => qr/^[71234]$/,
        action      => OFF,
        channel     => 2,
    },
];

my $override_channel;
my $override_action;



use_ok  ( "Khaospy::ControlPiBoilerHomeEasy",
            "operate",
        );

my $override_get_pi_hosts_conf
    = Sub::Override->new(
        'Khaospy::ControlPiBoilerHomeEasy::operate',
        sub {
            my ($channel, $action) = @_;
            $override_channel = $channel;
            $override_action  = $action;
        }
);


my $tests = [
    {day=>14, hour=>0,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #monday
    {day=>14, hour=>0,  minute=>1,  expect_channel=>2,     expect_action=> OFF  }, #monday
    {day=>14, hour=>5,  minute=>59, expect_channel=>2,     expect_action=> OFF  }, #monday
    {day=>14, hour=>6,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #monday
    {day=>14, hour=>6,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #monday
    {day=>14, hour=>10, minute=>1,  expect_channel=>undef, expect_action=> undef}, #monday
    {day=>14, hour=>12, minute=>1,  expect_channel=>undef, expect_action=> undef}, #monday
    {day=>14, hour=>18, minute=>1,  expect_channel=>undef, expect_action=> undef}, #monday
    {day=>14, hour=>20, minute=>1,  expect_channel=>undef, expect_action=> undef}, #monday
    {day=>14, hour=>21, minute=>59, expect_channel=>undef, expect_action=> undef}, #monday
    {day=>14, hour=>22, minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #monday
    {day=>14, hour=>23, minute=>59, expect_channel=>2,     expect_action=> OFF  }, #monday

    {day=>15, hour=>0,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #tuesday
    {day=>15, hour=>0,  minute=>1,  expect_channel=>2,     expect_action=> OFF  }, #tuesday
    {day=>15, hour=>5,  minute=>59, expect_channel=>2,     expect_action=> OFF  }, #tuesday
    {day=>15, hour=>6,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #tuesday
    {day=>15, hour=>6,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #tuesday
    {day=>15, hour=>10, minute=>1,  expect_channel=>undef, expect_action=> undef}, #tuesday
    {day=>15, hour=>12, minute=>1,  expect_channel=>undef, expect_action=> undef}, #tuesday
    {day=>15, hour=>18, minute=>1,  expect_channel=>undef, expect_action=> undef}, #tuesday
    {day=>15, hour=>20, minute=>1,  expect_channel=>undef, expect_action=> undef}, #tuesday
    {day=>15, hour=>21, minute=>59, expect_channel=>undef, expect_action=> undef}, #tuesday
    {day=>15, hour=>22, minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #tuesday
    {day=>15, hour=>23, minute=>59, expect_channel=>2,     expect_action=> OFF  }, #tuesday

    {day=>16, hour=>0,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #wednesday
    {day=>16, hour=>0,  minute=>1,  expect_channel=>2,     expect_action=> OFF  }, #wednesday
    {day=>16, hour=>5,  minute=>59, expect_channel=>2,     expect_action=> OFF  }, #wednesday
    {day=>16, hour=>6,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #wednesday
    {day=>16, hour=>6,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #wednesday
    {day=>16, hour=>10, minute=>1,  expect_channel=>undef, expect_action=> undef}, #wednesday
    {day=>16, hour=>12, minute=>1,  expect_channel=>undef, expect_action=> undef}, #wednesday
    {day=>16, hour=>18, minute=>1,  expect_channel=>undef, expect_action=> undef}, #wednesday
    {day=>16, hour=>20, minute=>1,  expect_channel=>undef, expect_action=> undef}, #wednesday
    {day=>16, hour=>21, minute=>59, expect_channel=>undef, expect_action=> undef}, #wednesday
    {day=>16, hour=>22, minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #wednesday
    {day=>16, hour=>23, minute=>59, expect_channel=>2,     expect_action=> OFF  }, #wednesday

    {day=>17, hour=>0,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #thursday
    {day=>17, hour=>0,  minute=>1,  expect_channel=>2,     expect_action=> OFF  }, #thursday
    {day=>17, hour=>5,  minute=>59, expect_channel=>2,     expect_action=> OFF  }, #thursday
    {day=>17, hour=>6,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #thursday
    {day=>17, hour=>6,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #thursday
    {day=>17, hour=>10, minute=>1,  expect_channel=>undef, expect_action=> undef}, #thursday
    {day=>17, hour=>12, minute=>1,  expect_channel=>undef, expect_action=> undef}, #thursday
    {day=>17, hour=>18, minute=>1,  expect_channel=>undef, expect_action=> undef}, #thursday
    {day=>17, hour=>20, minute=>1,  expect_channel=>undef, expect_action=> undef}, #thursday
    {day=>17, hour=>21, minute=>59, expect_channel=>undef, expect_action=> undef}, #thursday
    {day=>17, hour=>22, minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #thursday
    {day=>17, hour=>23, minute=>59, expect_channel=>2,     expect_action=> OFF  }, #thursday

    {day=>18, hour=>0,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #friday
    {day=>18, hour=>0,  minute=>1,  expect_channel=>2,     expect_action=> OFF  }, #friday
    {day=>18, hour=>5,  minute=>59, expect_channel=>2,     expect_action=> OFF  }, #friday
    {day=>18, hour=>6,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #friday
    {day=>18, hour=>6,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #friday
    {day=>18, hour=>10, minute=>1,  expect_channel=>undef, expect_action=> undef}, #friday
    {day=>18, hour=>12, minute=>1,  expect_channel=>undef, expect_action=> undef}, #friday
    {day=>18, hour=>18, minute=>1,  expect_channel=>undef, expect_action=> undef}, #friday
    {day=>18, hour=>20, minute=>1,  expect_channel=>undef, expect_action=> undef}, #friday
    {day=>18, hour=>21, minute=>59, expect_channel=>undef, expect_action=> undef}, #friday
    {day=>18, hour=>22, minute=>0,  expect_channel=>undef, expect_action=> undef}, #friday
    {day=>18, hour=>23, minute=>59, expect_channel=>undef, expect_action=> undef}, #friday

    {day=>19, hour=>0,  minute=>0,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>0,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>1,  minute=>1,  expect_channel=>2,     expect_action=> OFF  }, #saturday
    {day=>19, hour=>5,  minute=>59, expect_channel=>2,     expect_action=> OFF  }, #saturday
    {day=>19, hour=>6,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #saturday
    {day=>19, hour=>6,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>10, minute=>1,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>12, minute=>1,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>18, minute=>1,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>20, minute=>1,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>21, minute=>59, expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>22, minute=>0,  expect_channel=>undef, expect_action=> undef}, #saturday
    {day=>19, hour=>23, minute=>59, expect_channel=>undef, expect_action=> undef}, #saturday

    {day=>20, hour=>0,  minute=>0,  expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>0,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>1,  minute=>1,  expect_channel=>2,     expect_action=> OFF  }, #sunday
    {day=>20, hour=>5,  minute=>59, expect_channel=>2,     expect_action=> OFF  }, #sunday
    {day=>20, hour=>6,  minute=>0,  expect_channel=>2,     expect_action=> OFF  }, #sunday
    {day=>20, hour=>6,  minute=>1,  expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>10, minute=>1,  expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>12, minute=>1,  expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>18, minute=>1,  expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>20, minute=>1,  expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>21, minute=>59, expect_channel=>undef, expect_action=> undef}, #sunday
    {day=>20, hour=>22, minute=>0,  expect_channel=>2    , expect_action=> OFF  }, #sunday
    {day=>20, hour=>23, minute=>59, expect_channel=>2    , expect_action=> OFF  }, #sunday

];

for my $test ( @$tests) {

    $override_channel = undef;
    $override_action  = undef;
    my $dt = DateTime->new(
          year      => 2016,
          month     => 3,
          day       => $test->{day},
          hour      => $test->{hour},
          minute    => $test->{minute},
        );

    my $expect_str = defined $test->{expect_channel} ? $test->{expect_channel} : 'undef';
    $expect_str   .= ", ";
    $expect_str   .= defined $test->{expect_action} ? $test->{expect_action} : 'undef';

    diag ("testing ".$dt->day_name." ".$dt->strftime('%F %T')." . expect = $expect_str");

    Khaospy::ControlPiBoilerHomeEasy::_run_rules( $dt, $rules );

    if ( defined $test->{expect_channel} ){
        ok( $override_channel == $test->{expect_channel} );
    } else {
        ok( ! defined $override_channel  );
    }

    if ( defined $test->{expect_action} ){
        ok( $override_action eq $test->{expect_action} );
    } else {
        ok( ! defined $override_action );
    }

}

