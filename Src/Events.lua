---@class Bm2EventsModule
local events = Bm2Module.DeclareModule("Events")

function events:RegisterEarlyEvents()
  Bm2Addon:RegisterEvent("PLAYER_LOGIN", function()
    Bm2Addon:OnInitializeStep2()
  end)
end
