local ServerScriptService = game:GetService("ServerScriptService")

local UnitProfiles = require(script.Parent.UnitProfiles)
local GridBuilder = require(ServerScriptService.Server.fixedmodules.Grid.GridBuilder)
local GridManager = require(ServerScriptService.Server.fixedmodules.Grid.GridManager)
local DijkstraSolver = require(ServerScriptService.Server.fixedmodules.Pathfinding.DijkstraSolver)
local Pathfinder = require(ServerScriptService.Server.fixedmodules.Pathfinding.Pathfinder)
local Types = require(ServerScriptService.Server.fixedmodules.Types)

type UnitManager = {
    Pathfinders: {}
}
type UnitProfile = Types.UnitProfile
type Pathfinder = Types.Pathfinder

local UnitManager = {} :: UnitManager
local madeGridParts = false

local function getMapCellAttributes(map: Model): (Vector2?, CFrame?)
    local cellSize = map:GetAttribute("CellSize") :: Vector2?
    local anchor = map:GetAttribute("CellPartAnchor") :: CFrame?
    return cellSize, anchor
end

local function setMapCellAttributes(map: Model, cellSize: Vector2, anchor: CFrame)
    map:SetAttribute("CellSize", cellSize)
    map:SetAttribute("CellPartAnchor", anchor)
end

local function initPathfinder(profile: UnitProfile): Pathfinder?
    local map = GridManager.Map
    local mapBase = map.PrimaryPart
    if mapBase == nil then return end 

    local grid = GridBuilder.fromMap(map, GridManager.CellSize)
    local mapCS, mapAnchor = getMapCellAttributes(map)

    if mapCS == nil or mapAnchor == nil then 
        mapCS, mapAnchor = GridManager.CellSize, GridBuilder.getMapCellAnchor(map, GridManager.CellSize)
        setMapCellAttributes(map, mapCS, mapAnchor)
    end

    GridBuilder.initWalls(grid, map, profile.Height)

    if not madeGridParts then
        madeGridParts = true
        GridBuilder.createGridParts(map, grid, GridManager.CellSize)
    end

    local pathfinder = Pathfinder.new(grid, map)
    return pathfinder 
end

local function forEachPathfinder(profiles: {string}?, callback: (name: string, pathfinder: Pathfinder) -> ())
    if profiles then
        for _, name in profiles do
            if UnitManager.Pathfinders[name] == nil then continue end
            task.spawn(callback, name, UnitManager.Pathfinders[name])
        end
    else
        for name, pathfinder in UnitManager.Pathfinders do
            task.spawn(callback, name, pathfinder)
        end
    end
end

function UnitManager.init()
    UnitManager.Pathfinders = {}
end

function UnitManager.start()
    -- make a pathfinder for every profile
    if UnitManager.Pathfinders == nil then return end 
    if GridManager.Map == nil then return end

    for name, profile in UnitProfiles do
        if typeof(profile) ~= "table" then continue end 
        if UnitManager.Pathfinders[name] ~= nil then continue end

        local pathfinder = initPathfinder(profile)
        if pathfinder == nil then continue end 
    
        UnitManager.Pathfinders[name] = pathfinder
    end
end

function UnitManager.addObject(profiles: {string}?, i: number, name: string)
    forEachPathfinder(profiles, function(profileName: string, pathfinder: Pathfinder)
        local grid = pathfinder.grid
        grid:addObject(i, name)
    end)
end

function UnitManager.removeObject(profiles: {string}?, i: number)
    forEachPathfinder(profiles, function(profileName: string, pathfinder: Pathfinder)
        local grid = pathfinder.grid
        grid:removeObject(i)
    end)
end

function UnitManager.getObject(profiles: {string}?, i: number): {[string]: string}
    local objects = {}

    forEachPathfinder(profiles, function(name: string, pathfinder: Pathfinder)
        local grid = pathfinder.grid
        objects[name] = grid.objects[i]
    end)

    return objects
end

function UnitManager.solveGrids(profiles: {string}?)
    forEachPathfinder(profiles, function(name: string, pathfinder)
        local grid = pathfinder.grid

        DijkstraSolver.initObjects(grid)
        DijkstraSolver.computeCostsQueue(grid)
    end)
end

return UnitManager