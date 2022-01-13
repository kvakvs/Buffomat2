---@class Bm2TranslationModule
local translationModule = Bm2Module.DeclareModule("Translation")

translationModule.lang = {
  profile_solo  = "Solo",
  profile_party = "Party",
  profile_raid  = "Raid",
  profile_pvp   = "PvP",
}

function translationModule.Translate(key)
  return translationModule.lang[key] or key
end

setmetatable(translationModule, {
  __call = function(_, ...)
    return translationModule.Translate(...)
  end
})
