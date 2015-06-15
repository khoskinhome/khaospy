
class port(object):
    # a single port for a one wire device
    """
    a single port for a one wire device .
    """


##############################################################
# should I use smbus or quick2wire ?  dunno.

class collection(object):
    """
    Has all the one wire ports
    """

    @classmethod
    def poll(cls):
        """
        polls all the ports, which means :
        outputs are pushed to the one wire devices
        inputs are pushed to the one wire devices
        """

    @classmethod
    def addPorts(cls, deviceConfig):
        print ( "addPorts called with " + deviceConfig )
