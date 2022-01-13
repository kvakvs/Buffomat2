---@class Bm2SlashModule
local slashModule = Bm2Module.DeclareModule("Slash")

function slashModule:HandleSlash(input)
  Bm2Addon:Print("slash: " .. input)
end
