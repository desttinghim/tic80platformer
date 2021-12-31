-- Util
local util = {}

function enum(tbl)
 local len = #tbl
 for i=1,len do
  local v = tbl[i]
  tbl[v] = i
 end
 return tbl
end

return util
