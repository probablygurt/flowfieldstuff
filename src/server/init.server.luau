--[[local Players = game:GetService("Players")
local RemotesHandler = require(script.RemotesHandler)
local Units = require(script.modules.Units)
local FieldSolver = require(script.modules.FieldSolver)

local cellSize = Vector2.new(2, 2)
local map = workspace.Map :: Model

local pathfinder = Units.newPathfinder("Enemy", map, cellSize)
FieldSolver.createGridParts(pathfinder.grid, map, cellSize)
RemotesHandler.GridSize = Vector2.new(pathfinder.grid.width, pathfinder.grid.height)

Players.PlayerAdded:Connect(function(player: Player)
    local enemyUnit = Units.newUnit("Enemy", Vector2.one)

    RemotesHandler.sendUnitData(enemyUnit)
end)--]]