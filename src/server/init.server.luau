local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Grid = require(ReplicatedStorage.Shared.Grid)

local g = Grid.new(10, 10)
g:createParts()

local p = g:getPart(1, 1)
p.Color = Color3.fromRGB(255, 0, 0)

