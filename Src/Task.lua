---@class Bm2TaskModule
local taskModule = Bm2Module.DeclareModule("Task") ---@type Bm2TaskModule

local uiModule = Bm2Module.DeclareModule("Ui") ---@type Bm2UiModule
local macroModule = Bm2Module.DeclareModule("Macro") ---@type Bm2MacroModule

---@class Bm2Task
---@field type string BM2TASKTYPE_* const
---@field item Bm2GetContainerItemInfoResult If type is USE_ITEM or OPEN, bag:slot points at the item to click
---@field buffId string if type is BUFF
---@field target string|number Target unit if type is BUFF, or group number if type is GROUP_BUFF
---@field text string Extra message to display, if type is COMMENT or ERROR

local taskClass = {} ---@type Bm2Task
taskClass.__index = taskClass

--TODO: Can also set macro to use trinkets for before-combat last prio task?
taskModule.TASKTYPE_USE_ITEM = "use" -- use item in bag:slot
taskModule.TASKTYPE_OPEN = "open" -- use item to open, or right click without a target
taskModule.TASKTYPE_BUFF = "buff" -- cast buff from the all available buffs list
taskModule.TASKTYPE_GROUP_BUFF = "groupbuff" -- cast buff on group from the all available buffs list
taskModule.TASKTYPE_ERROR = "error" -- red colored error text
taskModule.TASKTYPE_COMMENT = "comment" -- neutral gray colored text

---@param target string
---@param buffId string
---@return Bm2Task
function taskModule:NewBuffTask(target, buffId)
  local obj = {
    type   = self.TASKTYPE_BUFF,
    buffId = buffId,
    target = target,
  } ---@type Bm2Task
  setmetatable(obj, taskClass)
  return obj
end

---@param target string Unit or nil
---@param item Bm2GetContainerItemInfoResult
---@return Bm2Task
function taskModule:NewUseItemTask(item, target)
  local obj = {
    type   = self.TASKTYPE_USE_ITEM,
    target = target,
    item   = item,
  } ---@type Bm2Task
  setmetatable(obj, taskClass)
  return obj
end

---@param item Bm2GetContainerItemInfoResult
---@return Bm2Task
function taskModule:NewOpenItemTask(item)
  local obj = {
    type = self.TASKTYPE_OPEN,
    item = item,
  } ---@type Bm2Task
  setmetatable(obj, taskClass)
  return obj
end

---@param text string
---@return Bm2Task
function taskModule:NewComment(text)
  local obj = {
    type = self.TASKTYPE_COMMENT,
    text = text,
  } ---@type Bm2Task
  setmetatable(obj, taskClass)
  return obj
end

---@param text string
---@return Bm2Task
function taskModule:NewError(text)
  local obj = {
    type = self.TASKTYPE_ERROR,
    text = text,
  } ---@type Bm2Task
  setmetatable(obj, taskClass)
  return obj
end

---@return string,string Macro, button title
function taskClass:GetMacro()
  if self.type == taskModule.TASKTYPE_USE_ITEM then
    local macro = macroModule:MacroTarget(self.target)
        .. macroModule:MacroUseItem(self.item.bag, self.item.slot)
    local buttonTitle = uiModule:FormatTexture(self.item.texture)
            .. self.item.itemLink
            .. (self.target and (" @" .. self.target) or "")
    return macro, buttonTitle
  end

  Bm2Addon:Print("Don't know how to GetMacro for task type " .. self.type)
  return nil, nil
end

---Returns string for the cast button
function taskClass:GetButtonText()
  if self.type == taskModule.TASKTYPE_USE_ITEM then
    return "(" .. _t("Use item ") .. ") " .. self.item.itemLink

  elseif self.type == taskModule.TASKTYPE_OPEN then
    return "(" .. _t("Open ") .. ") " .. self.item.itemLink
  end

  Bm2Addon:Print("Don't know how to GetButtonText for task type " .. self.type)
  return nil
end
