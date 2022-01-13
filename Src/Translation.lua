---@class Bm2TranslationModule
local translation = Bm2Module.DeclareModule("Translation")

translation.lang = {
  profile_solo = "Solo",
  profile_party = "Party",
  profile_raid = "Raid",
  profile_pvp = "PvP",
}

function translation.Translate(key)
  return translation.lang[key] or key
end

setmetatable(translation, { __call = function(_, ...) return translation.Translate(...) end})
