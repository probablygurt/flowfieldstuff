local ServerScriptService = game:GetService("ServerScriptService")

local GridQuery = require(ServerScriptService.Server.modules.Grid.GridQuery)
local Types = require(ServerScriptService.Server.modules.Grid.Types)

local ObjectData: {[string]: Types.ObjectData} = {
    Core = {
        Name = "Core",

        Cost = 0,
    },
    Mud = {
        Name = "Mud",

        Weight = 5,
    },
    Wall = {
        Name = "Wall",

        Weight = math.huge
    },
    Tower = {
        Name = "Tower",

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
    Tower2 = {
        Name = "Tower2",

        Weight = math.huge,
        Cost = 50,
        
        GetObjectArea = function(grid, i)
            local WEIGHT_ADD = 1

            local objectArea = {}
            local weight = {}

            for _, index in GridQuery.getCircle(grid, i, 3) do 
                weight[index] = WEIGHT_ADD
            end

            objectArea.Weights = weight

            return objectArea
        end
    }
}


return ObjectData