local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage.Shared

local loaded: {[string]: ModuleScript} = {}

local function loadModules(parent: Instance)
    for _, descendant in parent:GetDescendants() do
        if descendant.ClassName == "ModuleScript" then loaded[descendant.Name] = require(descendant) end
    end

    for _, module in loaded do
        if type(module.init) == "function" then module.init() end    
    end

    for _, module in loaded do
        if type(module.start) == "function" then task.defer(module.start) end
    end
end

loadModules(shared)
loadModules(script)