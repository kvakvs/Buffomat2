Bm2Module = {}

local moduleIndex = {}
Bm2Module._moduleIndex = moduleIndex

---@param name string
function Bm2Module.DeclareModule(name)
  if (not moduleIndex[name]) then
    moduleIndex[name] = {} -- setup new empty
    return moduleIndex[name]
  end

  return moduleIndex[name] -- found
end

Bm2Module.Import = Bm2Module.DeclareModule
