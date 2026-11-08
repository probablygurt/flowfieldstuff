local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Grid = require(ReplicatedStorage.Shared.Grid)

local g = Grid.new(50, 50)
g:createParts()

local function randomGoal(): (Vector2, number, BasePart)
    local randCoords = Vector2.new(math.random(1, g.width), math.random(1, g.height))
    local index = g:index(randCoords.X, randCoords.Y)
    local part = g:getPart(index)

    return randCoords, index, part
end

local goalCoords, goalIndex, goalPart = randomGoal()
goalPart.BrickColor = BrickColor.Red()

local function getNeighbours(nodeCoords: Vector2, neighbours: {Vector2}, visited: buffer)
    table.clear(neighbours)

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx == 0 and dy == 0 then continue end
            if not g:isValid(nodeCoords.X + dx, nodeCoords.Y + dy) then continue end

            local index = g:index(nodeCoords.X + dx, nodeCoords.Y + dy)
            
            if buffer.readbits(visited, index, 1) == 1 then continue end
            
            neighbours[index] = nodeCoords + Vector2.new(dx, dy)
        end
    end

    return neighbours
end

local function computeCosts(goalCoords: Vector2, goalIndex: number)
    local queue = {goalCoords}
    local neighbours = {}
    local visited = buffer.create(math.ceil((g.width * g.height) / 8))
    buffer.writebits(visited, goalIndex, 1, 1)

    while #queue > 0 do
        local curr = table.remove(queue, 1)
        local currIndex = g:index(curr.X, curr.Y)
        
        getNeighbours(curr, neighbours, visited)

        for index, neighbour in neighbours do
            table.insert(queue, neighbour)
            buffer.writebits(visited, index, 1, 1)
            
            g:setCost(index, g:getCost(currIndex) + g:getWeight(currIndex))
            local part = g:getPart(index)

            if part.BrickColor == BrickColor.Gray() then
                part.BrickColor = BrickColor.Yellow()
            end
        end
    end
end

task.wait(3)

for i = 1, 100 do
    local part
    local index
    repeat
        _, index, part = randomGoal()
    until index ~= goalIndex
    
    if math.random() > 0.5 then
        g:setWeight(index, 20)
        part.BrickColor = BrickColor.Black()
    else
        g:setWeight(index, 5)
        part.BrickColor = BrickColor.DarkGray()
    end
end

local function tracePath(startCoords: Vector2, startIndex: number)
    local curr = startCoords
    local currIndex = startIndex
    local path = {startCoords}

    for _ = 1, g.width * g.height do
        if currIndex == goalIndex then break end

        local bestCoords, bestIndex
        local bestTotal = math.huge

        for dx = -1, 1 do
			for dy = -1, 1 do
				if dx == 0 and dy == 0 then continue end
				if not g:isValid(curr.X + dx, curr.Y + dy) then continue end

				local index = g:index(curr.X + dx, curr.Y + dy)
				local stepLen = (dx ~= 0 and dy ~= 0) and math.sqrt2 or 1
				local total = g:getCost(index) + g:getWeight(index) * stepLen

				if total < bestTotal then
					bestTotal = total
					bestCoords = Vector2.new(curr.X + dx, curr.Y + dy)
					bestIndex = index
				end
			end
		end

        if not bestCoords then
			warn("No path from start to goal")
			break
		end

		curr, currIndex = bestCoords, bestIndex
		table.insert(path, currIndex)

		if currIndex ~= goalIndex then
			g:getPart(currIndex).BrickColor = BrickColor.Green()
			task.wait(0.05)
		end
    end
end

computeCosts(goalCoords, goalIndex)

local startCoords, startIndex, startPart = randomGoal()
startPart.BrickColor = BrickColor.Green()

tracePath(startCoords, startIndex)

