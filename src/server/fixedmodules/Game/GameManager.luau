local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TaskManager = require(ReplicatedStorage.Shared.TaskManager)
local GridManager = require(ServerScriptService.Server.fixedmodules.Grid.GridManager)
local Unit = require(ServerScriptService.Server.fixedmodules.Units.Unit)
local UnitManager = require(ServerScriptService.Server.fixedmodules.Units.UnitManager)

local GameManager = {}

function GameManager.init()
    print("GameManager init")
end

local function randomPos(): Vector2
    return Vector2.new(math.random(1, 100), math.random(1, 100))
end

function GameManager.start()
    TaskManager:delay(5, function()
        local grid = UnitManager.Pathfinders["Enemy"].grid

        local corePos = randomPos()
        UnitManager.addObject(nil, grid:index(corePos.X, corePos.Y), "Core")

        for i = 1, 20 do
            local rand = randomPos()
            repeat
                rand = randomPos()
            until grid.objects[grid:index(rand.X, rand.Y)] == nil

            UnitManager.addObject(nil, grid:index(rand.X, rand.Y), "Tower")
        end


        UnitManager.solveGrids()
        GridManager.displayGradient(grid,Color3.fromRGB(255, 255, 255), Color3.fromRGB())

        TaskManager:wait(200)

        for i = 1, 2000 do  
            local rand = randomPos()

            repeat
                rand = randomPos()
            until grid.objects[grid:index(rand.X, rand.Y)] == nil

            Unit.new("Enemy", rand)

            if i % 100 ~= 0 then continue end 
            TaskManager:wait(5)
        end
    end)
end


return GameManager