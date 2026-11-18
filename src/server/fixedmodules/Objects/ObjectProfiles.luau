local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ServerScriptService.Server.fixedmodules.Types)
local GridQuery = require(ServerScriptService.Server.modules.Grid.GridQuery)

local ObjectProfiles = {
    Core = {
        Cost = 0,
    },
    Mud = {
        Weight = 5,
    },
    Wall = {
        Weight = math.huge
    },
    Tower = {
        Weight = math.huge,
        Cost = 20,

        GetObjectArea = function(grid, i)
            local WEIGHT_ADD = 2

            local objectArea = {}
            local weight = {}

            for _, index in GridQuery.getCircle(grid, i, 10) do 
                weight[index] = WEIGHT_ADD
            end

            objectArea.Weights = weight

            return objectArea
        end
    },
} :: {[string]: Types.ObjectProfile}

function ObjectProfiles.init()
    for name, profile in ObjectProfiles do
        if typeof(profile) == "function" then continue end 
        profile.Name = name
    end
end

return ObjectProfiles