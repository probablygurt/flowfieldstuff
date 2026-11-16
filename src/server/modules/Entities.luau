local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ServerScriptService.Server.modules.Grid.Types)

local Entities = {}

Entities.Profiles = {
    Profile1 = {
        Name = "Untilted1",
        WeightMultiplier = {
            Category = {},
            Targets = {
                
            }
        },
        Interest = {
            Category = {},
            Targets = {
                
            }
        }
    }   
} :: {[string]: Types.EntityProfile}

return Entities