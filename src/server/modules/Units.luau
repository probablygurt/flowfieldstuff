local ServerScriptService = game:GetService("ServerScriptService")

local FieldSolver = require(script.Parent.FieldSolver)
local Types = require(ServerScriptService.Server.modules.Grid.Types)
local Pathfinder = require(ServerScriptService.Server.modules.Pathfinding.Pathfinder)

local Units = {
    Units = {},
    Pathfinders = {} :: {[string]: Pathfinder},
}

type Pathfinder = Types.Pathfinder
type UnitData = Types.UnitData

Units.Profiles = {
    Enemy = {
        Name = "Enemy",
        Health = "",

        Height = 0,
        WeightMultiplier = {
            Category = {},
            Targets = {
                
            }
        },
        Interest = {
            Category = {},
            Targets = {
                Tower = 0,
                Tower2 = 0
            }
        }
    }   
} :: {[string]: Types.UnitProfile}

local function getMapCellAttributes(map: Model): (Vector2?, CFrame?)
    local cellSize = map:GetAttribute("CellSize") :: Vector2?
    local anchor = map:GetAttribute("CellPartAnchor") :: CFrame?
    return cellSize, anchor
end

local function setMapCellAttributes(map: Model, cellSize: Vector2, anchor: CFrame)
    map:SetAttribute("CellSize", cellSize)
    map:SetAttribute("CellPartAnchor", anchor)
end

function Units.newUnit(profileName: string, position: Vector2): UnitData?
    if Units.Pathfinders[profileName] == nil then
        warn(`Can't make unit for profile "{profileName}" without its assigned pathfinder`)
        return
    end

    local pathfinder = Units.Pathfinders[profileName]
    local grid = pathfinder.grid

    if not grid:isValid(position.X, position.Y) then
        warn(`Can't make unit with invalid position {position}`)
        return
    end

    local profile = Units.Profiles[profileName]

    local unitData: UnitData = {
        name = profileName,
        position = position,
        health = profile.Health,
        maxHealth = profile.Health,
        targetIndex = -1
    }

    return unitData
end

function Units.newPathfinder(profileName: string, map: Model, cellSize: Vector2): Pathfinder?
    if Units.Pathfinders[profileName] ~= nil then
        warn(`Pathfinder for profile "{profileName}" already exists`)
        return
    end
    
    local profile = Units.Profiles[profileName]
    
    local mapBase = map.PrimaryPart :: BasePart
    
    local grid = FieldSolver.newGridFromPart(mapBase, cellSize)
    local mapCS, mapAnchor = getMapCellAttributes(map)

    if mapCS == nil or mapAnchor == nil then
        mapCS, mapAnchor = cellSize, FieldSolver.getMapCellAnchor(map, cellSize)
        setMapCellAttributes(map, mapCS, mapAnchor)
    end
    
    FieldSolver.initWalls(grid, map, profile.Height)

    local pathfinder = Pathfinder.new(grid, map)
    Units.Pathfinders[profileName] = pathfinder

    return pathfinder
end

return Units