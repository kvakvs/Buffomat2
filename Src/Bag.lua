---Bag contents cache

---@class Bm2BagModule
---@field wipeCachedItems boolean|nil Invalidate the bag cache
---@field cachedBag table<number, string> The bag cache
local bm2bag = Bm2Module.DeclareModule("Bag")

function bm2bag:Invalidate()
  -- TODO: Maybe just wipe() the cache?
  bm2bag.wipeCachedItems = true
  wipe(bm2bag.cachedBag)
end
