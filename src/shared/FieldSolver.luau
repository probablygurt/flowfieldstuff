--!strict
local GridBase = require(script.Parent.GridBase)

local DEFAULT_CELL_PART_SIZE_Y = 1

local FieldSolver = {}

export type GridBase = GridBase.GridBase

local function isDecimal(x: number): boolean
    return x % 1 ~= 0
end

function FieldSolver.newGridFromPart(base: BasePart, cellSize: Vector2): GridBase?
    local partW, partH = base.Size.X, base.Size.Z
    local gridSize = Vector2.new(partW, partH) / cellSize

    print(`GridSize: {gridSize}`)

    if isDecimal(gridSize.X) or isDecimal(gridSize.Y) then
        warn(`Grid size is not a whole number vector. Change the size of your base part or cell size. Grid size: ({gridSize})`)
        return 
    end

    return GridBase.new(gridSize.X, gridSize.Y)
end

function FieldSolver.createGridParts(grid: GridBase, base: BasePart, cellSize: Vector2)
    local baseSize = base.Size
    local baseCFrame = base.CFrame
    local topLeft = baseCFrame * CFrame.new(
        -baseSize.X * 0.5 + cellSize.X * 0.5,
        DEFAULT_CELL_PART_SIZE_Y,
        -baseSize.Z * 0.5 + cellSize.Y * 0.5
    )

    local cellPartSize = Vector3.new(cellSize.X, DEFAULT_CELL_PART_SIZE_Y, cellSize.Y)

    local folder = Instance.new("Folder")
    folder.Name = "GridParts"
    folder.Parent = base

    for y = 1, grid.height do
        for x = 1, grid.width do
            local index = grid:index(x, y)

            local cell = Instance.new("Part")
            cell.Anchored, cell.CanCollide, cell.CanTouch = true, false, true
			cell.TopSurface = Enum.SurfaceType.Smooth
            cell.Transparency = 0.9
            cell.Size = cellPartSize
			cell.CFrame = topLeft * CFrame.new((x - 1) * cellSize.X, 0, (y - 1) * cellSize.Y)
            cell.Name = `Cell{index}`
            cell.Parent = folder
        end
    end
end

function FieldSolver.setWeightRect(grid: GridBase, pos: Vector2, size: Vector2, w: number)
    local dirtyCells = {}
    
    for y = pos.Y, pos.Y + size.Y do
        for x = pos.X, pos.X + size.Y do
            local index = grid:index(x, y)

            table.insert(dirtyCells, index)
            grid:setWeight(index, w)
        end
    end

    return dirtyCells
end

function FieldSolver.setCostRect(grid: GridBase, pos: Vector2, size: Vector2, c: number)
    local dirtyCells = {}
    
    for y = pos.Y, pos.Y + size.Y do
        for x = pos.X, pos.X + size.Y do
            local index = grid:index(x, y)

            table.insert(dirtyCells, index)
            grid:setCost(index, c)
        end
    end

    return dirtyCells
end

function FieldSolver.forEachCell(grid: GridBase, cells: {number}?, callback: (i: number) -> ())
    local all = cells == nil

    if all then 
        for i = 0, grid.width * grid.height - 1 do
            callback(i)
        end
    else
        local indices = cells :: {number}

        for _, i in indices do
            callback(i)
        end

        return
    end
end


return FieldSolver