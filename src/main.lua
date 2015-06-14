require "circle"
require "timer"

function love.load(args)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  ECHO_GROWTH = 500 -- growth of radius in pixels per second
  ECHO_MAX_RADIUS = 1000 
  
  ENTITY_MIN_RADIUS = 8
  ENTITY_MAX_RADIUS = 64
  ENTITY_PREY_COLOR = {0, 255, 0, 255}
  ENTITY_PREDATOR_COLOR = {255, 0, 0, 255}
  
  EAT_SOUND = love.audio.newSource("gulp.wav", "static")
  ECHO_SOUND = love.audio.newSource("echo.wav", "static")
  camera = {}
  camera.x = 0
  camera.y = 0
  
  initWorld()
  
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

function love.keypressed(key, isrepeat)
  if key == "r" then
    initWorld()
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

  updateEntityPosition(player, dt)
  
  if love.keyboard.isDown(" ") and player.echoTimer.time == 0 then
    emitEcho(player)
    ECHO_SOUND:play()
    resetTimer(player.echoTimer)
  end
  
  updateTimer(player.echoTimer, dt)
  
  if player.radius <= ENTITY_MIN_RADIUS then
    initWorld()
  end
  
  -- Update echoes
  for echo, _ in pairs(echoes) do
    echo.radius = echo.radius + ECHO_GROWTH * dt
    -- Update alpha
    echo.color[4] = math.max(255 - (echo.radius / ECHO_MAX_RADIUS) * 255, 0)
    
    if echo.owner == player then
      for entity, _ in pairs(entities) do
        if circlesCollide(echo, entity) and
          not echo.echoedFrom[entity] then
          emitEcho(entity)
          echo.echoedFrom[entity] = true
        end
      end
    end
    
    if echo.radius > ECHO_MAX_RADIUS then
      echoes[echo] = nil
    end
  end
  
  -- Update entities
  for entity, _ in pairs(entities) do    
    updateEntityPosition(entity, dt)
    
    local distanceToPlayer = getDistance(player.x, player.y, entity.x, entity.y)
    local accelerationWeight = math.max(1 - (distanceToPlayer / 256), 0) 
    local angleToPlayer = math.atan2(player.y - entity.y, player.x - entity.x)
    
    if entity.type == "prey" then
      entity.dx = entity.dx -
        math.cos(angleToPlayer) * entity.acceleration * accelerationWeight * dt
      entity.dy = entity.dy -
        math.sin(angleToPlayer) * entity.acceleration * accelerationWeight * dt
    elseif entity.type == "predator" then
      entity.dx = entity.dx +
        math.cos(angleToPlayer) * entity.acceleration * accelerationWeight * dt
      entity.dy = entity.dy +
        math.sin(angleToPlayer) * entity.acceleration * accelerationWeight * dt
    end
    
    if circlesCollide(player, entity) then
      if entity.type == "prey" then
        eatEntity(player, entity)
        if entity.radius < 2 then
          entities[entity] = nil
          world.blobsLeft = world.blobsLeft - 1
          
          if world.blobsLeft == 0 then
            initWorld()
          end
        end
      elseif entity.type == "predator" then
        eatEntity(entity, player)
      end
    end
    
    updateEntityType(entity, dt)
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
      love.graphics.circle("fill", entity.x, entity.y, entity.radius)
    end
    
    -- Draw player
    love.graphics.setColor(player.color)
    love.graphics.circle("fill", player.x, player.y, player.radius)
  love.graphics.pop()
  
  local windowHeight = love.window.getHeight()
  fovShader:send("playerX", player.x - camera.x)
  fovShader:send("playerY", windowHeight - (player.y - camera.y))
  fovShader:send("playerRadius", player.radius)
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
      love.graphics.circle("line", echo.x, echo.y, echo.radius)
    end
  love.graphics.pop()
  
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Blobs left: " .. world.blobsLeft, 32, 32)
end

function emitEcho(entity)
  local newEcho = createCircle(entity.x, entity.y, entity.radius)
  newEcho.owner = entity
  newEcho.echoedFrom = {}
  newEcho.color = {}
  
  for partKey, colorPart in pairs(entity.color) do
    newEcho.color[partKey] = colorPart
  end
    
  echoes[newEcho] = true 
end

function updateEntityType(entity)
  if entity.radius < player.radius then
    entity.type = "prey"
    entity.color = ENTITY_PREY_COLOR
  else
    entity.type = "predator"
    entity.color = ENTITY_PREDATOR_COLOR
  end
end

function updateEntityPosition(entity, dt)
  entity.dx = entity.dx - entity.dx * entity.drag * dt
  entity.x = entity.x + entity.dx * dt
  
  entity.dy = entity.dy - entity.dy * entity.drag * dt
  entity.y = entity.y + entity.dy * dt
  
  -- bound entity to playable area
  if entity.x < entity.radius then
    entity.x = entity.radius
    entity.dx = 0
  end
  
  if entity.x > world.width - entity.radius then
    entity.x = world.width - entity.radius
    entity.dx = 0
  end
  
  if entity.y < entity.radius then
    entity.y = entity.radius
    entity.dy = 0
  end
  
  if entity.y > world.height - entity.radius then
    entity.y = world.height - entity.radius
    entity.dy = 0
  end
end

function eatEntity(biggerEntity, smallerEntity)
  local x1 = biggerEntity.x
  local x2 = smallerEntity.x
  local y1 = biggerEntity.y
  local y2 = smallerEntity.y
  local r1 = biggerEntity.radius
  local r2 = smallerEntity.radius
  local v1 = calulacteCircleVolume(r1)
  local v2 = calulacteCircleVolume(r2)
  
  local distance = getDistance(x1, y1, x2, y2)
  
  local newR2 = distance - r1
  local newV2 = calulacteCircleVolume(newR2)
  -- only grow by fraction of eaten mass
  local newV1 = v1 + 0.25 * (v2 - newV2)
  local newR1 = calulacteCircleRadius(newV1)
  
  biggerEntity.radius = newR1
  smallerEntity.radius = newR2
  
  if not EAT_SOUND:isPlaying() then
    EAT_SOUND:play()
  end
end

function getDistance(x1, y1, x2, y2)
  return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
end

function initWorld()
  world = {}
  world.width = 4000
  world.height = 3000
  world.blobsLeft = 32
  
  player = createCircle(100, 100, 16)
  player.dx = 0
  player.dy = 0
  player.acceleration = 3.0e2
  player.drag = 9.0e-1
  player.color = {255, 255, 255, 255}
  player.echoTimer = createTimer(1, true)
  
  echoes = {}
  
  entities = {}
  for i = 1, world.blobsLeft do
    local randomX = math.random(world.width)
    local randomY = math.random(world.height)
    local radius = (randomY / world.height) * (ENTITY_MAX_RADIUS - ENTITY_MIN_RADIUS)
    radius = radius * (math.random() + 0.5) + ENTITY_MIN_RADIUS
    local newEntity = createCircle(randomX, randomY, radius)
    newEntity.dx = 0
    newEntity.dy = 0
    newEntity.acceleration = 3.0e2
    newEntity.drag = 9.0e-1
    updateEntityType(newEntity)
    
    entities[newEntity] = true;
  end
end