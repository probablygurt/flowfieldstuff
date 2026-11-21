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
    return Vector2.new(math.random(1, 50), math.random(1, 50))
end

function GameManager.start()
    TaskManager:delay(120, function()
        local grid = UnitManager.Pathfinders["Enemy"].grid

        local corePos = randomPos()--Vector2.one--randomPos()
        UnitManager.addObject(nil, grid:index(corePos.X, corePos.Y), "Core")

        --[[for i = 1, 20 do
            local rand = randomPos()
            repeat
                rand = randomPos()
            until grid.objects[grid:index(rand.X, rand.Y)] == nil

            UnitManager.addObject(nil, grid:index(rand.X, rand.Y), "Tower")
        end--]]

        UnitManager.solveGrids()
        GridManager.displayGradient(grid,Color3.fromRGB(255, 255, 255), Color3.fromRGB())

        TaskManager:wait(10)

        for i = 1, 200 do  
            local rand = randomPos()

            repeat
                rand = randomPos()
            until grid:getObject(grid:index(rand.X, rand.Y)) == nil

            --Unit.new("Enemy", Vector2.new(50, 50))
            Unit.new("Enemy", rand)

            if i % 100 ~= 0 then continue end 
            TaskManager:wait(5)
        end
    end)

    TaskManager:delay(200, function()
        local grid = UnitManager.Pathfinders["Enemy"].grid

        local towerPos = Vector2.new(35, 25)
        UnitManager.addObject(nil, grid:index(towerPos.X, towerPos.Y), "Tower")

        --task.defer(GridManager.displayGradient, grid, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), nil, 0)
        TaskManager:wait(10)

        for i = 1, 10 do
            local rand = randomPos()

            repeat
                rand = randomPos()
            until grid:getObject(grid:index(rand.X, rand.Y)) == nil
            
            UnitManager.addObject(nil, grid:index(rand.X, rand.Y), "Tower")

            task.defer(GridManager.displayGradient, grid, Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), nil, 0.05)
            TaskManager:wait(60)
        end
    end)
end


return GameManager