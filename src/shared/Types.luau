export type Connection = {
    Disconnect: (self: Connection) -> ()
}

export type Signal = {
    Connect: (self: Signal, fn: () -> ()) -> (Connection),
    DisconnectAll: (self: Signal) -> (),
    Fire: (self: Signal, ...any) -> (),
    Wait: (self: Signal) -> (...any),
    Once: (self: Signal, fn: () -> ()) -> ()
}

export type TaskLink = {
    task: () -> () | thread,
    args: any,
    previous: TaskLink?,
    next: TaskLink?,
}

export type TaskList = {
    head: TaskLink?,
    add: (self: TaskList, fn: () -> () | thread) -> ()
}

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

export type Grid = GridData & {
    isValid: (self: Grid, x: number, y: number) -> (boolean),
    index: (self: Grid, x: number, y: number) -> (number),
    coordinates: (self: Grid, i: number) -> (Vector2),
    initializeBuffers: (self: Grid, weight_init: number?, cost_init: number?) -> (),
    
    getWeight: (self: Grid, i: number) -> (number),
    setWeight: (self: Grid, i: number, w: number) -> (),
    getCost: (self: Grid, i: number) -> (number),
    setCost: (self: Grid, i: number, c: number) -> (),

    addObject: (self: Grid, i: number, name: string, override: boolean?) -> (string?),
    removeObject: (self: Grid, i: number) -> (string?),

    forEachCell: (self: Grid, cells: {number}?, callback: (i: number) -> ()) -> (),
}

export type ObjectProfile = {
    Name: string,
    Category: string?,
    Weight: number?,
    Cost: number?,
    GetObjectArea: ((grid: Grid, i: number) -> ObjectArea)?
}

export type ObjectArea = {
    Weights: {number}?,
    Costs: {number}?
}

export type UnitProfile = {
    Name: string,
    Health: number,
    Speed: number,
    Height: number,
    WeightMultiplier: {
        Category: {[string]: number},
        Targets: {[string]: number} -- Overrides category weight multis
    },
    SeedCost: { 
        Category: {[string]: number},
        Targets: {[string]: number} -- Overrides category interest multis
    }
}

export type UnitData = {
    name: string,
    
    position: Vector2,
    health: number,
    maxHealth: number,
    speed: number,

    waypoints: {CFrame},
    cframe: CFrame,
    targetIndex: number,
    waypointIndex: number,
    unitIndex: number,

    onTickConnection: Connection
}

export type Unit = UnitData & {
    step: (self: Unit) -> (boolean),
    destroy: (self: Unit) -> ()
}

export type PathfinderData = {
    grid: Grid,
    map: Model,
    raycastParams: RaycastParams,
}

export type Pathfinder = PathfinderData & {
    getWaypoints: (self: Pathfinder, path: {number}) -> ({CFrame}),
}


return {}
