local ServerScriptService = game:GetService("ServerScriptService")

local GridManager = require(ServerScriptService.Server.fixedmodules.Grid.GridManager)
local UnitManager = require(ServerScriptService.Server.fixedmodules.Units.UnitManager)
local TaskManager = require(script.Parent.TaskManager)

local GameManager = {}

function GameManager.init()
    print("GameManager init")
end

function GameManager.start()
    print(TaskManager.Tick)

    TaskManager:delay(15, function()
        UnitManager.addObject(nil, 1324, "Core")
        UnitManager.solveGrids(nil)
        
        local grid = UnitManager.Pathfinders["Enemy"].grid
        GridManager.displayGradient(grid,Color3.fromRGB(255, 255, 255), Color3.fromRGB())
    end)
end


return GameManager