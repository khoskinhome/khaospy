package Khaospy::WebUI::Constants;
use strict; use warnings;

use Exporter qw/import/;

# in seconds :
our $PASSWORD_RESET_TIMEOUT = 3600;

our $DANCER_BASE_URL = '/dancer';

our @EXPORT_OK = qw(
    $PASSWORD_RESET_TIMEOUT
    $DANCER_BASE_URL
);

1;
