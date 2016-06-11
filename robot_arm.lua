local socket = require("socket")
local tcp_socket = socket.tcp()

robot_arm = {}

local meta_table = {
  ip = "127.0.0.1", 
  port = 9876,
  timeout = 60, 
  speed = 1.0, 
  connected = false,
  __newindex = function(table, key, value)
    if key == "timeout" then
      timeout = value
      tcp_socket:settimeout(value)
    elseif key == "speed" then
      if value < 0.0 or value > 1.0 or type(value) ~= "number" then
        value_error()
      else 
        set_speed(value)
        speed = value
      end
    elseif key == "ip" then
      ip = value
    elseif key == "port" then
      port = value
    else
      rawset(table, key, value)
    end
  end,
  
  __index = function(table, key)
    if key == "timeout" then
      return timeout
    elseif key == "speed" then
      return speed
    elseif key == "ip" then
      return ip
    elseif key == "port" then
      return port
    else
      return rawget(table, key)
    end
  end
}


function protocol_error(response, expected)
  error("Server responded with '"..response.."' but expected '"..expected.."'.", 2) -- 5 sends stacktrace back to demo.lua
end

function socket_error(connected, serverClosed)
  serverClosed = serverClosed or false
  if serverClosed then
    error("Server has gone byebye.", 2)
  end
  if not connected then
    error("You already closed the connection with the RobotArm.", 2)
  else
    error("Could not connect to the RobotArm. Is the RobotArm server running on ip '"..robot_arm.ip.."' and port '"..robot_arm.port.."'?", 2)
  end
end

function timeout_error(timeout)
  error("The RobotArm took more than "..timeout.." seconds to respond.", 2)
end

function value_error()
  error("The specified speed is not between 0.0 and 1.0.", 2)
end



local function receive()
  data, err = tcp_socket:receive()
  
  if data == "bye" then
    socket_error(meta_table.connected, true)
  end
  
  if err == "timeout" then
    timeout_error(robot_arm.timeout)
  elseif err == "closed" then
    socket_error(meta_table.connected)
  end  
  
  return data
end

local function send(message)
  result, err = tcp_socket:send(message.."\n")
  
  if err ~= nil then
    socket_error(meta_table.connected)
  end
  
  return receive()
end

local function connect_socket(ip, port)
  result, err = tcp_socket:connect(ip, port)
  if result ~= 1 then
    socket_error(true)
  else
    meta_table.connected = true
  end
end


local function contains(table, val)
   for i=1,#table do
      if table[i] == val then 
         return true
      end
   end
   return false
end

local function check_response(response, expected, allowed)
  if response ~= nil then
    correct_resp = true
    response = string.gsub(response, "\n", "")
    if not contains(allowed, response) then
      correct_resp = false
      protocol_error(response, expected)
    end
  else
    protocol_error(response, expected)
  end
end


function robot_arm:connect(ip, port)
  if meta_table.connected then
    robot_arm:close_connection()
  end
  
  ip = ip or "127.0.0.1"
  port = port or 9876
  
  robot_arm.ip = ip
  robot_arm.port = port
  
  connect_socket(ip, port)
  
  response = receive()
  check_response(response, "hello", {"hello"})
end

function robot_arm:move_left()
  response = send("move left")
  check_response(response, "ok", {"ok","bye"})
end

function robot_arm:move_right()
  response = send("move right")
  check_response(response, "ok", {"ok","bye"})
end

function robot_arm:grab()
  response = send("grab")
  check_response(response, "ok", {"ok","bye"})
end

function robot_arm:drop()
  response = send("drop")
  check_response(response,"ok",{"ok","bye"})
end

function robot_arm:scan()
  response = send("scan")
  check_response(response, "a color", {"red","blue","green","white","none","bye"})
  
  if response == "red" or response == "blue" or response == "green" or response == "white" then
    return robot_arm.colors[response]
  else
    return nil
  end
end

function robot_arm:random_level()
  robot_arm:load_level("random")
end

function robot_arm:load_level(name)
  response = send("load "..name)
  check_response(response, "ok", {"ok","wrong","bye"})
end

function set_speed(speed)
  response = send("speed "..tostring(speed*100))
  check_response(response, "ok", {"ok","bye"})
end

function robot_arm:close_connection()
  tcp_socket:close()
  tcp_socket = socket.tcp()
  meta_table.connected = false
end


setmetatable(robot_arm, meta_table)

robot_arm.colors = { red="red", green="green", blue="blue", white="white", none="none" }

robot_arm:connect()

return robot_arm
