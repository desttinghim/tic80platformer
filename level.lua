local level = {}

function level.init()
  return setmetatable({
    x = 0,
    y = 0,
    w = 30,
    h = 17,
    bank = 0, -- ? I may not need this
    levels = {}
  }, {__index = level})
end
-- Load level into memory
function level:load(world, x, y)
  self.x = x * self.w
  self.y = y * self.h

  local index = x + (y * 8)
  data = self.levels[index]

  for i,v in ipairs(data) do
    trace(i..' '..v.t)
    if v.t == "trigger" then
      world:addEntity({
        transform = {
          x = v.x, y = v.y,
        },
        aabb = {
          x = 0, y = 0, w = v.w, h = v.h,
        },
        trigger = v.trigger
      })
    elseif v.t == "lever" then
      world:addEntity({
          transform = {
            x = v.x * 8, y = v.y * 8,
          },
          aabb = {
            x = 0, y = 0, w = 8, h = 8,
          },
          effect = v.effect
      })
    end
  end
end
function level:assert(map, value, expected, msg)
  -- ensure value == expected, or trace msg
  if value ~= expected then
    trace(map.x..','..map.y..": "..msg)
  end
end
function level:assertExists(map, value, msg)
  if not value then
    trace(map.x..','..map.y..": "..msg)
  end
end
function level:assertTile(map, coord, value, msg)
  local tile = mget(map.x + coord.x, map.y + coord.y)
  level:assert(map, tile, value, '('..coord.x..','..coord.y..') '..msg)
end
function level:define(x,y,data)
  -- there is 8 columns per row in the global map
  local index = x + (y * 8)
  self.levels[index] = data
  local map = {x = x * self.w, y = y * self.h}
  for i,v in ipairs(data) do
    if v.t == "trigger" then
      level:assertExists(map, v.x, "missing trigger x")
      level:assertExists(map, v.y, "missing trigger y")
      level:assertExists(map, v.w, "missing trigger w")
      level:assertExists(map, v.h, "missing trigger h")
      level:assertExists(map, v.trigger, "missing trigger component data")
    elseif v.t == "lever" then
      level:assertTile(map, v, 1, "should be a lever")
      level:assertExists(map, v.effect, "missing effect component data")
    end
  end
end


return level
