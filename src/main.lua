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
  
  ECHO_GROWTH = 800
  ECHO_MAX_SIZE = 2400 
  echoes = {}
  
  ENTITY_MIN_SIZE = 4
  ENTITY_MAX_SIZE = 128
  ENTITY_PREY_COLOR = {0, 255, 0, 255}
  ENTITY_PREDATOR_COLOR = {255, 0, 0, 255}
  
  entities = {}
  for i = 1, 32 do
    local newEntity = {}
    newEntity.x = math.random(world.width)
    newEntity.y = math.random(world.height)
    newEntity.dx = 0
    newEntity.dy = 0
    newEntity.acceleration = 3.0e2
    newEntity.drag = 9.0e-1
    newEntity.size = ENTITY_MIN_SIZE +
      (newEntity.y / world.height) * (ENTITY_MAX_SIZE - ENTITY_MIN_SIZE)
    newEntity.size = newEntity.size * ((math.random() * 0.5) + 0.75)
    updateEntityType(newEntity)
    
    entities[newEntity] = true;
  end
  
  fovShader = love.graphics.newShader[[
    extern number playerX;
    extern number playerY;
    extern number playerRadius;
    extern number depth;
    vec4 effect(vec4 color, Image texture,
    vec2 texture_coords, vec2 screen_coords) {
      vec4 pixel = Texel(texture, texture_coords);
      
      number distance = distance(screen_coords, vec2(playerX, playerY));
      number sh = (1 - depth); // shallowness
      number alpha = (distance - playerRadius) / (640 * sh);
      return pixel * vec4(0.0,0.0,0.0,alpha);
    }
  ]]
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
  
  if player.x < player.size / 2 then
    player.x = player.size / 2
    player.dx = 0
  end
  
  if player.x > world.width - player.size / 2 then
    player.x = world.width - player.size / 2
    player.dx = 0
  end
  
  if player.y < player.size / 2 then
    player.y = player.size / 2
    player.dy = 0
  end
  
  if player.y > world.height - player.size / 2 then
    player.y = world.height - player.size / 2
    player.dy = 0
  end
  
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
      for entity, _ in pairs(entities) do
        if entitiesCollide(echo, entity) and
          not echo.echoedFrom[entity] then
          emitEcho(entity)
          echo.echoedFrom[entity] = true
        end
      end
    end
    
    if echo.size > ECHO_MAX_SIZE then
      echoes[echo] = nil
    end
  end
  
  -- Update entities
  for entity, _ in pairs(entities) do    
    entity.dx = entity.dx - entity.dx * entity.drag * dt
    entity.x = entity.x + entity.dx * dt
    
    entity.dy = entity.dy - entity.dy * entity.drag * dt
    entity.y = entity.y + entity.dy * dt
    
    if entitiesCollide(player, entity) then
      if entity.type == "prey" then
        eatEntity(player, entity)
        if entity.size < 0 then
          entities[entity] = nil
        end
      elseif entity.type == "predator" then
        eatEntity(entity, player)
      end
    end
    
    updateEntityType(entity)
  end
  
  -- Update camera
  local windowWidth = love.window.getWidth()
  camera.x = math.max(player.x - windowWidth / 2, 0)
  camera.x = math.min(camera.x, world.width - windowWidth)
  
  local windowHeight = love.window.getHeight()
  camera.y = math.max(player.y - windowHeight / 2, 0)
  camera.y = math.min(camera.y, world.height - windowHeight)
end

function love.draw() 
  love.graphics.setBackgroundColor(32 * (1 - (camera.y / world.height)),
    64 * (1 - (camera.y / world.height)),
    128 * (1 - (camera.y / world.height)))
  
  love.graphics.push()
  love.graphics.translate(-camera.x, -camera.y)
  
    -- Draw entities
    for entity, _ in pairs(entities) do
      love.graphics.setColor(entity.color)
      love.graphics.circle("fill", entity.x, entity.y, entity.size / 2)
    end
    
    -- Draw player
    love.graphics.setColor(player.color)
    love.graphics.circle("fill", player.x, player.y, player.size / 2)
  love.graphics.pop()
  
  local windowHeight = love.window.getHeight()
  fovShader:send("playerX", player.x - camera.x)
  fovShader:send("playerY", windowHeight - (player.y - camera.y))
  fovShader:send("playerRadius", player.size / 2)
  fovShader:send("depth", player.y / world.height)
  love.graphics.setShader(fovShader)
  love.graphics.rectangle("fill", 0, 0,
    love.window.getWidth(), love.window.getHeight())
  love.graphics.setShader()
  
  love.graphics.push()
  love.graphics.translate(-camera.x, -camera.y)
  
    -- Draw echoes
    for echo, _ in pairs(echoes) do
      love.graphics.setColor(echo.color)
      love.graphics.circle("line", echo.x, echo.y, echo.size / 2)
    end
  love.graphics.pop()
  
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(love.timer.getFPS(), 32, 32)
end

function entitiesOverlap(entity1, entity2)
  local x1 = entity1.x
  local x2 = entity2.x
  local y1 = entity1.y
  local y2 = entity2.y
  local r1 = entity1.size / 2
  local r2 = entity2.size / 2
  
  local distanceSquared = math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2)
  
  return distanceSquared < math.pow(r2 - r1, 2)
end

function entitiesCollide(entity1, entity2)
  local x1 = entity1.x
  local x2 = entity2.x
  local y1 = entity1.y
  local y2 = entity2.y
  local r1 = entity1.size / 2
  local r2 = entity2.size / 2
  
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

function updateEntityType(entity)
  if entity.size < player.size then
    entity.type = "prey"
    entity.color = ENTITY_PREY_COLOR
  else
    entity.type = "predator"
    entity.color = ENTITY_PREDATOR_COLOR
  end
end

function eatEntity(biggerEntity, smallerEntity)
  local x1 = biggerEntity.x
  local x2 = smallerEntity.x
  local y1 = biggerEntity.y
  local y2 = smallerEntity.y
  local r1 = biggerEntity.size / 2
  local r2 = smallerEntity.size / 2
  local v1 = calulacteCircleVolume(r1)
  local v2 = calulacteCircleVolume(r2)
  
  local distance = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
  
  local newR2 = distance - r1
  local newV2 = calulacteCircleVolume(newR2)
  -- only grow by fraction of eaten mass
  local newV1 = v1 + 0.25 * (v2 - newV2)
  local newR1 = calulacteCircleRadius(newV1)
  
  biggerEntity.size = newR1 * 2
  smallerEntity.size = newR2 * 2
end

function calulacteCircleVolume(radius)
  return math.pi * math.pow(radius, 2)
end

function calulacteCircleRadius(volume)
  return math.sqrt(volume / math.pi)
end