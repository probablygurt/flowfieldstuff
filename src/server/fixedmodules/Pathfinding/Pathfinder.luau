local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ReplicatedStorage.Shared.Types)
local GridBuilder = require(ServerScriptService.Server.fixedmodules.Grid.GridBuilder)

local INVALID_MAP_MSG = "Unable to make Pathfinder: Map is missing attributes 'CellPartSize' or 'CellPartAnchor'."
local INVALID_PATH_MSG = "Invalid path: Path length must be greater than 0"

type PathfinderData = Types.PathfinderData
type Grid = Types.Grid

local Pathfinder = {}
Pathfinder.__index = Pathfinder

export type Pathfinder = typeof(setmetatable({} :: PathfinderData, Pathfinder))

local function getCellSize(map: Model): Vector2?
    return map:GetAttribute("CellSize") :: Vector2?
end

local function getCellPartAnchor(map: Model): CFrame?
    return map:GetAttribute("CellPartAnchor") :: CFrame?
end

local function getGroundCFrame(target: CFrame, raycastParams: RaycastParams, height: number?): CFrame?
    local raycastResult = GridBuilder.castRayToGround(target, raycastParams, height)

    if raycastResult then
        local normal = raycastResult.Normal
        local right = target.RightVector
        right = (right - normal * right:Dot(normal)).Unit

        return CFrame.fromMatrix(raycastResult.Position, right, normal)
    end

    return
end

local function isCrossDiff(c0: Vector3, c1: Vector3, threshold: number?): boolean
    return (c1 - c0).Magnitude >= (threshold or 1e-2)
end

function Pathfinder.new(grid: Grid, map: Model): Pathfinder
    local self = {}
    self.grid = grid
    self.map = map

    if getCellSize(map) == nil or getCellPartAnchor(map) == nil then
        error(INVALID_MAP_MSG)
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams:AddToFilter(map)

    self.raycastParams = raycastParams

    return setmetatable(self, Pathfinder)
end

function Pathfinder.getWaypoints(self: Pathfinder, path: {number}): {CFrame}
    if #path < 2 then
        error(INVALID_PATH_MSG)
    end

    local anchor = getCellPartAnchor(self.map)
    local cellSize = getCellSize(self.map)
    local grid = self.grid

    local groundCFrames = {} 
    local crossProducts = {}
    local waypoints = {}

    for i = 1, #path - 1 do
        local i0, i1 = path[i], path[i + 1]
        local c0, c1 = grid:coordinates(i0), grid:coordinates(i1)
        local dir = c1 - c0
        
        local centerCf = GridBuilder.pointToWorldCf(anchor, cellSize, c0) 
        local edgeCf = centerCf * CFrame.new(dir.X * cellSize.X * 0.5, 0, dir.Y * cellSize.Y * 0.5)

        centerCf = getGroundCFrame(centerCf, self.raycastParams)
        edgeCf = getGroundCFrame(edgeCf, self.raycastParams)
 
        table.insert(crossProducts, centerCf.Position:Cross(edgeCf.Position))
        table.insert(groundCFrames, centerCf) 
        if i >= #path - 1 then continue end 
        table.insert(groundCFrames, edgeCf)
    end

    waypoints[1] = groundCFrames[1]
    local lastCross = crossProducts[1]

    -- cframe pruning
    for i = 2, #crossProducts do
        local currCross = crossProducts[i]
        local didDirChange = isCrossDiff(lastCross, currCross)

        if didDirChange or (not didDirChange and i == #crossProducts) then
            local currCenterIndex = i * 2 - 1
            --local nextCross = crossProducts[i + 1]

            -- added this due to a minor issue i experienced with slopes (turns out im not using slopes)
            -- dont remove just in case
            --[[if nextCross ~= nil and currCross ~= nextCross then
                table.insert(waypoints, groundCFrames[currCenterIndex - 2])
            end--]]

            table.insert(waypoints, groundCFrames[currCenterIndex])
        end

        lastCross = currCross
    end

    -- just fix orientation
    for i = 1, #waypoints do
        if i < #waypoints then
            if i == 4 then
            end
            waypoints[i] = CFrame.lookAt(waypoints[i].Position, waypoints[i + 1].Position)
        elseif i > 1 then
            waypoints[i] = CFrame.lookAlong(waypoints[i].Position, (waypoints[i].Position - waypoints[i - 1].Position).Unit)
        end
    end

    --[[for _, waypoint in waypoints do
        local marker = workspace.WaypointMarker:Clone() :: BasePart
        marker.CFrame = waypoint
        marker.Anchored = true
        marker.Parent = workspace
        task.delay(2, marker.Destroy, marker)
    end--]]

    return waypoints
end

return Pathfinder