function createTimer(cooldownLength, startsReady)
  local newTimer = {}
  newTimer.cooldown = cooldownLength

  if startsReady then
    newTimer.time = 0
  else
    newTimer.time = cooldownLength
  end
  
  return newTimer
end

function resetTimer(timer)
  timer.time = timer.cooldown
end

function updateTimer(timer, dt)
  timer.time = math.max(timer.time - dt, 0)
end