---@class Bm2PopupModule
---@field popupLastWipeName string
---@field popupDepth number|nil
local popupModule = Bm2Module.DeclareModule("UiPopup")

---@class Bm2PopupMenuItem

local function bm2PopupAddItem(self, text, disabled, value, arg1, arg2)
  local c = self._Frame.Bm2Items.count + 1
  self._Frame.Bm2Items.count = c

  if not self._Frame.Bm2Items[c] then
    self._Frame.Bm2Items[c] = {}
  end

  local t = self._Frame.Bm2Items[c] ---@type Bm2PopupMenuItem

  t.text = text or ""
  t.disabled = disabled or false
  t.value = value
  t.arg1 = arg1
  t.arg2 = arg2
  t.MenuDepth = PopupDepth
end

local function bm2PopupAddSubMenu(self, text, value)
  if text ~= nil and text ~= "" then
    bm2PopupAddItem(self, text, "MENU", value)
    popupModule.popupDepth = value
  else
    popupModule.popupDepth = nil
  end
end

---@param self Bm2Control
local function bm2PopupWipe(self, wipeName)
  self._Frame.Bm2Items.count = 0
  popupModule.popupDepth = nil

  if UIDROPDOWNMENU_OPEN_MENU == self._Frame then
    ToggleDropDownMenu(nil, nil, self._Frame, self._where, self._x, self._y)
    if wipeName == popupModule.popupLastWipeName then
      return false
    end
  end

  popupModule.popupLastWipeName = wipeName
  return true
end

local function bm2PopupClick(self, arg1, arg2, checked)
  if type(self.value) == "table" then
    self.value[arg1] = not self.value[arg1]
    self.checked = self.value[arg1]
    if arg2 then
      arg2(self.value, arg1, checked)
    end

  elseif type(self.value) == "function" then
    self.value(arg1, arg2)
  end
end

local function bm2PopupCreate(frame, level, menuList)
  if level == nil then
    return
  end

  local info = UIDropDownMenu_CreateInfo()

  for i = 1, frame.Bm2Items.count do
    local val = frame.Bm2Items[i]
    if val.MenuDepth == menuList then
      if val.disabled == "MENU" then
        info.text = val.text
        info.notCheckable = true
        info.disabled = false
        info.value = nil
        info.arg1 = nil
        info.arg2 = nil
        info.func = nil
        info.hasArrow = true
        info.menuList = val.value
        --info.isNotRadio=true
      else
        info.text = val.text
        if type(val.value) == "table" then
          info.checked = val.value[val.arg1] or false
          info.notCheckable = false
        else
          info.notCheckable = true
        end
        info.disabled = (val.disabled == true or val.text == "")
        info.keepShownOnClick = (val.disabled == "keep")
        info.value = val.value
        info.arg1 = val.arg1
        if type(val.value) == "table" then
          info.arg2 = frame.Bm2TableCallback
        elseif type(val.value) == "function" then
          info.arg2 = val.arg2
        end
        info.func = bm2PopupClick
        info.hasArrow = false
        info.menuList = nil
        --info.isNotRadio=true
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end
end

local function bm2PopupShow(self, where, x, y)
  where = where or "cursor"
  if UIDROPDOWNMENU_OPEN_MENU ~= self._Frame then
    UIDropDownMenu_Initialize(self._Frame, bm2PopupCreate, "MENU")
  end
  ToggleDropDownMenu(nil, nil, self._Frame, where, x, y)
  self._where = where
  self._x = x
  self._y = y
end

---@param tableCallback function
function popupModule:CreatePopup(tableCallback)
  local popup = {}
  popup._Frame = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
  popup._Frame.Bm2TableCallback = tableCallback
  popup._Frame.Bm2Items = {}
  popup._Frame.Bm2Items.count = 0
  popup.AddItem = bm2PopupAddItem
  popup.SubMenu = bm2PopupAddSubMenu
  popup.Show = bm2PopupShow
  popup.Wipe = bm2PopupWipe
  return popup
end
