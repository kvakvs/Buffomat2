---Bag contents cache
---@class Bm2BagModule
---@field wipeCachedItems boolean|nil Invalidate the bag cache
---@field cachedBag table<number, string> The bag cache
---@field getItemListCached table<number, Bm2GetContainerItemInfoResult> Stores copies of GetContainerItemInfo parse results
---@field haveItemCache table<number, Bm2GetContainerItemInfoResult> Cache by itemId, may not see multiple copies of same item, use to check availability
local bagModule = Bm2Module.DeclareModule("Bag")
bagModule.wipeCachedItems = true
bagModule.cachedBag = {}
bagModule.getItemListCached = {}
bagModule.haveItemCache = {}

-- This is filled from spellsDb setup code as new buffs are registered
bagModule.trackItems = {
  soulstones = { 5232, 16892, 16893, 16895, -- Soulstone
                 16896 }, -- TBC: Major Soulstone
}

local profileModule = Bm2Module.Import("Profile")---@type Bm2ProfileModule

function bagModule:Invalidate()
  bagModule.wipeCachedItems = true
  wipe(bagModule.cachedBag)
end

---@class Bm2GetContainerItemInfoResult
---@field itemId number
---@field checkCooldown boolean If true, cooldowns data will be refreshed
---@field cooldownExpire number GetTime() when cooldown on item expires or 0
---@field itemLink string
---@field bag number Inventory bag id
---@field slot number Inventory slot id
---@field texture number|string Item picture path
---@field lootable boolean Is a container with something inside

local function bm2ContainerItemCooldown(checkCooldown, bag, slot)
  local cdExpire = 0

  if checkCooldown then
    local startTime, duration, enable = GetContainerItemCooldown(bag, slot)

    if startTime > 0 then
      cdExpire = startTime + duration
    elseif enable then
      cdExpire = GetTime() + duration
    end
  end

  return cdExpire
end

---@return Bm2GetContainerItemInfoResult
local function bm2NewGCIResult(itemId, itemLink, bag, slot, icon, checkCooldown)
  return {
    itemId         = itemId,
    itemLink       = itemLink,
    checkCooldown  = checkCooldown,
    cooldownExpire = bm2ContainerItemCooldown(checkCooldown, bag, slot),
    bag            = bag,
    slot           = slot,
    texture        = icon,
  }
end

---Cache bag contents, only interesting items listed in bagModule.trackItems
---@return table<number, Bm2GetContainerItemInfoResult>
local function bm2LoadBagContents()
  local bags = {}

  for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local icon, _itemCount, _locked, _quality, _isReadableBook, lootable, itemLink
      , _isGrayedOut, _noGoldValue, itemID = GetContainerItemInfo(bag, slot)

      -- Only items in bagModule.trackItems will be cached
      for _index, list in pairs(bagModule.trackItems) do
        if tContains(list, itemID) then
          local newItem = bm2NewGCIResult(itemID, itemLink, bag, slot, icon, true)
          tinsert(bags, newItem)
        end
      end

      if lootable and profileModule.active.openLootableInBag then
        local locked = false

        --for _index, text in ipairs(BOM.Tool.ScanToolTip("SetBagItem", bag, slot)) do
        --  if text == LOCKED then
        --    locked = true
        --    break
        --  end
        --end

        if not locked then
          local newItem = bm2NewGCIResult(itemID, itemLink, bag, slot, icon, false)
          newItem.lootable = true
          tinsert(bags, newItem)
        end -- not locked
      end -- lootable & config.openLootable
    end -- for all bag slots in the current bag
  end -- for all bags

  -- Update lookup cache
  wipe(bagModule.haveItemCache)
  for _index, item in ipairs(bags) do
    bagModule.haveItemCache[item.itemId] = item
  end

  return bags
end

---@return table<number, Bm2GetContainerItemInfoResult>
function bagModule:GetItemList()
  if self.wipeCachedItems then
    self.wipeCachedItems = false
    self.getItemListCached = bm2LoadBagContents()
  end

  --Update cooldowns
  for _index, item in ipairs(self.getItemListCached) do
    if item.checkCooldown then
      item.cooldownExpire = bm2ContainerItemCooldown(true, item.bag, item.slot)
    end
  end

  return self.getItemListCached
end

---Find the item in the cached bag contents
---@param item number the itemId number
---@param respectCooldown boolean respect the cooldown, return nil if found but not ready
---@return Bm2GetContainerItemInfoResult|nil
function bagModule:AnyInventoryItem(item, respectCooldown)
  -- If table of itemids is passed, instead iterate the table and first to succeed will return
  if type(item) == "table" then
    for _index, itemid in item do
      local eachResult = self:AnyInventoryItem(itemid, respectCooldown)
      if eachResult then
        return eachResult
      end
    end
    return nil
  end

  local cachedItem = self.haveItemCache[item]
  if not cachedItem then
    return nil -- do not have
  end

  if respectCooldown
      and cachedItem.cooldownExpire > 0
      and cachedItem.cooldownExpire < GetTime()
  then
    return nil -- still on cooldown
  end

  return cachedItem
end
