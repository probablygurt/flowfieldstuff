local GridBase = require(script.Parent.GridBase)
local GridHeap = require(script.Parent.GridHeap)

local DEFAULT_CELL_PART_SIZE_Y = 1

local DIR_X = {-1, 1, 0, 0, -1, 1, -1, 1}
local DIR_Y = {0, 0, -1, 1, -1, 1, 1, -1}
local OPP = {2, 1, 4, 3, 6, 5, 8, 7} 
local DIR_COST = {10, 10, 10, 10, 14, 14, 14, 14}

local FieldSolver = {}

type StepWeight = (grid: GridBase, x: number, y: number, d: number) -> (number?, number?)
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
            cell.Transparency = 0.25
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

function FieldSolver.getMaxCost(grid: GridBase): number
    local max = -math.huge
	
    for i = 0, grid.width * grid.height - 1 do
		local c = grid:getCost(i)
		if c ~= math.huge and c > max then max = c end
	end

	return max
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

function FieldSolver.createGradient(grid: GridBase, maxCost: number, map: Model, c1: Color3, c2: Color3)
    local n = grid.width * grid.height
    local base = map.PrimaryPart
    local gridParts = base:FindFirstChild("GridParts") :: Folder?

    if gridParts == nil then return end 

    for i = 0, n - 1 do
        local cost = grid:getCost(i)
        local part = gridParts:FindFirstChild(`Cell{i}`) :: BasePart
        if part == nil then continue end
        
        local alpha = (cost / maxCost)
        part.Color = c1:Lerp(c2, alpha)
    end
end

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
        local weight = grid:getWeight(index)
        
        if objectData.Weight ~= nil then
            grid:setWeight(index, weight + objectData.Weight)
        end

        if objectData.Cost ~= nil then
            grid:setCost(index, objectData.Cost)
        end
    end

    for index, objectData in grid.objects do
        if objectData.Init ~= nil then
            objectData.Init(grid, index)
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

    local solidSources = {}
    local gridHeap = GridHeap.new()

    local p = 0
    for y = 1, grid.height do
        for x = 1, grid.width do
            p += 1

            local weight = grid:getWeight(p - 1)
            if weight < 0 then return end 

            local cost = grid:getCost(p - 1)
            if weight == math.huge then
                if cost ~= math.huge then
                    table.insert(solidSources, p)
                end

                continue
             end 

            walkable[p] = true 
            costs[p] = cost
            if cost == math.huge then continue end 

            gridHeap:push(p, cost)
        end
    end

    for _, sourcePos in solidSources do
        local sourceIndex = sourcePos - 1
        local cy = sourceIndex // grid.width + 1
        local cx = sourceIndex % grid.width + 1
        local cost = grid:getCost(sourceIndex)

        for d = 1, #DIR_COST do
            local nx, ny = cx + DIR_X[d], cy + DIR_Y[d]
            if not grid:isValid(nx, ny) then continue end 

            local np = (ny - 1) * grid.width + nx
            if not walkable[np] then continue end 

            if d > 4 then
                if not walkable[(cy - 1) * grid.width + nx] then continue end
                if not walkable[(ny - 1) * grid.width + cx] then continue end  
            end

            local candidate = cost + DIR_COST[d]
            if candidate < costs[np] then
                costs[np] = candidate
                improved[np] = true
                gridHeap:push(np, candidate)
            end
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

function FieldSolver.tracePath(grid: GridBase, origin: Vector2, stepWeight: StepWeight?): {number}
    local defStepWeight = stepWeight or FieldSolver.stepWeight

    local path = {grid:index(origin.X, origin.Y)}

    local n = grid.width * grid.height
    local currX, currY, currIndex = origin.X, origin.Y, grid:index(origin.X, origin.Y)
    
    for i = 1, n do
        local cost = grid:getCost(currIndex)
        local lowest = cost
        local lowestI = -1

        for d = 1, #DIR_COST do
            local ni, _ = defStepWeight(grid, currX, currY, d)
            if ni == nil then continue end 

            local c = grid:getCost(ni)
            if c < lowest then
                lowest = c
                lowestI = ni
            end
        end

        if lowest >= cost then break end

        table.insert(path, lowestI)
        
        currX = lowestI % grid.width + 1
        currY = lowestI // grid.width + 1
        currIndex = lowestI
    end

    local base = workspace.Map.PrimaryPart
    local gridParts = base:FindFirstChild("GridParts") :: Folder?

    if gridParts ~= nil then
        for _, i in path do
            local part = gridParts:FindFirstChild(`Cell{i}`) :: BasePart
            if part == nil then continue end 

            local prevColor = part.Color
            part.Color = Color3.fromRGB(255, 255, 0)
            task.delay(5, function()
                part.Color = prevColor
            end)

            task.wait()
        end
    end

    return path
end

return FieldSolver