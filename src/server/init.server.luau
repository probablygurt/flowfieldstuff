local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesHandler = require(script.RemotesHandler)
local FieldSolver = require(ReplicatedStorage.Shared.FieldSolver)

local cellSize = Vector2.new(2, 2)

local map = workspace.Map :: Model
local mapBase = map.PrimaryPart :: BasePart

local mapGrid = FieldSolver.newGridFromPart(mapBase, cellSize)

RemotesHandler.Grid = mapGrid
FieldSolver.createGridParts(mapGrid, mapBase, cellSize)

local function computeCosts()
    local t = os.clock()
    FieldSolver.computeCosts(mapGrid)
    print(`finished in {(os.clock() - t) * 1000} ms`)
end

computeCosts()
