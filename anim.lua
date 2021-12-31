require "util"

-- Animation
local F = enum{"INDEX","WAIT","STOP","LOOP"}
local Anim = {}

Anim.new = function(anim, begin)
    local t = setmetatable({},{__index = Anim})
    t.time = 0
    t.anim = anim
    t.current = begin
    t.next = 0
    t.frame = 1
    return t
end

Anim.play = function(self, anim)
    if self.current ~= anim then
        self.current = anim
        self.next = 0
        self.frame = 1
    end
end

Anim.still = function(i)
    return {
        {t=F.INDEX,v=i},
        {t=F.STOP}
    }
end

Anim.simple = function(len, ilist)
    local a = {}
    for i,v in ipairs(ilist) do
        a[#a+1]={t=F.INDEX,v=v}
        a[#a+1]={t=F.WAIT,v=len}
    end
    a[#a+1]={t=F.LOOP}
    return a
end

Anim.update = function(self, dt)
    local index = nil
    if stopped then return index end
    self.time = self.time + dt
    while self.current ~= nil and self.next <= self.time do
        local a = self.anim[self.current]
        local f = a[self.frame]
        if f.t == F.STOP then
            self.current = nil
            break
        elseif f.t == F.INDEX then
            index = f.v
        elseif f.t == F.LOOP then
            self.frame = 0
        elseif f.t == F.WAIT then
            self.next = self.time + f.v
        end
        self.frame = self.frame + 1
    end
    return index
end

return Anim
