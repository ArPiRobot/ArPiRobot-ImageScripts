robot: 'robot_mod.Robot' = None

import robot as robot_mod

if __name__ == "__main__":
    import main # No this is not redundant!
    main.robot = robot_mod.Robot()
    main.robot.start()