--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

type GridHeap = Types.GridHeap

local GridHeap = {}
GridHeap.__index = GridHeap

function GridHeap.new(): GridHeap
    local self = {}
    self.cells = {}
    self.costs = {}
    self.size = 0

    return setmetatable(self, GridHeap) :: any
end

function GridHeap.push(self: GridHeap, cell: number, cost: number)
    self.size += 1
    local i = self.size 
    
    while i > 1 do
        local parent = i // 2
        local pCost = self.costs[parent]
        if pCost <= cost then break end

        self.cells[i], self.costs[i] = self.cells[parent], pCost
        i = parent
    end

    self.cells[i] = cell
    self.costs[i] = cost
end

function GridHeap.pop(self: GridHeap): (number?, number?)
    if self.size == 0 then return end 

    local minCell, minCost = self.cells[1], self.costs[1]
    local lastCell, lastCost = self.cells[self.size], self.costs[self.size]

    self.size -= 1

    if self.size > 0 then
        local i = 1

        while true do 
            local smallest = i * 2
            if smallest > self.size then break end

            local sCost = self.costs[smallest]
            
            local right = smallest + 1
            if right <= self.size then
                local rCost = self.costs[right]
                
                if rCost < sCost then
                    smallest = right
                    sCost = rCost
                end
            end

            if sCost >= lastCost then break end

            self.cells[i] = self.cells[smallest]
            self.costs[i] = sCost
            i = smallest
        end

        self.cells[i] = lastCell
        self.costs[i] = lastCost
    end

    return minCell, minCost
end

return GridHeap