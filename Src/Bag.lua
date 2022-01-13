---Bag contents cache

---@class Bm2BagModule
---@field wipeCachedItems boolean|nil Invalidate the bag cache
---@field cachedBag table<number, string> The bag cache
local bagModule = Bm2Module.DeclareModule("Bag")
bagModule.cachedBag = {}

function bagModule:Invalidate()
  -- TODO: Maybe just wipe() the cache?
  bagModule.wipeCachedItems = true
  wipe(bagModule.cachedBag)
end
