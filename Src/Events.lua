---@class Bm2EventsModule
local events = Bm2Module.DeclareModule("Events")

function events:RegisterEarlyEvents()
  --Bm2Addon:RegisterEvent("PLAYER_LOGIN", function()
  Bm2Addon:RegisterEvent("PLAYER_ENTERING_WORLD", function() Bm2Addon:OnInitializeStep2() end)
  Bm2Addon:RegisterEvent("LOADING_SCREEN_DISABLED", function() Bm2Addon:OnInitializeStep2() end)
end
