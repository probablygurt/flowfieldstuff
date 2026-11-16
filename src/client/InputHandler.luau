local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlacementController = require(script.Parent.PlacementController)
local UIHandler = require(script.Parent.UIHandler)

local remotes = ReplicatedStorage.Remotes :: Folder
local requestPlaceableObjects = remotes.RequestPlaceableObjects :: RemoteFunction
local placeObject = remotes.PlaceObject :: RemoteEvent
local destroyObject = remotes.DestroyObject :: RemoteEvent
local tracePath = remotes.TracePath :: RemoteEvent

local InputHandler = {}

local placeableObjects = requestPlaceableObjects:InvokeServer()
local placementMode = PlacementController.Mode.None
local selectedToPlaceIndex = 1

local function incrementSelected(d: number): number
    local count = #placeableObjects
    if count < 1 then
        selectedToPlaceIndex = 1
        return selectedToPlaceIndex
    end

    selectedToPlaceIndex = ((selectedToPlaceIndex + d - 1) % count) + 1
    return selectedToPlaceIndex
end

function InputHandler.toggleBuild(_, state: Enum.UserInputState)
    if state ~= Enum.UserInputState.Begin then return end

    local isBuildMode = placementMode == PlacementController.Mode.Build
    placementMode = if isBuildMode then PlacementController.Mode.None else PlacementController.Mode.Build
    
    if placementMode == PlacementController.Mode.Build then
        PlacementController.Start()
        UIHandler.updateSelectedToPlace(placeableObjects[selectedToPlaceIndex], selectedToPlaceIndex)
    
        CAS:BindAction("PlaceObject", InputHandler.onMouseClick, false, Enum.UserInputType.MouseButton1)
    elseif placementMode == PlacementController.Mode.None then
        PlacementController.Stop()
        UIHandler.updateSelectedToPlace("Placement Inactive")

        CAS:UnbindAction("PlaceObject")
    end
end

function InputHandler.toggleDestroy(_, state: Enum.UserInputState)
    if state ~= Enum.UserInputState.Begin then return end

    local isDestroyMode = placementMode == PlacementController.Mode.Destroy
    placementMode = if isDestroyMode then PlacementController.Mode.None else PlacementController.Mode.Destroy
    
    if placementMode == PlacementController.Mode.Destroy then
        PlacementController.Start()
        UIHandler.updateSelectedToPlace("Select object to destroy")

        CAS:BindAction("DestroyObject", InputHandler.onMouseClick, false, Enum.UserInputType.MouseButton1)
    elseif placementMode == PlacementController.Mode.None then
        PlacementController.Stop()
        UIHandler.updateSelectedToPlace("Placement Inactive")

        CAS:UnbindAction("DestroyObject")
    end
end

function InputHandler.cycleSelectedToPlace(actionName: string, state: Enum.UserInputState)
    if placementMode ~= PlacementController.Mode.Build then return end
    if state ~= Enum.UserInputState.Begin then return end 

    if actionName == "CycleSelectedToPlaceL" then
        incrementSelected(-1)
    else
        incrementSelected(1)
    end

    UIHandler.updateSelectedToPlace(placeableObjects[selectedToPlaceIndex], selectedToPlaceIndex)
end

function InputHandler.onMouseClick(actionName: string, state: Enum.UserInputState)
    if state ~= Enum.UserInputState.Begin then return end 

    if actionName == "PlaceObject" and placementMode == PlacementController.Mode.Build then
        placeObject:FireServer(PlacementController.GridCoords, placeableObjects[selectedToPlaceIndex])
    elseif actionName == "DestroyObject" and placementMode == PlacementController.Mode.Destroy then
        destroyObject:FireServer(PlacementController.GridCoords)
    end
end

function InputHandler.tracePath(_, state: Enum.UserInputState)
    if state ~= Enum.UserInputState.Begin then return end 

    tracePath:FireServer(PlacementController.GridCoords)
end

CAS:BindAction("ToggleBuild", InputHandler.toggleBuild, false, Enum.KeyCode.F)
CAS:BindAction("ToggleDestroy", InputHandler.toggleDestroy, false, Enum.KeyCode.R)
CAS:BindAction("CycleSelectedToPlaceL", InputHandler.cycleSelectedToPlace, false, Enum.KeyCode.Q)
CAS:BindAction("CycleSelectedToPlaceR", InputHandler.cycleSelectedToPlace, false, Enum.KeyCode.E)
CAS:BindAction("TracePath", InputHandler.tracePath, false, Enum.KeyCode.T)
UIHandler.updateSelectedToPlace("Placement Inactive")

return InputHandler