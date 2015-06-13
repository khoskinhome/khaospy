#./install/libpy/khaospy/pi2cMultiLightSingleWayManual.py
#./install/libpy/test.py

class Device(object):

#    def __init__(self) :
#        return

    def getSwitchMainsState(self) :
        # returns the state of the mains voltage switch.  ( on(true) or off(false) )
        print ("pi2cMultiLightSingleWayManual.getSwitchMainsState")
        return False

    def getSwitchExtraState(self) :
        # returns the state of the extra low voltage switch. ( on(true) or off(false) )
        print ("pi2cMultiLightSingleWayManual.getSwitchExtraState")
        return False

    def pollMainsDetector():
        print ("pi2cMultiLightSingleWayManual.pollMainsDetector")

#    def pollSwitchAndToggle(self) :
#        # polls the state of Li
#        print ("pi2cMultiLightSingleWayManual.pollSwitchAndToggle")
#        return False

    def areLightsMainlyOn(self) :
        # should this be called "isLightsMainlyOn" ? that sounds wrong to me.
        # returns True or False. If 5 lights out of a possible 9 are "ON" this returns True. If 4 lights out of a possible 9 are "ON" this method returns False.
        print ("pi2cMultiLightSingleWayManual.areLightsMainlyOn")
        return False

    # if the list-of-lights isn't defined in the following method calls, the default is ALL lights.

    def getLightState ( self, list_of_lights ) :
        # returns an array of 1 or more lights state ( on(true) or off(false) ) . This is a calculated value. ( not the 240v-detector-state ) .
        print ("pi2cMultiLightSingleWayManual.getLightState %r " % list_of_lights )
        return False

    def setLightOn ( self, list_of_lights ) :
        print ("pi2cMultiLightSingleWayManual.setLightOn")
        return False

    def setLightOff ( self, list_of_lights ) :
        print ("pi2cMultiLightSingleWayManual.setLightOff")
        return False

    def setLightToggle ( self, list_of_lights ) :
        print ("pi2cMultiLightSingleWayManual.setLightToggle")
        return False
        #  ( swaps light from current state. if light is on, this method switches it off )
