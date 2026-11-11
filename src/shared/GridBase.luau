--!strict

local DEF_WEIGHT_INIT = 1
local DEF_COST_INIT = math.huge

local GridBase = {}
GridBase.__index = GridBase

export type GridBase = typeof(setmetatable({} :: {
    width: number,
    height: number,
    weight: buffer,
    cost: buffer
}, GridBase))

local function initializeBuffers(weight: buffer, cost: buffer, n: number, weight_init: number, cost_init: number)
    for i = 0, n - 1 do
        buffer.writef32(weight, i * 4, weight_init)
        buffer.writef32(cost, i * 4, cost_init)
    end
end

function GridBase.new(width: number, height: number,
     weight_init: number?, cost_init: number?): GridBase
    
    local wi = weight_init or DEF_WEIGHT_INIT
    local ci = cost_init or DEF_COST_INIT
    local n = width * height
    
    local self = {}
    self.width = width
    self.height = height
    self.weight = buffer.create(n * 4)
    self.cost = buffer.create(n * 4)

    initializeBuffers(self.weight, self.cost, n, wi, ci)

    return setmetatable(self, GridBase)
end

function GridBase.isValid(self: GridBase, x: number, y: number): boolean
	return x > 0 and x <= self.width and y > 0 and y <= self.height
end

-- Returns a 0-based index from 2D coordinates for a 1-based index
-- We'll be using the convention that (1, 1) refers to the first element in the grid
-- Thus, (1, 1) returns 0
function GridBase.index(self: GridBase, x: number, y: number): number
	return (y - 1) * self.width + x - 1
end

-- Converts a 0-based index back to 2D coordinates for a 1-based index
-- index 0 points back to (1, 1)
function GridBase.coordinates(self: GridBase, i: number): Vector2
	return Vector2.new(i % self.width, i // self.width) + Vector2.one
end

function GridBase.getWeight(self: GridBase, i: number): number
    return buffer.readf32(self.weight, i * 4)
end

function GridBase.setWeight(self: GridBase, i: number, w: number)
    buffer.writef32(self.weight, i * 4, w)
end

function GridBase.getCost(self: GridBase, i: number): number
    return buffer.readf32(self.cost, i * 4)
end

function GridBase.setCost(self: GridBase, i: number, c: number)
    buffer.writef32(self.cost, i * 4, c)
end


return GridBase