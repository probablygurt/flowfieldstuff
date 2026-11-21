local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local DEF_WEIGHT_INIT = 1
local DEF_COST_INIT = math.huge

type Grid = Types.Grid

local Grid = {}
Grid.__index = Grid

local function initializeBuffers(weight: buffer, cost: buffer, n: number, weight_init: number, cost_init: number)
    for i = 0, n - 1 do
        buffer.writef32(weight, i * 4, weight_init)
        buffer.writef32(cost, i * 4, cost_init)
    end
end

function Grid.new(width: number, height: number,
     weight_init: number?, cost_init: number?): Grid
    
    local wi = weight_init or DEF_WEIGHT_INIT
    local ci = cost_init or DEF_COST_INIT
    local n = width * height
    
    local self = {} :: Grid
    self.width = width
    self.height = height
    self.weight = buffer.create(n * 4)
    self.cost = buffer.create(n * 4)
    self.objects = {}
    self.objectAdded = Signal.new()

    initializeBuffers(self.weight, self.cost, n, wi, ci)

    return setmetatable(self, Grid)
end

@native
function Grid.isValid(self: Grid, x: number, y: number): boolean
	return x > 0 and x <= self.width and y > 0 and y <= self.height
end

-- Returns a 0-based index from 2D coordinates for a 1-based index
-- We'll be using the convention that (1, 1) refers to the first element in the grid
-- Thus, (1, 1) returns 0
@native
function Grid.index(self: Grid, x: number, y: number): number
	return (y - 1) * self.width + x - 1
end

-- Converts a 0-based index back to 2D coordinates for a 1-based index
-- index 0 points back to (1, 1)
@native
function Grid.coordinates(self: Grid, i: number): Vector2
	return Vector2.new(i % self.width, i // self.width) + Vector2.one
end

@native
function Grid.initializeBuffers(self: Grid, weight_init: number?, cost_init: number?)
    local wi = weight_init or DEF_WEIGHT_INIT
    local ci = cost_init or DEF_COST_INIT

    local n = self.width * self.height
    initializeBuffers(self.weight, self.cost, n, wi, ci)
end 

@native
function Grid.getWeight(self: Grid, i: number): number
    return buffer.readf32(self.weight, i * 4)
end

@native
function Grid.setWeight(self: Grid, i: number, w: number)
    buffer.writef32(self.weight, i * 4, w)
end

@native
function Grid.getCost(self: Grid, i: number): number
    return buffer.readf32(self.cost, i * 4)
end

@native
function Grid.setCost(self: Grid, i: number, c: number)
    buffer.writef32(self.cost, i * 4, c)
end

@native
function Grid.addObject(self: Grid, i: number, name: string, override: boolean): boolean?
    local overridden = self.objects[i + 1]
    if overridden ~= nil and not override then return false end 

    self.objects[i + 1] = name
    self.objectAdded:Fire(i, name)

    return true
end 

@native
function Grid.removeObject(self: Grid, i: number): string?
    if self.objects[i + 1] == nil then return end 

    local removed = self.objects[i + 1]
    self.objects[i + 1] = nil
    
    return removed
end

@native
function Grid.getObject(self: Grid, i: number): string?
    return self.objects[i + 1]
end

function Grid.forEachCell(self: Grid, cells: {number}?, callback: (i: number) -> ())
    if cells then 
        for _, i in cells do
            task.spawn(callback, i)
        end
    else
        for i = 0, self.width * self.height - 1 do
            task.spawn(callback, i)
        end
    end
end

return Grid