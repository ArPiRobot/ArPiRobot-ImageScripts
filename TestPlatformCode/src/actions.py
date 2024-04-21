from arpirobot.core.action import Action, LockedDeviceList
from arpirobot.core.log import Logger
import main


# Create actions here
# Each action must have 4 functions. Use the template below.
# An optional 5th function (locked_devices) is 
# available if an action needs exclusive control of a device

# You can refer to the current instance of your Robot class using main.robot

"""
class MyAction(Action):
    # Add arguments to the constructor if needed
    def __init__(self):
        # Make sure this is always the first line of the constructor
        super().__init__()

        # Store arguments as member variables here if necessary

    def locked_devices(self) -> LockedDeviceList:
        # If an action needs exclusive control of devices, lock them here
        return []

    def begin(self):
        # Run when the action is started
        pass

    def process(self):
        # Run periodically while the action is running
        pass

    def finish(self, was_interrupted: bool):
        # Run when the action is stopped
        # was_interrupted will be True if the action did not stop on its own (see should_continue)
        pass
    
    def should_continue(self) -> bool:
        # The action will stop itself when this returns False
        # This is run after each time process() runs to determine if the action should stop
        return False
"""