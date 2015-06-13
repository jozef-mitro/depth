function love.load(args)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  playerX = love.window.getWidth() / 2
  playerY = love.window.getHeight() / 2
  playerDX = 0;
  playerDY = 0;
  playerAcceleration = 1.0e2
  playerDrag = 2.5e-1
  playerSize = 16
end

function love.update(dt)
  if love.keyboard.isDown("w") then
    playerDY = playerDY - playerAcceleration * dt
  end
  
  if love.keyboard.isDown("a") then
    playerDX = playerDX - playerAcceleration * dt
  end
  
  if love.keyboard.isDown("s") then
    playerDY = playerDY + playerAcceleration * dt
  end
  
  if love.keyboard.isDown("d") then
    playerDX = playerDX + playerAcceleration * dt
  end

  playerDX = playerDX - playerDX * playerDrag * dt
  playerX = playerX + playerDX * dt
  
  playerDY = playerDY - playerDY * playerDrag * dt
  playerY = playerY + playerDY * dt
end

function love.draw()
  love.graphics.circle("fill", playerX, playerY, playerSize / 2);
end