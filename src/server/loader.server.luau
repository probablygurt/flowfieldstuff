local fixedmodules = script.Parent.fixedmodules
local loaded: {[string]: ModuleScript} = {}

for _, descendant: ModuleScript in fixedmodules:GetDescendants() do
    if descendant.ClassName == "ModuleScript" then loaded[descendant.Name] = require(descendant) end
end

for _, module in loaded do
    if type(module.init) == "function" then module.init() end    
end

for _, module in loaded do
    if type(module.start) == "function" then task.defer(module.start) end
end
