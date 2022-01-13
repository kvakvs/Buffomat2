---@class Bm2TooltipModule
local tooltipModule = Bm2Module.DeclareModule("Tooltip")

---Add onenter/onleave scripts to show the tooltip with translation by key
---@param translation_key string - the key from Languages.lua
function tooltipModule:Set(control, translation_key)
  control:SetScript("OnEnter", function()
    GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
    GameTooltip:AddLine(translation_key)
    GameTooltip:Show()
  end)
  control:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
end
