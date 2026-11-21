local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Grid = require(script.Parent.Grid)

local DEFAULT_CELL_PART_SIZE_Y = 1
local DEFAULT_RAY_LENGTH = 1000

type Grid = Types.Grid

local GridBuilder = {}

local function isDecimal(x: number): boolean
    return x % 1 ~= 0
end

function GridBuilder.fromMap(map: Model, cellSize: Vector2): Grid?
    local base = map.PrimaryPart
    if base == nil then return end 
    
    local partX, partZ = base.Size.X, base.Size.Z
    local gridSize = Vector2.new(partX, partZ) / cellSize

    if isDecimal(gridSize.X) or isDecimal(gridSize.Y) then
        warn(`Ensure that map size is proportional to cell size`)
        return 
    end

    return Grid.new(gridSize.X, gridSize.Y)
end

function GridBuilder.getMapCellAnchor(map: Model, cellSize: Vector2): CFrame
    local base = map.PrimaryPart
    local baseSize = base.Size
    local baseCFrame = base.CFrame
    
    return baseCFrame * CFrame.new(
        -baseSize.X * 0.5 + cellSize.X * 0.5,
        baseSize.Y * 0.5,
        -baseSize.Z * 0.5 + cellSize.Y * 0.5
    )
end

function GridBuilder.pointToWorldCf(anchor: CFrame, cellSize: Vector2, pos: Vector2): CFrame
    return anchor * CFrame.new((pos.X - 1) * cellSize.X, 0, (pos.Y - 1) * cellSize.Y)
end

function GridBuilder.castRayToGround(target: CFrame, raycastParams: RaycastParams, height: number?): RaycastResult?
    local rayLength = height or DEFAULT_RAY_LENGTH
    
    local rayOrigin = (target * CFrame.new(0, rayLength, 0)).Position
    local rayDir = (target.Position - rayOrigin).Unit

    return workspace:Raycast(rayOrigin, rayDir * rayLength * 2, raycastParams)
end

function GridBuilder.createGridParts(map: Model, grid: Grid, cellSize: Vector2)
    local base = map.PrimaryPart
    local anchor = GridBuilder.getMapCellAnchor(map, cellSize)
    
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
			cell.CFrame = GridBuilder.pointToWorldCf(anchor, cellSize, Vector2.new(x, y)) *
             CFrame.new(0, cellPartSize.Y * 0.5, 0)
            cell.Name = `Cell{index}`
            cell.Parent = folder
        end
    end
end

function GridBuilder.initWalls(grid: Grid, map: Model, height: number)
    local anchor = map:GetAttribute("CellPartAnchor") :: CFrame?
    local cellSize = map:GetAttribute("CellSize")

    if anchor == nil or cellSize == nil then
        error("Map is missing attribute 'CellPartAnchor' or 'CellSize'")
    end

    local anchorY = anchor.Y
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams:AddToFilter(map)

    grid:forEachCell(nil, function(i: number)
        local target = GridBuilder.pointToWorldCf(anchor, cellSize, grid:coordinates(i))
        local raycastResult = GridBuilder.castRayToGround(target, raycastParams)

        if raycastResult == nil then return end 

        local raycastY = raycastResult.Position.Y

        if math.abs(raycastY - anchorY) > height then
            grid:addObject(i, "Wall")
        end
    end)
end


return GridBuilder