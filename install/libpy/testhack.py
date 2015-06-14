#!/usr/bin/python

import smbus
import time
 
i2cbus = smbus.SMBus(0)  # Rev 1 Pi uses 0
#i2cbus = smbus.SMbus(1)  # Rev 2 Pi uses 1
 
i2cAddress = 0x27 # Device address (A0-A2)
IODIRA = 0x00 # Pin direction register
IODIRB = 0x01 # Pin direction register

OLATA  = 0x14 # Register for outputs
#OLATB = 

GPIOA  = 0x12 # Register for inputs
#GPIOB = 

"""
my $mcp23017_registers = {
    IODIRA => '0x00', # IODIR A/B are used to set the direction of the gpio pin 0 for output, 1 for input.
    IODIRB => '0x01',

    GPIOA  => '0x12', # GPIO A/B are used to get the input on a gpio port
    GPIOB  => '0x13',

    OLATA  => '0x14', # OLAT A/B are used to switch on and off the outputs on a gpio port.
    OLATB  => '0x15',
};

i2cset  -y 0 0x27 0x00 0x06
i2cset  -y 0 0x27 0x01 0x0c

Dumper of i2cset register =$VAR1 = {
          '-y 0' => {
                      '0x27' => {
                                  '0x15' => 237,
                                  '0x14' => 230
                                }
                    }
        };
"""

# Set all GPA pins as outputs by setting
# all bits of IODIRA register to 0
i2cbus.write_byte_data(i2cAddress,IODIRA,0x06)
i2cbus.write_byte_data(i2cAddress,IODIRB,0x0c)
 
# Set output all 7 output bits to 0
i2cbus.write_byte_data(i2cAddress,OLATA,0)
 
for MyData in range(1,8):
  # Count from 1 to 8 which in binary will count
  # from 001 to 111
  i2cbus.write_byte_data(i2cAddress,OLATA,MyData)
  print (MyData)
  time.sleep(1)
 
# Set all bits to zero
i2cbus.write_byte_data(i2cAddress,OLATA,0)
