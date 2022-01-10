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
