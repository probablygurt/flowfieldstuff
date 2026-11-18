local FileManagerService = game:GetService("FileManagerService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Units = require(ServerScriptService.Server.modules.Units)
local FieldSolver = require(ServerScriptService.Server.modules.FieldSolver)
local Types = require(ServerScriptService.Server.modules.Grid.Types)
local ObjectData = require(ServerScriptService.Server.modules.ObjectData)

local remotes = ReplicatedStorage.Remotes :: Folder
local requestPlaceableObjects = remotes.RequestPlaceableObjects :: RemoteFunction
local requestGridSize = remotes.RequestGridSize :: RemoteFunction
local placeObject = remotes.PlaceObject :: RemoteEvent
local destroyObject = remotes.DestroyObject :: RemoteEvent
local tracePath = remotes.TracePath :: RemoteEvent
local sendUnitData = remotes.SendUnitData :: RemoteEvent

local RemotesHandler = {
    GridSize = nil,
    PlaceableObjects = {}
}

type GridBase = Types.GridBase
type UnitData = Types.UnitData

local function initPlaceableObjects()
    for name, _ in ObjectData do
        table.insert(RemotesHandler.PlaceableObjects, name)
    end
end

local function solveMap(grid: GridBase)
    FieldSolver.initObjects(grid, Units.Profiles.Enemy)
    FieldSolver.computeCostsQueue(grid)

    --[[local maxWeight = FieldSolver.getMaxWeight(grid)
    local maxCost = FieldSolver.getMaxCost(grid)
    local fromW, toW = Color3.fromRGB(155, 155, 155), Color3.fromRGB(255, 0, 0)
    local fromC, toC = Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 255)

    FieldSolver.createGradient(grid, maxCost, workspace.Map, fromC, toC, FieldSolver.GradientType.Cost)--]]
end

local function forEachPathfinderGrid(callback: (profileName: string, grid: GridBase) -> ())
    print(Units)
    
    for profileName, pathfinder in Units.Pathfinders do
        local grid = pathfinder.grid
        callback(profileName, grid)
    end
end

function RemotesHandler.onRequestPlaceableObjects(player: Player): {string}
    return RemotesHandler.PlaceableObjects
end

function RemotesHandler.onRequestGridSize(player: Player): Vector2?
    return RemotesHandler.GridSize
end

function RemotesHandler.onPlaceObject(player: Player, gridCoords: Vector2, toPlace: string)
    forEachPathfinderGrid(function(profileName, grid)
        if not grid:isValid(gridCoords.X, gridCoords.Y) then return end 
        if table.find(RemotesHandler.PlaceableObjects, toPlace) == nil then return end

        local index = grid:index(gridCoords.X, gridCoords.Y)

        grid:addObject(index, toPlace)
        print(`Added {toPlace} at {gridCoords} | Index {index} at profile {profileName}`)

        solveMap(grid)
    end)    
end

function RemotesHandler.onDestroyObject(player: Player, gridCoords: Vector2)
    forEachPathfinderGrid(function(profileName: string, grid)
        if not grid:isValid(gridCoords.X, gridCoords.Y) then return end

        local index = grid:index(gridCoords.X, gridCoords.Y)
        local removed = grid:removeObject(index)

        if removed ~= nil then
            print(`Removed {removed} at {gridCoords} | Index {index}`)
        end

        solveMap(grid)
    end)
end

function RemotesHandler.onTracePath(player: Player, gridCoords: Vector2)
    forEachPathfinderGrid(function(profileName: string, grid)
        if not grid:isValid(gridCoords.X, gridCoords.Y) then return end 
        FieldSolver.tracePath(grid, gridCoords)
    end)
end

function RemotesHandler.sendUnitData(unitData: UnitData)
    sendUnitData:FireAllClients()
end

initPlaceableObjects()
requestPlaceableObjects.OnServerInvoke = RemotesHandler.onRequestPlaceableObjects
requestGridSize.OnServerInvoke = RemotesHandler.onRequestGridSize
placeObject.OnServerEvent:Connect(RemotesHandler.onPlaceObject)
destroyObject.OnServerEvent:Connect(RemotesHandler.onDestroyObject)
tracePath.OnServerEvent:Connect(RemotesHandler.onTracePath)

return RemotesHandler