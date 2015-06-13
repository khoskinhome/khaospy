#./install/libpy/khaospy/pi2cSingleLightTwoWayManual.py
#./install/libpy/test.py

# In the following file "Mains" == 240v Mains ( i.e. not low voltage )

import khaospyUtils

class Device(object):

    def __init__(self) :
        return

    def getSwitchMainsState(self) :
        # throws an error.
        raise khaospyUtils.Kaboom("Pi2cSingleLightTwoWayManual cannot getSwitchMainsState")

    def getSwitchExtraState(self) :
        # returns the state of the extra low voltage switch. ( on(true) or off(false) )
        print ("Pi2cSingleLightTwoWayManual.getSwitchExtraState")
        return False

    def pollMainsDetector(self):
        print ("Pi2cSingleLightTwoWayManual.pollMainsDetector")
        return True;

#    def pollSwitchAndToggle(self) :
#        # polls the state of Li
#        print ("Pi2cSingleLightTwoWayManual.pollSwitchAndToggle")
#        return False

#    def areLightsMainlyOn(self) :
#        # should this be called "isLightsMainlyOn" ? that sounds wrong to me.
#        # returns True or False. If 5 lights out of a possible 9 are "ON" this returns True. If 4 lights out of a possible 9 are "ON" this method returns False.
#        print ("Pi2cSingleLightTwoWayManual.areLightsMainlyOn")
#        return False

    # if the list-of-lights isn't defined in the following method calls, the default is ALL lights.

    def getLightState ( self ) :
        # returns an the state of the Light ( on(true) or off(false) ) . This is what the 240v-detector detects
        print ("Pi2cSingleLightTwoWayManual.getLightState" )
        return False

    def setLightOn ( self ) :
        print ("Pi2cSingleLightTwoWayManual.setLightOn")
        return False

    def setLightOff ( self ) :
        print ("Pi2cSingleLightTwoWayManual.setLightOff")
        return False

    def setLightToggle ( self ) :
        print ("Pi2cSingleLightTwoWayManual.setLightToggle")
        return False
        #  ( swaps light from current state. if light is on, this method switches it off )




