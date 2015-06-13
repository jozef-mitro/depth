function love.load(args)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  player = {}
  player.x = love.window.getWidth() / 2
  player.y = love.window.getHeight() / 2
  player.dx = 0
  player.dy = 0
  player.acceleration = 1.0e2
  player.drag = 2.5e-1
  player.size = 32
  
  prey = {} 
  prey.x = 100
  prey.y = 100
  prey.dx = 0
  prey.dy = 0
  prey.acceleration = 1.0e2
  prey.drag = 2.5e-1
  prey.size = 16
  
  predator = {} 
  predator.x = 600
  predator.y = 300
  predator.dx = 0
  predator.dy = 0
  predator.acceleration = 1.0e2
  predator.drag = 2.5e-1
  predator.size = 64
end

function love.update(dt)
  if love.keyboard.isDown("w") then
    player.dy = player.dy - player.acceleration * dt
  end
  
  if love.keyboard.isDown("a") then
    player.dx = player.dx - player.acceleration * dt
  end
  
  if love.keyboard.isDown("s") then
    player.dy = player.dy + player.acceleration * dt
  end
  
  if love.keyboard.isDown("d") then
    player.dx = player.dx + player.acceleration * dt
  end

  player.dx = player.dx - player.dx * player.drag * dt
  player.x = player.x + player.dx * dt
  
  player.dy = player.dy - player.dy * player.drag * dt
  player.y = player.y + player.dy * dt
end

function love.draw() 
  -- Draw prey
  love.graphics.setColor(0, 255, 0)
  love.graphics.circle("fill", prey.x, prey.y, prey.size / 2)
  
  -- Draw player
  love.graphics.setColor(255, 255, 255)
  love.graphics.circle("fill", player.x, player.y, player.size / 2)
  
  -- Draw predator
  love.graphics.setColor(255, 0, 0)
  love.graphics.circle("fill", predator.x, predator.y, predator.size / 2)
end

function circlesOverlap(circle1, circle2)
  local x1 = circle1.x
  local x2 = circle2.x
  local y1 = circle1.y
  local y2 = circle2.y
  local r1 = circle1.size / 2
  local r2 = circle2.size / 2
  
  local distanceSquared = math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2)
  
  return distanceSquared < math.pow(r2 - r1, 2)
end