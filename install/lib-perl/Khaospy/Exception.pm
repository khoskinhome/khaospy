package Khaospy::Exception;
use strict;
use warnings;

use Exception::Class (

    'KhaospyExcept::InvalidDaemonScriptName',

    'KhaospyExcept::ControlsConfig',
    'KhaospyExcept::ControlDoesnotExist',
    'KhaospyExcept::ControlsConfigNoType',
    'KhaospyExcept::ControlsConfigInvalidType',

    'KhaospyExcept::ControlsConfigUnknownKeys',
    'KhaospyExcept::ControlsConfigNoKey',
    'KhaospyExcept::ControlsConfigKeysInvalidValue',

    'KhaospyExcept::PiHostsNoValidGPIO',
    'KhaospyExcept::PiHostsDaemonNotOnHost',
    'KhaospyExcept::ControlsConfigInvalidGPIO',
    'KhaospyExcept::ControlsConfigDuplicateGPIO',

    'KhaospyExcept::PiHostsNoValidI2CBus',
    'KhaospyExcept::ControlsConfigInvalidI2CBus',
    'KhaospyExcept::ControlsConfigDuplicateMCP23017GPIO',

    'KhaospyExcept::ControlsConfigHostUnresovlable',

    'KhaospyExcept::ShellCommand',

    'KhaospyExcept::UnhandledControl',

);


1;

