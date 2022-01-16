---@class Bm2ToolModule
local toolModule = Bm2Module.DeclareModule("Tool")

function toolModule.UnitDistanceSquared(uId)
  --partly copied from DBM
  --    * Paul Emmerich (Tandanu @ EU-Aegwynn) (DBM-Core)
  --    * Martin Verges (Nitram @ EU-Azshara) (DBM-GUI)

  local range

  if UnitIsUnit(uId, "player") then
    range = 0
  else
    local distanceSquared, checkedDistance = UnitDistanceSquared(uId)

    if checkedDistance then
      range = distanceSquared
    elseif C_Map.GetBestMapForUnit(uId) ~= C_Map.GetBestMapForUnit("player") then
      range = TOO_FAR
    elseif IsItemInRange(8149, uId) then
      range = 64 -- 8 --Voodoo Charm
    elseif CheckInteractDistance(uId, 3) then
      range = 100 --10
    elseif CheckInteractDistance(uId, 2) then
      range = 121 --11
    elseif IsItemInRange(14530, uId) then
      -- 18--Heavy Runecloth Bandage. (despite popular sites saying it's 15 yards,
      -- it's actually 18 yards verified by UnitDistanceSquared
      range = 324
    elseif IsItemInRange(21519, uId) then
      range = 529 --23--Item says 20, returns true until 23.
    elseif IsItemInRange(1180, uId) then
      range = 1089 --33--Scroll of Stamina
    elseif UnitInRange(uId) then
      range = 1849--43 item check of 34471 also good for 43
    else
      range = 10000
    end
  end
  return range
end
