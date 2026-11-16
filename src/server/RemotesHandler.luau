local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Entities = require(ServerScriptService.Server.modules.Entities)
local FieldSolver = require(ServerScriptService.Server.modules.FieldSolver)
local GridBase = require(ServerScriptService.Server.modules.Grid.GridBase)
local ObjectData = require(ServerScriptService.Server.modules.ObjectData)

local remotes = ReplicatedStorage.Remotes :: Folder
local requestPlaceableObjects = remotes.RequestPlaceableObjects :: RemoteFunction
local requestGridSize = remotes.RequestGridSize :: RemoteFunction
local placeObject = remotes.PlaceObject :: RemoteEvent
local tracePath = remotes.TracePath :: RemoteEvent

local RemotesHandler = {
    Grid = nil,
    PlaceableObjects = {}
}

local function initPlaceableObjects()
    for name, _ in ObjectData do
        table.insert(RemotesHandler.PlaceableObjects, name)
    end
end

function RemotesHandler.onRequestPlaceableObjects(player: Player): {string}
    return RemotesHandler.PlaceableObjects
end

function RemotesHandler.onRequestGridSize(player: Player): Vector2?
    if RemotesHandler.Grid == nil then return end

    return Vector2.new(RemotesHandler.Grid.width, RemotesHandler.Grid.height)
end

function RemotesHandler.onPlaceObject(player: Player, gridCoords: Vector2, toPlace: string)
    local grid = RemotesHandler.Grid :: GridBase.GridBase

    if not grid:isValid(gridCoords.X, gridCoords.Y) then return end 
    if table.find(RemotesHandler.PlaceableObjects, toPlace) == nil then return end

    local index = grid:index(gridCoords.X, gridCoords.Y)

    grid:addObject(index, toPlace)
    print(`Added {toPlace} at {gridCoords} | Index {index}`)

    FieldSolver.initObjects(grid, Entities.Profiles.Profile1)

    local t = os.clock()
    FieldSolver.computeCostsQueue(grid)
    warn(`computeCosts: {string.format("%.2f", (os.clock() - t) * 1000)}ms`)

    local maxWeight = FieldSolver.getMaxWeight(grid)
    local maxCost = FieldSolver.getMaxCost(grid)
    local fromW, toW = Color3.fromRGB(155, 155, 155), Color3.fromRGB(255, 0, 0)
    local fromC, toC = Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 255)

    FieldSolver.createGradient(grid, maxCost, workspace.Map, fromC, toC, FieldSolver.GradientType.Cost)
end

function RemotesHandler.onTracePath(player: Player, gridCoords: Vector2)
    local grid = RemotesHandler.Grid :: GridBase.GridBase

    local path = FieldSolver.tracePath(grid, gridCoords)

    if not grid:isValid(gridCoords.X, gridCoords.Y) then return end 
end

initPlaceableObjects()
requestPlaceableObjects.OnServerInvoke = RemotesHandler.onRequestPlaceableObjects
requestGridSize.OnServerInvoke = RemotesHandler.onRequestGridSize
placeObject.OnServerEvent:Connect(RemotesHandler.onPlaceObject)
tracePath.OnServerEvent:Connect(RemotesHandler.onTracePath)

return RemotesHandler