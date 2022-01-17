---Bag contents cache
---@class Bm2BagModule
---@field wipeCachedItems boolean|nil Invalidate the bag cache
---@field cachedBag table<number, string> The bag cache
---@field getItemListCached table<number, Bm2GetContainerItemInfoResult> Stores copies of GetContainerItemInfo parse results
local bagModule = Bm2Module.DeclareModule("Bag")
bagModule.wipeCachedItems = true
bagModule.cachedBag = {}
bagModule.getItemListCached = {}

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
---@field cooldownExpire number GetTime() when cooldown on item expires or 0
---@field itemLink string
---@field bag number Inventory bag id
---@field slot number Inventory slot id
---@field texture number|string Item picture path
---@field lootable boolean Is a container with something inside

---@return Bm2GetContainerItemInfoResult
local function bm2NewGCIResult(itemId, itemLink, bag, slot, icon)
  local startTime, duration, enable = GetItemCooldown(itemId)
  local cdExpire = 0
  if startTime > 0 then
    cdExpire = startTime + duration
  elseif enable then
    cdExpire = GetTime() + duration
  end
  return {
    itemId         = itemId,
    itemLink       = itemLink,
    cooldownExpire = cdExpire,
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
          local newItem = bm2NewGCIResult(itemID, itemLink, bag, slot, icon)
          tinsert(bags, newItem)
        end
      end

      if lootable and profileModule.active.openLootableInBag then
        local locked = false

        for _index, text in ipairs(BOM.Tool.ScanToolTip("SetBagItem", bag, slot)) do
          if text == LOCKED then
            locked = true
            break
          end
        end

        if not locked then
          local newItem = bm2NewGCIResult(itemID, itemLink, bag, slot, icon)
          newItem.lootable = true
          tinsert(bags, newItem)
        end -- not locked
      end -- lootable & config.openLootable
    end -- for all bag slots in the current bag
  end -- for all bags

  return bags
end

---@return table<number, Bm2GetContainerItemInfoResult>
function bagModule:GetItemList()
  if bagModule.wipeCachedItems then
    bagModule.wipeCachedItems = false
    bagModule.getItemListCached = bm2LoadBagContents()
  end

  --Update CD
  for i, item in ipairs(bagModule.getItemListCached) do
    if item.CD then
      item.CD = { GetContainerItemCooldown(item.Bag, item.Slot) }
    end
  end

  return bagModule.getItemListCached
end
