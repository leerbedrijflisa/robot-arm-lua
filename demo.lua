local robot_arm = require("robot_arm")

robot_arm:connect("127.0.0.1", 9876)

robot_arm.speed = 0.5
robot_arm.timeout = 10

while true do 
  robot_arm:move_left()
end