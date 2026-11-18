local ServerScriptService = game:GetService("ServerScriptService")

local UnitProfiles = require(script.Parent.UnitProfiles)
local Types = require(ServerScriptService.Server.fixedmodules.Types)

type Unit = Types.Unit

local Unit = {}
Unit.__index = Unit

function Unit.new(profileName, spawnPos: Vector2): Unit
    local profile = UnitProfiles[profileName]
    
    local self = {} :: Unit
    self.name = profileName
    self.position = spawnPos
    self.health = profile.Health
    self.maxHealth = profile.Health
    self.targetIndex = -1
    
    return setmetatable(self, Unit)
end

return Unit