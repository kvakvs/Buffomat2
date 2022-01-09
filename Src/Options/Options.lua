---@class Bm2OptionsModule
local options = Bm2Module.DeclareModule("Options")

---@type Bm2TranslationModule
local translation = Bm2Module.Import("Translation")
local function _t(key)
  return function()
    return translation(key)
  end
end

function options:MakeGeneralTab()
  return {
    name  = _t('General'),
    type  = "group",
    order = 10,
    args  = {
      --header_general = {
      --  type  = "header",
      --  order = 1,
      --  name  = _t('General Options'),
      --},
      activateWhen   = {
        type   = "group",
        order  = 2,
        inline = true,
        name   = _t('Activate when...'),
        args   = {
          autoShow        = {
            type  = "toggle",
            order = 1,
            name  = _t('When there\'s work to do'),
            desc  = _t('Pop Buffomat window when task list is not empty.'),
            width = 1.5,
            get   = function()
              return Bm2Addon.db.char.autoShow;
            end,
            set   = function(info, value)
              Bm2Addon.db.char.autoShow = value;
            end,
          },
          scanInRestAreas = {
            type  = "toggle",
            order = 2,
            name  = _t('Scan buffs in rest areas'),
            desc  = _t('Allow buffing with Buffomat in cities and inns.'),
            width = 1.5,
            get   = function()
              return Bm2Addon.db.char.scanInRestAreas;
            end,
            set   = function(info, value)
              Bm2Addon.db.char.scanInRestAreas = value;
            end,
          },
        },
      }
    }
  }
end

function options:GetDefaults()
  return {
    global = {},
    char   = {
      autoShow        = true,
      scanInRestAreas = true,
    },
  }
end
