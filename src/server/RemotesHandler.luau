local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage.Remotes :: Folder
local requestPlaceableObjects = remotes.RequestPlaceableObjects :: RemoteFunction

local RemotesHandler = {}

RemotesHandler.PlaceableObjects = {
    "Core",
    "Wall",
    "Tower"
}

function RemotesHandler.onRequestPlaceableObjects(player: Player): {string}
    return RemotesHandler.PlaceableObjects
end

requestPlaceableObjects.OnServerInvoke = RemotesHandler.onRequestPlaceableObjects

return RemotesHandler