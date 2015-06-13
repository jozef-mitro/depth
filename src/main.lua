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
  player.color = {255, 255, 255, 255}
  player.echoTimer = 0
  player.echoCooldown = 1
  
  ECHO_GROWTH = 320
  ECHO_MAX_SIZE = 1280 
  echoes = {}
  
  prey = {} 
  prey.x = 100
  prey.y = 100
  prey.dx = 0
  prey.dy = 0
  prey.acceleration = 1.0e2
  prey.drag = 2.5e-1
  prey.size = 16
  prey.color = {0, 255, 0, 255}
  
  predator = {} 
  predator.x = 600
  predator.y = 300
  predator.dx = 0
  predator.dy = 0
  predator.acceleration = 1.0e2
  predator.drag = 2.5e-1
  predator.size = 64
  predator.color = {255, 0, 0, 255}
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
  
  if love.keyboard.isDown(" ") and player.echoTimer == 0 then
    emitEcho(player)    
    player.echoTimer = player.echoCooldown
  end
  
  player.echoTimer = math.max(player.echoTimer - dt, 0)
  
  for echo, _ in pairs(echoes) do
    echo.size = echo.size + ECHO_GROWTH * dt
    -- Update alpha
    echo.color[4] = math.max(255 - (echo.size / ECHO_MAX_SIZE) * 255, 0)
    
    if echo.owner == player then
      if circlesCollide(echo, prey) and
        not echo.echoedFrom[prey] then
        emitEcho(prey)
        echo.echoedFrom[prey] = true
      end
      
      if circlesCollide(echo, predator) and
        not echo.echoedFrom[predator]  then
        emitEcho(predator)
        echo.echoedFrom[predator] = true
      end
    end
    
    if echo.size > ECHO_MAX_SIZE then
      echoes[echo] = nil
    end
  end
end

function love.draw() 
  love.graphics.setBackgroundColor(0, 0, 32)
  
  -- Draw prey
  love.graphics.setColor(prey.color)
  love.graphics.circle("fill", prey.x, prey.y, prey.size / 2)
  
  -- Draw player
  love.graphics.setColor(player.color)
  love.graphics.circle("fill", player.x, player.y, player.size / 2)
  
  -- Draw predator
  love.graphics.setColor(predator.color)
  love.graphics.circle("fill", predator.x, predator.y, predator.size / 2)
  
  -- Draw echoes
  for echo, _ in pairs(echoes) do
    love.graphics.setColor(echo.color)
    love.graphics.circle("line", echo.x, echo.y, echo.size / 2)
  end
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

function circlesCollide(circle1, circle2)
  local x1 = circle1.x
  local x2 = circle2.x
  local y1 = circle1.y
  local y2 = circle2.y
  local r1 = circle1.size / 2
  local r2 = circle2.size / 2
  
  local distanceSquared = math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2)
  
  return distanceSquared < math.pow(r2 + r1, 2)
end

function emitEcho(entity)
  local newEcho = {}
  newEcho.x = entity.x
  newEcho.y = entity.y
  newEcho.size = entity.size
  newEcho.color = {}
  newEcho.owner = entity
  newEcho.echoedFrom = {}
  
  for partKey, colorPart in pairs(entity.color) do
    newEcho.color[partKey] = colorPart
  end
    
  echoes[newEcho] = true 
end