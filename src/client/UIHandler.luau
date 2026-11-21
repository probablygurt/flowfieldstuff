local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TaskManager = require(ReplicatedStorage.Shared.TaskManager)

local player: Player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local coreGui = playerGui:WaitForChild("Core") :: ScreenGui

local placementDataFrame = coreGui.PlacementData :: Frame
local selectedToPlaceLabel = placementDataFrame.SelectedToPlace :: TextLabel
local selectedIndexLabel = placementDataFrame.SelectedToPlaceIndex :: TextLabel

local serverDataFrame = coreGui.ServerData :: Frame
local serverTickLabel = serverDataFrame.ServerTick :: TextLabel
local TPSLabel = serverDataFrame.TPS :: TextLabel

local UIHandler = {}

function UIHandler.updateSelectedToPlace(v: string, i: string?)
    selectedToPlaceLabel.Text = v
    selectedIndexLabel.Text = i or ""
end

function UIHandler.start()
    TaskManager.OnTick:Connect(function(currTick)
        serverTickLabel.Text = `Server Tick: {currTick}`
    end)

    local lastTick = TaskManager.Tick

    task.defer(function()
        while task.wait(1) do
            TPSLabel.Text = `TPS: {TaskManager.Tick - lastTick}`
            lastTick = TaskManager.Tick
        end
    end)
end

return UIHandler