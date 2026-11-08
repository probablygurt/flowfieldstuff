local Node = {}
Node.__index = Node

type NodeData = {
    weight: number,
    cost: number
}

export type Node = typeof(setmetatable({} :: NodeData, Node))

function Node.new(weight: number, cost: number): Node
    local self = {}
    self.weight = weight or 0
    self.cost = cost or 0 
    
    return setmetatable(self, Node)
end

return Node