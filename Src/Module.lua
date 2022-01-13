Bm2Module = {}

local moduleIndex = {}
Bm2Module._moduleIndex = moduleIndex

---New empty module with private section
local function bm2NewModule()
  return {
    private = {}
  }
end

---@param name string
function Bm2Module.DeclareModule(name)
  if (not moduleIndex[name]) then
    moduleIndex[name] = bm2NewModule()
    return moduleIndex[name]
  end

  return moduleIndex[name] -- found
end

Bm2Module.Import = Bm2Module.DeclareModule

---For each known module call function by fnName and optional context will be
---passed as 1st argument, can be ignored (defaults to nil)
---module:EarlyModuleInit (called early on startup)
---module:LateModuleInit (called late on startup, after entered world)
function Bm2Module.CallInEachModule(fnName, context)
  for _name, module in moduleIndex do
    if module.fnName then
      module:fnName(context)
    end
  end
end
