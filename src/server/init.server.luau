local RemotesHandler = require(script.RemotesHandler)
local FieldSolver = require(script.modules.FieldSolver)

local cellSize = Vector2.new(2, 2)

local map = workspace.Map :: Model
local mapBase = map.PrimaryPart :: BasePart

local mapGrid = FieldSolver.newGridFromPart(mapBase, cellSize)

RemotesHandler.Grid = mapGrid
FieldSolver.createGridParts(mapGrid, mapBase, cellSize)
