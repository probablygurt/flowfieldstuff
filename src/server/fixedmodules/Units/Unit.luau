local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TaskManager = require(ReplicatedStorage.Shared.TaskManager)
local Types = require(ReplicatedStorage.Shared.Types)
local UnitManager = require(script.Parent.UnitManager)
local GridBuilder = require(ServerScriptService.Server.fixedmodules.Grid.GridBuilder)
local GridManager = require(ServerScriptService.Server.fixedmodules.Grid.GridManager)
local DijkstraSolver = require(ServerScriptService.Server.fixedmodules.Pathfinding.DijkstraSolver)
local UnitProfiles = require(script.Parent.UnitProfiles)

type Unit = Types.Unit
type Pathfinder = Types.Pathfinder

local UNIT_STEP = 0.1

local Unit = {}
local UnitClass = {}
UnitClass.__index = UnitClass

local unitModelsFolder = ReplicatedStorage.Units :: Folder
local unitModels: {[string]: Model} = {}

local unitsFolder = workspace:FindFirstChild("Units") :: Folder?
local units: {Unit} = {}
local parts = {}
local cframes = {}
local pivotOffsets = {}
local finalCFrames = {}

local function preloadUnitModels()
    for name, profile in UnitProfiles do
        if typeof(profile) ~= "table" then continue end
        
        local unitModel = unitModelsFolder:FindFirstChild(name) :: Model?
        if unitModel == nil then
            warn(`No unit model found for {name}, skipping..`)
            continue
        end

        local hitbox = unitModel:FindFirstChild("Hitbox")
        if hitbox == nil then
            warn(`No hitbox part found for model {name}, skipping..`) 
            continue
        end

        unitModels[name] = unitModel
    end
end

function Unit.new(profileName, spawnPos: Vector2): Unit?
    local profile = UnitProfiles[profileName]
    
    local model = unitModels[profileName]
    assert(model, `Couldn't make unit object for {profileName} without an available unit model`)

    local pathfinder = UnitManager.Pathfinders[profileName]
    assert(pathfinder, `Couldn't make unit object for {profileName} without an initialized pathfinder object`)    
    local grid = pathfinder.grid
    assert(grid:isValid(spawnPos.X, spawnPos.Y), `Couldn't make unit object for {profileName} with an invalid position`)

    local path = DijkstraSolver.tracePath(grid, spawnPos)
    if #path < 2 then
        warn(`Couldn't make unit object for {profileName} with an invalid position`)
        return
    end

    local waypoints = pathfinder:getWaypoints(path)

    local anchor = GridBuilder.getMapCellAnchor(GridManager.Map, GridManager.CellSize)
    local worldCframe = GridBuilder.pointToWorldCf(anchor, GridManager.CellSize, spawnPos)

    model = model:Clone()
    model:PivotTo(waypoints[1])
    model.Parent = unitsFolder
    
    local self = {} :: Unit
    self.name = profileName
    self.position = spawnPos
    self.health = profile.Health
    self.maxHealth = profile.Health
    self.speed = profile.Speed
    self.model = model
    self.waypoints = waypoints
    self.targetIndex = -1
    self.waypointIndex = 1

    local pivotInverse = model.PrimaryPart.PivotOffset:Inverse()
    table.insert(units, self)
    table.insert(parts, model.PrimaryPart)
    table.insert(cframes, waypoints[1])
    table.insert(pivotOffsets, pivotInverse)
    table.insert(finalCFrames, waypoints[1] * pivotInverse)

    self.cframeIndex = #finalCFrames
    self.onTickConnection = TaskManager.OnTick:Connect(function()
        self:step(1)
    end)

    return setmetatable(self, UnitClass)
end

function UnitClass.step(self: Unit, ticks: number)
    local waypoints = self.waypoints 
    local currWaypoint = waypoints[self.waypointIndex]
    local nextWaypoint = waypoints[self.waypointIndex + 1]
    
    if nextWaypoint == nil then
        self:destroy()
        return
    end 

    local currCFrame = cframes[self.cframeIndex] --self.model:GetPivot()
    local dir = nextWaypoint.Position - currWaypoint.Position

    currCFrame = CFrame.lookAlong(currCFrame.Position + dir.Unit * self.speed * UNIT_STEP, dir)

    local passed = (currCFrame.Position - nextWaypoint.Position):Dot(dir) >= 0
    if passed then
        currCFrame = nextWaypoint
        self.waypointIndex += 1
    end

    cframes[self.cframeIndex] = currCFrame
    finalCFrames[self.cframeIndex] = currCFrame * pivotOffsets[self.cframeIndex]
end

function UnitClass.destroy(self: Unit)
    local i = self.cframeIndex
    local last = #finalCFrames

    if i ~= last then
        parts[i], cframes[i] = parts[last], cframes[last]
        pivotOffsets[i], finalCFrames[i] = pivotOffsets[last], finalCFrames[last]
        units[i] = units[last]

        units[i].cframeIndex = i
    end

    self.onTickConnection:Disconnect()
    self.model:Destroy()
    parts[last], cframes[last], pivotOffsets[last], finalCFrames[last], units[last] = nil, nil, nil, nil, nil
    setmetatable(self, nil)
end

function Unit.init()
    preloadUnitModels()

    if unitsFolder == nil then
        unitsFolder = Instance.new("Folder")
        unitsFolder.Name = "Units"
        unitsFolder.Parent = workspace
    end

    --[[TaskManager.OnTick:Connect(function(currTick: number)
        for _, unit in units do
            if unit:step(1) then
                unit:destroy()
            end
        end
    end)--]]

    TaskManager.PostTicks:Connect(function()
        workspace:BulkMoveTo(parts, finalCFrames, Enum.BulkMoveMode.FireCFrameChanged)
    end)
end

return Unit