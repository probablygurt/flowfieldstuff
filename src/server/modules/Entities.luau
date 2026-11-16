local Entities = {}

export type Profile = {
    Name: string,
    WeightMultiplier: {
        Category: {[string]: number},
        Targets: {[string]: number} -- Overrides category weight multis
    },
    Interest: { 
        Category: {[string]: number},
        Targets: {[string]: number} -- Overrides category interest multis
    }
}

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
}

return Entities