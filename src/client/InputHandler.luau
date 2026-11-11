local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIHandler = require(script.Parent.UIHandler)

local remotes = ReplicatedStorage.Remotes :: Folder
local requestPlaceableObjects = remotes.RequestPlaceableObjects :: RemoteFunction

local InputHandler = {}

local placeableObjects = requestPlaceableObjects:InvokeServer()
local placementToggled = false
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

function InputHandler.togglePlacement(_, state: Enum.UserInputState)
    if state ~= Enum.UserInputState.Begin then return end

    placementToggled = not placementToggled
    
    if placementToggled then
        UIHandler.updateSelectedToPlace(placeableObjects[selectedToPlaceIndex], selectedToPlaceIndex)
    else 
        UIHandler.updateSelectedToPlace("Placement Not Active")
    end
end

function InputHandler.cycleSelectedToPlace(actionName: string, state: Enum.UserInputState)
    if placementToggled == false or state ~= Enum.UserInputState.Begin then return end 

    if actionName == "CycleSelectedToPlaceL" then
        incrementSelected(-1)
    else
        incrementSelected(1)
    end

    UIHandler.updateSelectedToPlace(placeableObjects[selectedToPlaceIndex], selectedToPlaceIndex)
end

CAS:BindAction("TogglePlacement", InputHandler.togglePlacement, false, Enum.KeyCode.F)
CAS:BindAction("CycleSelectedToPlaceL", InputHandler.cycleSelectedToPlace, false, Enum.KeyCode.Q)
CAS:BindAction("CycleSelectedToPlaceR", InputHandler.cycleSelectedToPlace, false, Enum.KeyCode.E)
UIHandler.updateSelectedToPlace("Placement Not Active")

return InputHandler