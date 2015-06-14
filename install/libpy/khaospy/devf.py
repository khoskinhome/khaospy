
import khaospy
# import all the packages that contain the "Device" classes
# ./install/libpy/khaospy/mcp23017MultiLightSingleWayManual.py
from khaospy import mcp23017MultiLightSingleWayManual

# ./install/libpy/khaospy/mcp23017SingleLightTwoWayManual.py
from khaospy import mcp23017SingleLightTwoWayManual

## ./install/libpy/khaospy/mcp23017BoilerRadiator.py
from khaospy import mcp23017BoilerRadiator
#
##### import khaospy.mcp23017TSL2561LightSensor ## not sure about the light sensor I have.
#
## ./install/libpy/khaospy/mcp23017DoorWindowSwitch.py
from khaospy import mcp23017DoorWindowSwitch
#
## ./install/libpy/khaospy/mcp23017PIRSwitch.py
from khaospy import mcp23017PIRSwitch
#
## ./install/libpy/khaospy/oneWireTemperatureSensor.py
from khaospy import oneWireTemperatureSensor


def factory( deviceConfig ):
    """
    khaospy.factory.Device

    makes a khaos "Device" where a device is a light controller, temperature sensor just some home-auto object.

    """
    typeHomeAutoClass = deviceConfig["HomeAutoClass"]
    if typeHomeAutoClass == "khaospy.mcp23017MultiLightSingleWayManual.Device" :
        return khaospy.mcp23017MultiLightSingleWayManual.Device( deviceConfig )

    elif typeHomeAutoClass == "khaospy.mcp23017SingleLightTwoWayManual.Device" :
        return khaospy.mcp23017SingleLightTwoWayManual.Device( deviceConfig )

    elif typeHomeAutoClass ==  "khaospy.mcp23017BoilerRadiator.Device":
        return  khaospy.mcp23017BoilerRadiator.Device( deviceConfig )

    elif typeHomeAutoClass ==  "khaospy.mcp23017DoorWindowSwitch.Device":
        return  khaospy.mcp23017DoorWindowSwitch.Device( deviceConfig )

    elif typeHomeAutoClass ==  "khaospy.mcp23017PIRSwitch.Device":
        return  khaospy.mcp23017PIRSwitch.Device( deviceConfig )

    elif typeHomeAutoClass ==  "khaospy.oneWireTemperatureSensor.Device":
        return  khaospy.oneWireTemperatureSensor.Device( deviceConfig )

    # TODO could do with a proper exception here :
    assert 0, "Bad typeHomeAutoClass: " + typeHomeAutoClass


