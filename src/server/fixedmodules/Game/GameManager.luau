local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TaskManager = require(ReplicatedStorage.Shared.TaskManager)
local GridManager = require(ServerScriptService.Server.fixedmodules.Grid.GridManager)
local UnitManager = require(ServerScriptService.Server.fixedmodules.Units.UnitManager)

local GameManager = {}

function GameManager.init()
    print("GameManager init")
end

function GameManager.start()
    TaskManager:delay(5, function()
        local grid = UnitManager.Pathfinders["Enemy"].grid

        UnitManager.addObject(nil, 50*50-1, "Core")
        UnitManager.solveGrids()
        GridManager.displayGradient(grid,Color3.fromRGB(255, 255, 255), Color3.fromRGB())
    end)

    TaskManager.OnTick:Connect(function(currTick)
        print(`Server Tick: {currTick}`)
    end)
end


return GameManager