function love.load(args)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  world = {}
  world.width = 8000
  world.height = 6000
  
  player = {}
  player.x = 100
  player.y = 100
  player.dx = 0
  player.dy = 0
  player.acceleration = 3.0e2
  player.drag = 9.0e-1
  player.size = 32
  player.color = {255, 255, 255, 255}
  player.echoTimer = 0
  player.echoCooldown = 1
  
  camera = {}
  camera.x = 0
  camera.y = 0
  
  ECHO_GROWTH = 640
  ECHO_MAX_SIZE = 3200 
  echoes = {}
  
  prey = {}
  for i = 1, 32 do
    local newPrey = {}
    newPrey.x = math.random(world.width)
    newPrey.y = math.random(world.height)
    newPrey.dx = 0
    newPrey.dy = 0
    newPrey.acceleration = 1.0e2
    newPrey.drag = 2.5e-1
    newPrey.size = 8
    newPrey.color = {0, 255, 0, 255}
    prey[newPrey] = true;
  end
  
  predators = {} 
  for i = 1, 32 do
    local newPredator = {}
    newPredator.x = math.random(world.width)
    newPredator.y = math.random(world.height)
    newPredator.dx = 0
    newPredator.dy = 0
    newPredator.acceleration = 1.0e2
    newPredator.drag = 2.5e-1
    newPredator.size = 64
    newPredator.color = {255, 0, 0, 255}
    predators[newPredator] = true
  end
end

function love.update(dt)
  -- Update player
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
  
  -- Update echoes
  for echo, _ in pairs(echoes) do
    echo.size = echo.size + ECHO_GROWTH * dt
    -- Update alpha
    echo.color[4] = math.max(255 - (echo.size / ECHO_MAX_SIZE) * 255, 0)
    
    if echo.owner == player then
      for preyInstance, _ in pairs(prey) do
        if circlesCollide(echo, preyInstance) and
          not echo.echoedFrom[preyInstance] then
          emitEcho(preyInstance)
          echo.echoedFrom[preyInstance] = true
        end
      end
      
      for predator, _ in pairs(predators) do
        if circlesCollide(echo, predator) and
          not echo.echoedFrom[predator]  then
          emitEcho(predator)
          echo.echoedFrom[predator] = true
        end
      end
    end
    
    if echo.size > ECHO_MAX_SIZE then
      echoes[echo] = nil
    end
  end
  
  -- Update prey
  for preyInstance, _ in pairs(prey) do
    if circlesOverlap(player, preyInstance) then
      prey[preyInstance] = nil
    end
  end
  
  -- Update camera
  local windowWidth = love.window.getWidth()
  camera.x = math.max(player.x - windowWidth / 2, 0)
  camera.x = math.min(camera.x, world.width)
  
  local windowHeight = love.window.getHeight()
  camera.y = math.max(player.y - windowHeight / 2, 0)
  camera.y = math.min(camera.y, world.height)
end

function love.draw() 
  love.graphics.setBackgroundColor(32 * (1 - (camera.y / world.height)),
    64 * (1 - (camera.y / world.height)),
    128 * (1 - (camera.y / world.height)))
  
  love.graphics.push()
  love.graphics.translate(-camera.x, -camera.y)
  
    -- Draw prey
    for preyInstance, _ in pairs(prey) do
      love.graphics.setColor(preyInstance.color)
      love.graphics.circle("fill", preyInstance.x, preyInstance.y,
        preyInstance.size / 2)
    end
    
    -- Draw player
    love.graphics.setColor(player.color)
    love.graphics.circle("fill", player.x, player.y, player.size / 2)
    
    -- Draw predator
    for predator, _ in pairs(predators) do
      love.graphics.setColor(predator.color)
      love.graphics.circle("fill", predator.x, predator.y,
        predator.size / 2)
    end
    
    -- Draw echoes
    for echo, _ in pairs(echoes) do
      love.graphics.setColor(echo.color)
      love.graphics.circle("line", echo.x, echo.y, echo.size / 2)
    end
  love.graphics.pop()
  
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(love.timer.getFPS(), 32, 32)
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