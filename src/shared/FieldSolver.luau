--!strict
local GridBase = require(script.Parent.GridBase)

local DEFAULT_CELL_PART_SIZE_Y = 1
local DIR = {
    -Vector2.xAxis,
    Vector2.xAxis,
    -Vector2.yAxis,
    Vector2.yAxis,
    
    -Vector2.one,
    Vector2.one,
    Vector2.new(-1, 1),
    Vector2.new(1, -1)
}

local DIR_COST = {
    10, 10, 10, 10,
    14, 14, 14, 14
}

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
        baseSize.Y * 0.5 + DEFAULT_CELL_PART_SIZE_Y * 0.5,
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
            cell.Anchored, cell.CanCollide = true, false
            cell.CanTouch, cell.CanQuery = false, false
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
    
    for y = pos.Y, pos.Y + size.Y - 1 do
        for x = pos.X, pos.X + size.Y - 1 do
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

type StepWeight = (grid: GridBase, x: number, y: number, d: number) -> (number?, number?)

function FieldSolver.stepWeight(grid: GridBase, x: number, y: number, d: number): (number?, number?)
    local nx, ny = x + DIR[d].X, y + DIR[d].Y
    if not grid:isValid(nx, ny) then return end

    local ni = grid:index(nx, ny)
    local weight = grid:getWeight(ni)
    
    if d > 4 then
        local diag1 = grid:getWeight(grid:index(nx, y))
        local diag2 = grid:getWeight(grid:index(x, ny))

        if diag1 + diag2 == math.huge then return end 
    end

    return ni, weight * DIR_COST[d]
end

-- Assumes goal costs have already been initialized
function FieldSolver.computeCosts(grid: GridBase, stepWeight: StepWeight?)
    local defStepWeight: StepWeight = stepWeight or FieldSolver.stepWeight

    local changed = true

    while changed do
        changed = false

        for y = 1, grid.height do
            for x = 1, grid.width do
                local index = grid:index(x, y)

                if grid:getWeight(index) == math.huge then continue end

                local cost = grid:getCost(index)
                local best = cost

                for d = 1, #DIR do
                    local ni, weight = defStepWeight(grid, x, y, d)
                    if ni == nil or weight == nil then continue end

                    best = math.min(best, grid:getCost(ni) + weight)
                end

                if best < cost then
                    grid:setCost(index, best)
                    changed = true
                end
            end
        end
    end
end

function FieldSolver.getMaxCost(grid: GridBase): number
    local max = -math.huge
	
    for i = 0, grid.width * grid.height - 1 do
		local c = grid:getCost(i)
		if c ~= math.huge and c > max then max = c end
	end

	return max
end

return FieldSolver