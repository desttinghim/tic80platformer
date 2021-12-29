-- title:  testing
-- author: desttinghim
-- desc:   trying out tic80
-- script: lua

-- Util
function enum(tbl)
 local len = #tbl
 for i=1,len do
  local v = tbl[i]
  tbl[v] = i
 end
 return tbl
end

-- Animation
F = enum{"INDEX","WAIT","STOP","LOOP"}
Anim = {
 new = function(anim)
  local t = setmetatable({},{__index = Anim})

  t.anim = anim
  t.index = 1
  t.next = 0
  t.frame = 1
  return t
 end,

 play = function(self, i)
  if self.index ~= i then
   self.index = i
   self.next = 0
   self.frame = 1
  end
 end,

 still = function(i)
  return {
   {t=F.INDEX,v=i},
   {t=F.STOP}
  }
 end,
 
 simple = function(len, ilist)
  local a = {}
  for i,v in ipairs(ilist) do
   a[#a+1]={t=F.INDEX,v=v}
   a[#a+1]={t=F.WAIT,v=len}
  end
  a[#a+1]={t=F.LOOP}
  return a
 end,
} -- Anim

-- Actor
Actor = {
 new = function(tbl)
  tbl.index = tbl.index or 255
  tbl.x = tbl.x or 0
  tbl.y = tbl.y or 0
  tbl.xoff = tbl.xoff or 0
  tbl.yoff = tbl.yoff or 0
  tbl.w = tbl.w or 1
  tbl.h = tbl.h or 1
  tbl.scale = tbl.scale or 1
  tbl.rot = tbl.rot or 0
  return tbl
 end,
} -- Actor

Control={
 -- Valid `controller` values:
 --  0,1,2,3 = players 1-4
 --  4+ = AI
 new = function(tbl)
  tbl.controller = tbl.controller
  tbl.left = false
  tbl.right = false
  tbl.up = false
  tbl.down = false
  tbl.anim = tbl.anim or {}
  return tbl
 end
}

Physics={
 new = function(tbl)
  tbl.hbox = tbl.hbox or {top=1, bot=7, left=0, right=8}
  tbl.vbox = tbl.vbox or {top=0, bot=8, left=1, right=7}
  tbl.gravity = tbl.gravity or 1
  tbl.hspeed = tbl.hspeed or 0
  tbl.vspeed = tbl.vspeed or 0
  return tbl
 end,

 -- Create box table, the values are relative to the
 -- actors x/y
 aabb = function(point, box)
  return {
   top = point.y - box.top,
   bot = point.y + box.bot,
   left = point.x - box.left,
   right = point.x + box.right,
  }
 end,

 h_overlaps = function(a,b)
  return (a.left < b.right) and (a.right > b.left)
 end,

 v_overlaps = function(a,b)
  return (a.top < b.bottom) and (a.bottom > b.top)
 end,

 overlaps = function(a,b)
  return h_overlaps(a,b) and v_overlaps(a,b)
 end,

 collides_with_map = function(aabb)
  local tl = fget(mget(aabb.left // 8, aabb.top // 8),0)
  local bl = fget(mget(aabb.left // 8, aabb.bot // 8),0)
  local tr = fget(mget(aabb.right // 8, aabb.top // 8),0)
  local br = fget(mget(aabb.right // 8, aabb.bot // 8),0)
  return tl or tr or bl or br
 end,
}

Comp = {
 count=0,

 actor={},
 control={},
 anim={},
 physics={},

 add = function(self, ent)
  self.count = self.count + 1
  local count = self.count
  if ent.actor then self.actor[count] = ent.actor end
  if ent.control then self.control[count] = ent.control end
  if ent.anim then self.anim[count] = ent.anim end
  if ent.physics then self.physics[count] = ent.physics end
  return count
 end,
}

t=0

function init()
 local player = Comp:add({
  actor = Actor.new({index=256,x=84,y=84,xoff=3,yoff=3}),
  anim = Anim.new({
   Anim.still(256),
   Anim.simple(7,{257,258,259,260}),
   Anim.still(261),
   Anim.still(262),
  }),
  control = Control.new({
    controller=0,
    anim={still=1,walk=2,jump=3,fall=4},
  }),
  physics = Physics.new({
    vbox={top=4,bot=4,left=0,right=1},
    hbox={top=3,bot=3,left=1,right=2},
    gravity=0.5,
  }),
 })
end

init()

function TIC()
 Sys.run()
 t=t+1
end

Sys = {
 run = function()
  for i,control in pairs(Comp.control) do
   if control.controller == 0 then Sys.input(control) end
  end

  for i,act in ipairs(Comp.actor) do
   if Comp.physics[i] then
    Sys.physics(act, Comp.physics[i], Comp.control[i])
   end
   if Comp.anim[i] then
    Sys.animate(act, Comp.anim[i], Comp.control[i])
   end
  end

  Sys.draw(Comp.actor)
 end,

 input = function(control)
  control.up = btn(0)
  control.down = btn(1)
  control.left = btn(2)
  control.right = btn(3)
 end,

 physics = function(actor,physics,control)
  -- Gravity
  local mx = actor.x // 8
  local mbelow = (actor.y + physics.vbox.bot + 1) // 8
  local on_ground = fget(mget(mx, mbelow),0)
  if not on_ground then
   physics.vspeed = physics.vspeed + physics.gravity
   physics.vspeed = physics.vspeed > 7 and 7 or physics.vspeed
  end

  -- if on_ground then trace('on ground') end

  if control then
   local hspeed = 0
   if control.left then hspeed = hspeed - 1 end
   if control.right then hspeed = hspeed + 1 end
   physics.hspeed = hspeed
   if control.up and on_ground then physics.vspeed = -4 end
  end

  actor.x = actor.x + physics.hspeed
  actor.y = actor.y + physics.vspeed

  local haabb = Physics.aabb(actor, physics.hbox)
  if Physics.collides_with_map(haabb) then
   actor.x = actor.x - physics.hspeed
   physics.hspeed = 0
  end

  local vaabb = Physics.aabb(actor, physics.vbox)
  if Physics.collides_with_map(vaabb) then
   actor.y = actor.y - physics.vspeed
   physics.vspeed = 0
  end

 end,

 animate = function(actor,anim,control)
  if control then
   if control.left then
    actor.flip=1
    if control.anim.walk then anim:play(control.anim.walk) end
   elseif control.right then
    actor.flip=0
    if control.anim.walk then anim:play(control.anim.walk) end
   else
    if control.anim.still then anim:play(control.anim.still) end
   end
  end
  while anim.index ~= nil and anim.next <= t do
   local a = anim.anim[anim.index]
   local f = a[anim.frame]
   if f.t == F.STOP then
    anim.index = nil
    break
   elseif f.t == F.INDEX then
    actor.index = f.v
   elseif f.t == F.LOOP then
    anim.frame = 0
   elseif f.t == F.WAIT then
    anim.next = t + f.v
   end
   anim.frame = anim.frame + 1
  end
 end,

 draw = function(actor)
  cls(13)
  map(0,0,30,17)
  print("HELLO LOUIS!",84,84)
  for i,act in ipairs(actor) do
   local transparent = 0
   spr(
    act.index,
    act.x-act.xoff,
    act.y-act.yoff,
    transparent,
    act.scale,
    act.flip,
    act.rot,
    act.w,
    act.h
   )
  end
 end,
}

-- <TILES>
-- 018:00000000000000000000000000000000000c0000000000000cc00c0ccccccccc
-- 020:0cccccccccc0000cc0000c00c0000000c0000000cc0c0000cc000000c0000000
-- 021:ccccccc00ccc0c0c0000000c00c000cc0000000c0000c00c000000cc0000000c
-- 033:0000000c000000cc000000cc0000000c0000c00c000000cc000000cc0000000c
-- 035:c0000000c00c0000cc000000c0000000c00c0000c0000000cc000000cc000000
-- 036:c0c00000c0000000cc000000cc000000c000c000c0000000cc0c000c0ccccccc
-- 037:0000000c000000cc000000cc0000c00c0c00000c0000000c0c0c0cccccccccc0
-- 050:cccccccc0c000c0c0000000000c0000000000000000000000000000000000000
-- 255:dccccccdcc2cc2cccc2cc2cccc2cc2cccc2cc2cccccccccccc2cc2ccdccccccd
-- </TILES>

-- <SPRITES>
-- 000:000cc000000cc00000cccc000cccccd00cccccd00cccccd000c00d0000c00d00
-- 001:000cc000000cc00000cccc0000cccc0000cccc0000cccc00000dc000000d0000
-- 002:000cc000000cc00000cccc0000cccc000dccccc000cccc0000d0c00000d0c000
-- 003:000cc000000cc00000cccc0000cccc0000cccc0000cccc00000c0d00000c0000
-- 004:000cc000000cc00000cccc000cccccd0c0cccc0d00cccc0000c00d0000c00d00
-- 005:000cc000000cc0000ccccc0dc0ccccd000cccc0000ccccd00cc000d000000000
-- 006:000cc000000cc0000cccccd0c0cccc0d00cccc0000ccccd000c000d000c00000
-- </SPRITES>

-- <MAP>
-- 001:000021212121212121212121212121212121212121212121212121210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:001200000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:001200000000000000000000000041510000000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:001200000000000000000000412300005100000000000000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:000023232323232323232323000000000023232323232323232323230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX>

-- <PATTERNS>
-- 000:400018000000000000100000400018000000000000100000600018000000000000100000400018000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <FLAGS>
-- 000:00000000000000000000000000000000000010001010000000000000000000000010001010100000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

