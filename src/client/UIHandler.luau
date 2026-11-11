local Players = game:GetService("Players")

local player: Player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local coreGui = playerGui:WaitForChild("Core") :: ScreenGui

local placementDataFrame = coreGui.PlacementData :: Frame
local selectedToPlaceLabel = placementDataFrame.SelectedToPlace :: TextLabel
local selectedIndexLabel = placementDataFrame.SelectedToPlaceIndex :: TextLabel

local UIHandler = {}

function UIHandler.updateSelectedToPlace(v: string, i: string?)
    selectedToPlaceLabel.Text = v
    selectedIndexLabel.Text = i or ""
end

return UIHandler