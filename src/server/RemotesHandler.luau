local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FieldSolver = require(ReplicatedStorage.Shared.FieldSolver)
local GridBase = require(ReplicatedStorage.Shared.GridBase)
local ObjectData = require(ReplicatedStorage.Shared.ObjectData)

local remotes = ReplicatedStorage.Remotes :: Folder
local requestPlaceableObjects = remotes.RequestPlaceableObjects :: RemoteFunction
local requestGridSize = remotes.RequestGridSize :: RemoteFunction
local placeObject = remotes.PlaceObject :: RemoteEvent

local RemotesHandler = {
    Grid = nil
}

RemotesHandler.PlaceableObjects = {
    "Core",
    "Wall",
    "Mud"
}

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

    grid:addObjectData(index, ObjectData[toPlace])
    print(`Added {toPlace} at {gridCoords} | Index {index}`)
    FieldSolver.initObjects(grid)

    local t = os.clock()
    FieldSolver.computeCostsQueue(grid)
    warn(`computeCosts: {string.format("%.2f", (os.clock() - t) * 1000)}ms`)

    FieldSolver.createGradient(grid, FieldSolver.getMaxCost(grid), workspace.Map, Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 255))
end

requestPlaceableObjects.OnServerInvoke = RemotesHandler.onRequestPlaceableObjects
requestGridSize.OnServerInvoke = RemotesHandler.onRequestGridSize
placeObject.OnServerEvent:Connect(RemotesHandler.onPlaceObject)
return RemotesHandler