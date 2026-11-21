local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

type GridManager = {
    Map: Model,
    CellSize: Vector2,
    GradientType: {
        Cost: number,
        Weight: number
    },
    
    init: () -> (),
    start: () -> (),
    getMaxCost: (grid: Grid) -> (number),
    getMaxWeight: (grid: Grid) -> (number),
    displayGradient: (grid: Grid, c0: Color3, c1: Color3, gradientType: number?) -> ()
}

type Grid = Types.Grid

local GridManager = {} :: GridManager

function GridManager.init()
    GridManager.Map = workspace.Map
    GridManager.CellSize = Vector2.new(1, 1)
    GridManager.GradientType = {
        Cost = 1,
        Weight = 0
    }
end

function GridManager.getMaxCost(grid: Grid): number
    local max = -math.huge
	
    for i = 0, grid.width * grid.height - 1 do
		local c = grid:getCost(i)
		if c ~= math.huge and c > max then max = c end
	end

	return max
end

function GridManager.getMaxWeight(grid: Grid): number
    local max = -math.huge
	
    for i = 0, grid.width * grid.height - 1 do
		local c = grid:getWeight(i)
		if c ~= math.huge and c > max then max = c end
	end

	return max
end

function GridManager.displayGradient(grid: Grid, c0: Color3, c1: Color3, gradientType: number?)
    gradientType = gradientType or GridManager.GradientType.Cost

    local n = grid.width * grid.height
    local base = GridManager.Map.PrimaryPart
    local gridParts = base:FindFirstChild("GridParts") :: Folder?

    if gridParts == nil then return end 

    for i = 0, n - 1 do
        local part = gridParts:FindFirstChild(`Cell{i}`) :: BasePart
        if part == nil then continue end
        
        local alpha = 0
        
        if gradientType == GridManager.GradientType.Cost then
            local max = GridManager.getMaxCost(grid)
            local cost = grid:getCost(i)
            alpha = (cost / max)
        elseif gradientType == GridManager.GradientType.Weight then
            local max = GridManager.getMaxWeight(grid)
            local weight = grid:getWeight(i)
            alpha = (weight / max)
        end

        part.Color = c0:Lerp(c1, alpha)
    end
end

return GridManager