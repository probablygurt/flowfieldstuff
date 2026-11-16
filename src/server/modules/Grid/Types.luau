export type GridHeapData = {
    cells: {number},
    costs: {number},
    size: number,
}

export type GridHeap = GridHeapData & {
    push: (self: GridHeap, cell: number, cost: number) -> (),
    pop: (self: GridHeap) -> (number?, number?)
}

export type GridData = {
    width: number,
    height: number,
    weight: buffer,
    cost: buffer,
    objects: {[number]: string},
}

export type GridBase = GridData & {
    isValid: (self: GridBase, x: number, y: number) -> (boolean),
    index: (self: GridBase, x: number, y: number) -> (number),
    coordinates: (self: GridBase, i: number) -> (Vector2),
    initializeBuffers: (self: GridBase, weight_init: number?, cost_init: number?) -> (),
    
    getWeight: (self: GridBase, i: number) -> (number),
    setWeight: (self: GridBase, i: number, w: number) -> (),
    getCost: (self: GridBase, i: number) -> (number),
    setCost: (self: GridBase, i: number, c: number) -> (),

    addObject: (self: GridBase, i: number, name: string, override: boolean?) -> (string?),
    removeObject: (self: GridBase, i: number) -> (string?)
}

export type ObjectData = {
    Name: string,
    Category: string?,
    Weight: number?,
    Cost: number?,
    GetObjectArea: ((grid: GridBase, i: number) -> ObjectArea)?
}

export type ObjectArea = {
    Weights: {number}?,
    Costs: {number}?
}

export type EntityProfile = {
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


export type PathfinderData = {
    grid: GridBase,
    map: Model,
}

export type Pathfinder = PathfinderData & {

}

return {}