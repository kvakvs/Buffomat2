---@class Bm2OptionsModule
local options = Bm2Module.DeclareModule("Options")

---@type Bm2TranslationModule
local _t = Bm2Module:Import("Translation")

function options:MakeGeneralTab()
  return {
    name = function() return _t('General'); end,
    type = "group",
    order = 10,
    args = {
      bm2_header = {
        type = "header",
        order = 1,
        name = function() return _t('General Options'); end,
      },
      enabled = {
        type = "toggle",
        order = 1.1,
        name = function() return _t('Enable Icons'); end,
        desc = function() return _t('Enable or disable icons.'); end,
        width = 1.5,
        get = function () return false; end,
        set = function (info, value) end,
      },
    }
  }
end
