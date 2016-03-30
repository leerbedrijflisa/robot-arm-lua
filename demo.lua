local robot_arm = require("robot_arm")

robot_arm:connect("127.0.0.1", 9876)

robot_arm.speed = 1.0 -- server has to scale 0-1 to 0-100
robot_arm.timeout = 10

robot_arm:load_level("bas/tower")

robot_arm:move_left()
robot_arm:grab()

colors = robot_arm.colors
color = robot_arm.scan()

if color == colors.red or color == colors.blue then
  robot_arm:move_right()
else
  robot_arm:move_left()
end

robot_arm:drop()