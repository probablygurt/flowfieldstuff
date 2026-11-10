local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FieldSolver = require(ReplicatedStorage.Shared.FieldSolver)

local cellSize = Vector2.new(4, 4)
local map = workspace.Map :: BasePart

local mapGrid = FieldSolver.newGridFromPart(map, cellSize)
FieldSolver.createGridParts(mapGrid, map, cellSize)

local dirtyCells = FieldSolver.setWeightRect(mapGrid, Vector2.one * 3, Vector2.one * 5, 2)

FieldSolver.forEachCell(mapGrid, dirtyCells, function(i: number)
    print(i)
    local part = map.GridParts:FindFirstChild(`Cell{i}`) :: BasePart
    if part == nil then return end
    part.BrickColor = BrickColor.DarkGray()
end)