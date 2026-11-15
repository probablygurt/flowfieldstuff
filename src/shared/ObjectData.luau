local GridBase = require(script.Parent.GridBase)

local function isSolid(grid: GridBase.GridBase, x: number, y: number): boolean
    return grid:getWeight(grid:index(x, y)) == math.huge
end

local function isObstructed(grid: GridBase.GridBase, x0: number, y0: number, x1: number, y1: number): boolean
    --Bresenham's walk
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = if x0 < x1 then 1 else -1
    local sy = if y0 < y1 then 1 else -1
    local err = dx - dy
    local x, y = x0, y0

    while x ~= x1 or y ~= y1 do
        local e2 = err * 2
        local movedX, movedY = false, false

        if e2 > -dy then
            err -= dy
            x += sx
            movedX = true
        end

        if e2 < dx then
            err += dx
            y += sy
            movedY = true
        end

        if movedX and movedY and isSolid(grid, x - sx, y) and isSolid(grid, x, y - sy) then
            return true
        end

        if x == x1 and y == y1 then break end 
        if isSolid(grid, x, y) then return true end 
    end

    return false
end

local function drawCircle(grid: GridBase.GridBase, i: number, rad: number, checkObstructed: boolean?): {number}
    local indices = {}

    checkObstructed = checkObstructed or true

    local cy = i // grid.width + 1
    local cx = i % grid.width + 1

    local top = cy - rad
    local bot = cy + rad

    for y = top, bot do
        local dy = y - cy
        local dx = math.sqrt(rad * rad - dy * dy)
        local left = math.ceil(cx - dx)
        local right = math.floor(cx + dx)

        for x = left, right do
            if x == cx and y == cy or not grid:isValid(x, y) then continue end 
            if checkObstructed and isObstructed(grid, cx, cy, x, y) then continue end

            local index = grid:index(x, y)
            table.insert(indices, index)
        end
    end

    return indices
end

local ObjectData: {[string]: GridBase.ObjectArea} = {
    Core = {
        Cost = 0,
    },
    Mud = {
        Weight = 5,
    },
    Wall = {
        Weight = math.huge
    },
    Tower = {
        Weight = math.huge,
        Cost = 20,
        GetObjectArea = function(grid, i)
            local WEIGHT_ADD = 2

            local objectArea: GridBase.ObjectArea = {}
            local weight = {}

            for _, index in drawCircle(grid, i, 10) do 
                weight[index] = WEIGHT_ADD
            end

            objectArea.Weights = weight

            return objectArea
        end
    }
}


return ObjectData