---@class Bm2TranslationModule
local translation = Bm2Module.DeclareModule("Translation")

function translation.Translate(key)
  return key
end

setmetatable(translation, { __call = function(_, ...) return translation.Translate(...) end})
