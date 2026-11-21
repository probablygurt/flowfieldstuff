local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local UnitProfiles = {
    Enemy = {
        Health = 0,
        Speed = 5,
        Height = 0,
        WeightMultiplier = {
            Category = {},
            Targets = {}
        },
        SeedCost = {
            Category = {},
            Targets = {
                Tower = math.huge,
                Tower2 = math.huge
            }
        }
    } 
} :: {[string]: Types.UnitProfile} 

function UnitProfiles.init()
    for profileName, profile in UnitProfiles do
        if typeof(profile) == "function" then continue end 
        profile.Name = profileName
    end
end

return UnitProfiles