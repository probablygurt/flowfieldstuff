local GridBase = require(script.Parent.GridBase)
local GridHeap = require(script.Parent.GridHeap)

local DEFAULT_CELL_PART_SIZE_Y = 1

local DIR_X = {-1, 1, 0, 0, -1, 1, -1, 1}
local DIR_Y = {0, 0, -1, 1, -1, 1, 1, -1}
local OPP = {2, 1, 4, 3, 6, 5, 8, 7}

--[[
(-1, 0) = (1, 0)
(1, 0) = (-1, 0)

(0, -1) = (0, 1)
(0, 1) = (0, -1)
--]]

local DIR_COST = {10, 10, 10, 10}

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

    local folder = base:FindFirstChild("GridParts") :: Folder?

    if folder == nil then
        folder = Instance.new("Folder")
        folder.Name = "GridParts"
        folder.Parent = base
    end
    
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

@native
function FieldSolver.stepWeight(grid: GridBase, x: number, y: number, d: number): (number?, number?)
    local nx, ny = x + DIR_X[d], y + DIR_Y[d]
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

function FieldSolver.initObjects(grid: GridBase)
    grid:initializeBuffers()

    for index, objectData in grid.objects do
        if objectData.Weight ~= nil then
            grid:setWeight(index, objectData.Weight)
        end

        if objectData.Cost ~= nil then
            grid:setCost(index, objectData.Cost)
        end
    end
end

-- Assumes objects have already been initialized
@native
function FieldSolver.computeCosts(grid: GridBase, stepWeight: StepWeight?)
    local defStepWeight: StepWeight = stepWeight or FieldSolver.stepWeight

    local changed = true
    local passes = 0

    while changed do
        changed = false
        passes += 1

        for y = 1, grid.height do
            for x = 1, grid.width do
                local index = grid:index(x, y)

                if grid:getWeight(index) == math.huge then continue end

                local cost = grid:getCost(index)
                local best = cost

                for d = 1, #DIR_COST do
                    local ni, weight = defStepWeight(grid, x, y, d)
                    if ni == nil then continue end

                    best = math.min(best, grid:getCost(ni) + weight)
                end

                if best < cost then
                    grid:setCost(index, best)
                    changed = true
                end
            end
        end
    end

    print(`passes: {passes}`)
end

@native
function FieldSolver.computeCostsQueue(grid: GridBase, stepWeight: StepWeight?)
    local defStepWeight: StepWeight = stepWeight or FieldSolver.stepWeight
    
    local n = grid.width * grid.height
    local walkable = table.create(n, false)
    local costs = table.create(n, 0)
    local improved = table.create(n, false)

    local gridHeap = GridHeap.new()

    local p = 0
    for y = 1, grid.height do
        for x = 1, grid.width do
            p += 1

            local weight = grid:getWeight(p - 1)
            if weight < 0 then return end 
            if weight == math.huge then continue end 

            walkable[p] = true 
            
            local cost = grid:getCost(p - 1)
            costs[p] = cost
            if cost == math.huge then continue end 

            gridHeap:push(p, cost)
        end
    end

    while gridHeap.size > 0 do
        local cell, curr = gridHeap:pop()

        if curr ~= costs[cell] then continue end 

        local y = (cell - 1) // grid.width + 1
        local x = cell - (y - 1) * grid.width

        for d = 1, #DIR_COST do
            local ix, iy = x + DIR_X[d], y + DIR_Y[d]
            if not grid:isValid(ix, iy) then continue end

            local ipos = (iy - 1) * grid.width + ix
            if not walkable[ipos] then continue end

            local ni, weight = defStepWeight(grid, ix, iy, OPP[d])
        
            if ni == nil then continue end 

            local candidate = curr + weight
            if candidate < costs[ipos] then
                costs[ipos] = candidate
                improved[ipos] = true
                gridHeap:push(ipos, candidate)
            end
        end
    end

    for i = 1, n do
        if improved[i] then
            grid:setCost(i - 1, costs[i])
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

function FieldSolver.createGradient(grid: GridBase, maxCost: number, map: Model, c1: Color3, c2: Color3)
    local n = grid.width * grid.height
    local base = map.PrimaryPart

    for i = 0, n - 1 do
        local cost = grid:getCost(i)
        local part = base.GridParts:FindFirstChild(`Cell{i}`) :: BasePart
        
        if part == nil then continue end
        
        local alpha = (cost / maxCost)
        part.Transparency = 0
        part.Color = c1:Lerp(c2, alpha)
    end
end

return FieldSolver