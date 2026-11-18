local ServerScriptService = game:GetService("ServerScriptService")

local GridHeap = require(ServerScriptService.Server.fixedmodules.Grid.GridHeap)
local ObjectProfiles = require(ServerScriptService.Server.fixedmodules.Objects.ObjectProfiles)
local Types = require(ServerScriptService.Server.fixedmodules.Types)

type Grid = Types.Grid
type UnitProfile = Types.UnitProfile
type ObjectProfile = Types.ObjectProfile
type StepWeight = (grid: Grid, x: number, y: number, d: number) -> (number?, number?)

local DIR_X = {-1, 1, 0, 0, -1, 1, -1, 1}
local DIR_Y = {0, 0, -1, 1, -1, 1, 1, -1}
local OPP = {2, 1, 4, 3, 6, 5, 8, 7} 
local DIR_COST = {10, 10, 10, 10, 14, 14, 14, 14}
local COST_SCALE = 10

local DijkstraSolver = {}

local function scaledWeight(w: number, objectProfile: ObjectProfile, profile: UnitProfile?): number
    if w == math.huge or profile == nil then return w end

    local wm = profile.WeightMultiplier
    local multi = wm.Targets[objectProfile.Name] or wm.Category[objectProfile.Category] or 1

    return w * multi
end

local function seedCost(objectProfile: ObjectProfile, unitProfile: UnitProfile?): number
    local baseCost = objectProfile.Cost
    if unitProfile == nil then return baseCost end

    local s = unitProfile.SeedCost
    return (s.Targets[unitProfile.Name] or s.Category[unitProfile] or baseCost) * COST_SCALE
end

@native
function DijkstraSolver.initObjects(grid: Grid, unitProfile: UnitProfile?)
    grid:initializeBuffers()

    for i, name in grid.objects do
        local objectProfile = ObjectProfiles[name] 
        if objectProfile == nil then continue end 

        if objectProfile.Weight ~= nil then
            local added = scaledWeight(objectProfile.Weight, objectProfile, unitProfile)
            grid:setWeight(i, grid:getWeight(i) + added)
        end

        if objectProfile.Cost ~= nil then
            grid:setCost(i, seedCost(objectProfile, unitProfile))
        end
    end

    for index, name in grid.objects do
        local objectProfile = ObjectProfiles[name]
        if objectProfile == nil then continue end 

        if objectProfile.GetObjectArea ~= nil then
            local objectArea = objectProfile.GetObjectArea(grid, index)

            if objectArea.Weights ~= nil then
                for i, w in objectArea.Weights do
                    local added = scaledWeight(w, objectProfile, unitProfile)
                    grid:setWeight(i, grid:getWeight(i) + added)
                end
            end

            if objectArea.Costs ~= nil then
                -- unimplemented
            end
        end
    end
end

@native
function DijkstraSolver.stepWeight(grid: Grid, x: number, y: number, d: number): (number?, number?)
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

@native
function DijkstraSolver.computeCostsQueue(grid: Grid, stepWeight: StepWeight?)
    local defStepWeight: StepWeight = stepWeight or DijkstraSolver.stepWeight
    
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
        local pos, curr = gridHeap:pop()

        if curr ~= costs[pos] then continue end 

        local y = (pos - 1) // grid.width + 1
        local x = pos - (y - 1) * grid.width

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

@native
function DijkstraSolver.tracePath(grid: Grid, from: Vector2, stepWeight: StepWeight?): {number}
    local defStepWeight = stepWeight or DijkstraSolver.stepWeight

    local path = {grid:index(from.X, from.Y)}

    local n = grid.width * grid.height
    local currX, currY, currIndex = from.X, from.Y, grid:index(from.X, from.Y)
    
    for i = 1, n do
        local cost = grid:getCost(currIndex)
        local bestScore = math.huge
        local bestIndex = -1

        for d = 1, #DIR_COST do
            local ni, weight = defStepWeight(grid, currX, currY, d)
            if ni == nil then continue end 

            local c = grid:getCost(ni)
            if c >= cost then continue end 

            local score = c + weight
            if score < bestScore then
                bestScore = score
                bestIndex = ni
            end
        end

        if bestIndex == -1 then break end

        table.insert(path, bestIndex)
        
        currX = bestIndex % grid.width + 1
        currY = bestIndex // grid.width + 1
        currIndex = bestIndex
    end

    return path
end

return DijkstraSolver