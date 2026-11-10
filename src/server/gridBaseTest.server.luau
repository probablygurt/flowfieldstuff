local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FieldSolver = require(ReplicatedStorage.Shared.FieldSolver)

local cellSize = Vector2.new(1, 1)
local goalColor = Color3.fromRGB(0, 255, 0)
local farColor = Color3.fromRGB(255, 0, 255)

local map = workspace.Map :: Model
local mapBase = map.PrimaryPart :: BasePart

local mapGrid = FieldSolver.newGridFromPart(mapBase, cellSize)
FieldSolver.createGridParts(mapGrid, mapBase, cellSize)
local baseOrigin = Vector2.new(mapGrid.width, mapGrid.height) // 2
local baseSize = Vector2.one * 3

local goalIndices = FieldSolver.setCostRect(mapGrid, baseOrigin, baseSize, 0)

FieldSolver.forEachCell(mapGrid, goalIndices, function(i: number)
    local part = mapBase.GridParts:FindFirstChild(`Cell{i}`) :: BasePart
    if part == nil then return end

    part.Transparency = 0
    part.Color = goalColor
end)

local raycastParams = RaycastParams.new()
raycastParams:AddToFilter(map)
raycastParams.FilterType = Enum.RaycastFilterType.Include

FieldSolver.forEachCell(mapGrid, nil, function(i: number)
    local part = mapBase.GridParts:FindFirstChild(`Cell{i}`) :: BasePart
    if part == nil then return end
    
    local origin = (part.CFrame * CFrame.new(Vector3.yAxis * 1000)).Position
    local direction = (part.Position - origin).Unit * (1000 + part.Size.Y)

    local raycast = workspace:Raycast(origin, direction, raycastParams)
    if raycast then
        local hitPart = raycast.Instance

        if hitPart.Name == "Mud" then
            part.Color = Color3.fromRGB(255, 115, 0)
            mapGrid:setWeight(i, 5)
        elseif hitPart.Name == "Wall" then
            part.Color = Color3.fromRGB(0, 0, 0)
            mapGrid:setWeight(i, math.huge)
        end
    end
end)

local D = {
    -Vector2.xAxis,
    Vector2.xAxis,
    -Vector2.yAxis,
    Vector2.yAxis,
    -Vector2.one,
    Vector2.one,
    Vector2.new(-1, 1),
    Vector2.new(1, -1)
}

local D_COST = {
    10, 10, 10, 10, 14, 14, 14, 14
}

local function stepWeight(x, y, d): (number?, number?)
    local nx, ny = x + D[d].X, y + D[d].Y
    if not mapGrid:isValid(nx, ny) then return end

    local ni = mapGrid:index(nx, ny)
    local weight = mapGrid:getWeight(ni)
    
    if d > 4 then
        local diag1 = mapGrid:getWeight(mapGrid:index(nx, y))
        local diag2 = mapGrid:getWeight(mapGrid:index(x, ny))

        if diag1 + diag2 == math.huge then return end 
    end

    return ni, weight * D_COST[d]
end

local function computeCosts()
    local t = os.clock()

    local changed = true

    while changed do
        changed = false

        for y = 1, mapGrid.height do
            for x = 1, mapGrid.width do
                local index = mapGrid:index(x, y)
                if mapGrid:getWeight(index) == math.huge then continue end

                local cost = mapGrid:getCost(index)
                local best = cost

                for d = 1, #D do
                    local ni, weight = stepWeight(x, y, d)
                    if not ni then continue end
                    best = math.min(best, mapGrid:getCost(ni) + weight)
                end

                if best < cost then
                    mapGrid:setCost(index, best)
                    changed = true
                end
            end
        end
    end

    print(`finished in {(os.clock() - t) * 1000} ms`)
end

local function getMaxCost(): number
	local m = 0
	for i = 0, mapGrid.width * mapGrid.height - 1 do
		local c = mapGrid:getCost(i)
		if c ~= math.huge and c > m then m = c end
	end
	return m
end

local function createGradient(maxCost: number)
    local n = mapGrid.width * mapGrid.height

    for i = 0, n - 1 do
        local cost = mapGrid:getCost(i)
        local part = mapBase.GridParts:FindFirstChild(`Cell{i}`) :: BasePart
        
        if part == nil then continue end
        
        local alpha = (cost / maxCost)
        part.Transparency = 0
        part.Color = goalColor:Lerp(farColor, alpha)
    end
end

local function tracePath(start: Vector2): { number }
	local path = {}
	local x, y = start.X, start.Y
	local currIndex = mapGrid:index(x, y)

	for _ = 1, mapGrid.width * mapGrid.height do
		table.insert(path, currIndex)

		if table.find(goalIndices, currIndex) then break end

		local bestD, bestIndex, bestScore = nil, nil, math.huge

		for d = 1, #D do
			local ni, weight = stepWeight(x, y, d)
			if not ni then continue end
			local score = mapGrid:getCost(ni) + weight

			if score < bestScore then
				bestD, bestIndex, bestScore = d, ni, score
			end
		end

		if not bestD then
			warn("No path from start to goal")
			break
		end

		x, y = x + D[bestD].X, y + D[bestD].Y
		currIndex = bestIndex
	end

	return path
end

task.wait(2)
computeCosts()
task.wait(1)
createGradient(getMaxCost())

FieldSolver.forEachCell(mapGrid, tracePath(Vector2.new(95, 96)), function(i: number)
    local part = mapBase.GridParts:FindFirstChild(`Cell{i}`) :: BasePart
        
    if part == nil then return end
    part.BrickColor = BrickColor.Yellow()
    part.Transparency = 0

    task.wait()
end)
