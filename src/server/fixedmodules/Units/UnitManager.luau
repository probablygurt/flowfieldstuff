local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ReplicatedStorage.Shared.Signal)
local Types = require(ReplicatedStorage.Shared.Types)
local UnitProfiles = require(script.Parent.UnitProfiles)
local GridBuilder = require(ServerScriptService.Server.fixedmodules.Grid.GridBuilder)
local GridManager = require(ServerScriptService.Server.fixedmodules.Grid.GridManager)
local DijkstraSolver = require(ServerScriptService.Server.fixedmodules.Pathfinding.DijkstraSolver)
local Pathfinder = require(ServerScriptService.Server.fixedmodules.Pathfinding.Pathfinder)

type Signal = Types.Signal
type UnitProfile = Types.UnitProfile
type Pathfinder = Types.Pathfinder
type UnitManager = {
    Pathfinders: {Pathfinder},

    init: () -> (),
    start: () -> (),
    addObject: (profiles: {}?, i: number, name: string) -> (),
    removeObject: (profiles: {}?, i: number) -> (),
    getObject: (profiles: {}?, i: number) -> ({[string]: string}),
    solveGrids: (profiles: {string}?) -> (),

    gridSolved: Signal,
}

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

    local unitsFolder = workspace:FindFirstChild("Units")
    if unitsFolder == nil then
        unitsFolder = Instance.new("Folder")
        unitsFolder.Name = "Units"
        unitsFolder.Parent = workspace
    end

    UnitManager.UnitsFolder = unitsFolder
    UnitManager.gridSolved = Signal.new()
end

function UnitManager.start()
    if UnitManager.Pathfinders == nil then return end 
    if GridManager.Map == nil then return end

    for name, profile in UnitProfiles do
        if typeof(profile) ~= "table" then continue end 
        if UnitManager.Pathfinders[name] ~= nil then continue end

        local pathfinder = initPathfinder(profile)
        if pathfinder == nil then continue end 
    
        UnitManager.Pathfinders[name] = pathfinder
    end

    forEachPathfinder(nil, function(name: string, pathfinder: Pathfinder)
        local grid = pathfinder.grid

        grid.objectAdded:Connect(function()
            UnitManager.solveGrids({name})
            
            --GridManager.displayGradient(grid, Color3.fromRGB(255, 255, 255), Color3.fromRGB())
        end)
    end)
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

        DijkstraSolver.initObjects(grid, UnitProfiles[name])
        DijkstraSolver.computeCostsQueue(grid)

        UnitManager.gridSolved:Fire(name)
    end)
end

return UnitManager