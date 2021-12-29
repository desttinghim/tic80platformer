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

 animate = function(actor,anim,control,physics)
  if control and physics then
   if not physics.on_ground then
    if physics.vspeed < 0 then
     if control.anim.jump then anim:play(control.anim.jump) end
    else
     if control.anim.fall then anim:play(control.anim.fall) end
    end
   elseif control.left then
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
} -- Anim
