function createCircle(x, y, radius)
  newCircle = {}
  newCircle.x = x
  newCircle.y = y
  newCircle.radius = radius
  
  return newCircle
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
  local r1 = circle1.radius
  local r2 = circle2.radius
  
  local distanceSquared = math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2)
  
  return distanceSquared < math.pow(r2 + r1, 2)
end

function calulacteCircleVolume(radius)
  return math.pi * math.pow(radius, 2)
end

function calulacteCircleRadius(volume)
  return math.sqrt(volume / math.pi)
end