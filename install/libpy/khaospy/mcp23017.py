
class port(object):
    # a single port on a MCP23017 chip
    """
    a single port on an MCP23017.

    has
      "i2cbus" : 0,
      "i2cAddress" : "0x27",

      "enabled" : 0,
      "inORout" : 1,
      "current_state" : 1,
      "portnum" : 2,
      "port" : "a"

    """




##############################################################
# should I use smbus or quick2wire ?  dunno.

class collection(object):
    """
    Has all the mcp23017 ports, on all the mcp23017 chips. ( using the mcp23017.port class )

    One Raspberry Pi can support up to 8 MCP23017 chips with i2cAddresses in
    the range of 0x20 -> 0x27
    """

    # a collection of mcp23017 ports on one or more mcp23017 chips.

    def poll():
        """
        polls all the ports, which means :
        outputs are pushed to the MCP23017 chip(s)
        inputs  are got from the MCP23017 chip(s)
        """


