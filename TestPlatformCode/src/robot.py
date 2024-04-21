from arpirobot.core.robot import BaseRobot
from arpirobot.core.log import Logger
from arpirobot.core.action import ActionManager
from arpirobot.core.network import NetworkTable

from arpirobot.devices.adafruitmotorhat import AdafruitMotorHatMotor
from arpirobot.devices.drv8833 import DRV8833Module
from arpirobot.devices.gpio import StatusLED
from arpirobot.devices.gamepad import Gamepad

from arpirobot.arduino.iface import ArduinoUartInterface
from arpirobot.arduino.sensor import VoltageMonitor

# Expected functionality:
#   Gamepad left stick Y axis moves motors on motor hat
#   Gamepad right trigger moves DRV8833 motor
#   Status LED works
#   Voltage monitor via arduino reports main batt voltage

# Choose one
board = "rpi"
# board = "opi3b"
# board = "opizero2w"


class Robot(BaseRobot):
    def __init__(self):
        global board
        super().__init__()

        # Arduino: /dev/ttyUSB0
        #   Vmon: A0
        # DRV8833: Motor A in use
        #   SLP: Physical pin 11
        #   Ain1: Physical pin 13
        #   Ain2: Physical pin 15
        # Status LED: Physical pin 16
        # Motor Hat: Motors 1 & 4
        #   Uses standard position i2c (physical 3 and 5)
        #   should work with Io's default i2c bus

        if board == "rpi":
            SPL_PIN = 17
            AIN1_PIN = 27
            AIN2_PIN = 22
            LED_PIN = 23
        elif board == "opi3b":
            SPL_PIN = 118
            AIN1_PIN = 128
            AIN2_PIN = 130
            LED_PIN = 131
        elif board == "opizero2w":
            SPL_PIN = 226
            AIN1_PIN = 227
            AIN2_PIN = 261
            LED_PIN = 270
        
        self.arduino = ArduinoUartInterface("/dev/ttyUSB0", 57600)
        self.vmon = VoltageMonitor("A0", 5.00, 30000, 7500)
        self.m1 = AdafruitMotorHatMotor(1)
        self.m4 = AdafruitMotorHatMotor(4)
        self.drv8833 = DRV8833Module(AIN1_PIN, AIN2_PIN, -1, -1, SPL_PIN)
        self.ma = self.drv8833.get_motor_a()
        self.led = StatusLED(LED_PIN)
        self.gp0 = Gamepad(0)

    
    def robot_started(self):
        self.arduino.add_device(self.vmon)
        self.arduino.begin()
        self.vmon.make_main_vmon()

    def robot_stopped(self):
        pass

    def robot_enabled(self):
        pass

    def robot_disabled(self):
        pass

    def enabled_periodic(self):
        drive = self.gp0.get_axis(1)
        other = self.gp0.get_axis(5)
        self.m1.set_speed(drive)
        self.m4.set_speed(drive)
        self.ma.set_speed(other)

    def disabled_periodic(self):
        pass

    def periodic(self):
        self.feed_watchdog()
